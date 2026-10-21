import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/http.dart';
import '../domain/guide.dart';
import '../domain/guide_feed_query.dart';
import '../domain/guide_repository.dart';
import '../domain/report_reason.dart';
import 'guide_feed_request.dart';
import 'guide_json.dart';

/// Storage bucket of guide covers and step images (0001_init.sql).
const guideImagesBucket = 'guide-images';

/// Postgres `unique_violation`: the `guide_stars` and `guide_reports`
/// primary keys.
const _uniqueViolation = '23505';

/// [GuideRepository] over the `guide_feed` view and `guide_stars`.
class SupabaseGuideRepository implements GuideRepository {
  /// [currentUserId] defaults to the signed-in Supabase user.
  SupabaseGuideRepository(this._client, {String? Function()? currentUserId})
    : _currentUserId = currentUserId ?? (() => _client.auth.currentUser?.id);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  @override
  Future<List<Guide>> fetchFeed(GuideFeedQuery query, {int offset = 0}) async {
    final rows = await _send(
      buildGuideFeedRequest(_client, query, offset: offset),
    );
    return [for (final row in rows) guideFromJson(row)];
  }

  @override
  Future<Set<String>> starredGuideIds() async {
    final userId = _currentUserId();
    if (userId == null) return const {};
    final rows = await _send(
      _client.from('guide_stars').select('guide_id').eq('user_id', userId),
    );
    return {for (final row in rows) row['guide_id'] as String};
  }

  @override
  Future<Guide> fetchGuide(String id) async {
    final rows = await _send(
      _client.from('guide_feed').select().eq('id', id).limit(1),
    );
    if (rows.isEmpty) throw GuideNotFoundException(id);
    return guideFromJson(rows.first);
  }

  @override
  Future<void> starGuide(String id) async {
    final userId = _requireUserId();
    try {
      await _send(
        _client.from('guide_stars').insert({'user_id': userId, 'guide_id': id}),
      );
    } on PostgrestException catch (e) {
      // The row exists already (a star from another device): the guide is
      // starred, which is what was asked for.
      if (e.code != _uniqueViolation) rethrow;
    }
  }

  @override
  Future<void> unstarGuide(String id) async {
    final userId = _requireUserId();
    await _send(
      _client
          .from('guide_stars')
          .delete()
          .eq('user_id', userId)
          .eq('guide_id', id),
    );
  }

  @override
  Future<void> reportGuide(
    String id, {
    required ReportReason reason,
    String? note,
  }) async {
    final userId = _requireUserId();
    // The trimmed string is what is sent, so it is what the client check
    // has to agree with the column's char_length(note) <= 200 about.
    final trimmed = note?.trim();
    if (!isValidReportNote(trimmed)) {
      throw ArgumentError.value(
        note,
        'note',
        'longer than $maxReportNoteLength characters',
      );
    }
    try {
      await _send(
        _client.from('guide_reports').insert({
          'guide_id': id,
          'reporter_id': userId,
          'reason': reason.wireValue,
          if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
        }),
      );
    } on PostgrestException catch (e) {
      // This user already reported this guide: one report per user per
      // guide, so the report stands and there is nothing more to do.
      if (e.code != _uniqueViolation) rethrow;
    }
  }

  @override
  String coverUrl(String coverPath) =>
      _client.storage.from(guideImagesBucket).getPublicUrl(coverPath);

  String _requireUserId() =>
      _currentUserId() ?? (throw const AuthRequiredException());

  /// Runs [request] once, with the app-wide timeout and without
  /// postgrest's automatic GET retries (plan/09 § Errors). A request that
  /// never got an answer becomes [NetworkException].
  Future<T> _send<T>(PostgrestBuilder<T, T, T> request) async {
    try {
      return await request.retry(
        enabled: false,
        requestTimeout: AppHttpClient.defaultTimeout,
      );
    } on TimeoutException {
      throw const NetworkException('Request timed out');
    } on SocketException catch (e) {
      throw NetworkException('Socket error: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Client error: ${e.message}');
    }
  }
}
