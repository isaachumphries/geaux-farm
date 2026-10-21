import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/http.dart';
import '../domain/guide.dart';
import '../domain/guide_feed_query.dart';
import '../domain/guide_repository.dart';
import '../domain/guide_validation.dart';
import 'guide_feed_request.dart';
import 'guide_json.dart';

/// Storage bucket of guide covers and step images (0001_init.sql).
const guideImagesBucket = 'guide-images';

/// Writes always target the table, never the `guide_feed` view.
const _guidesTable = 'guides';

const _draftStatus = 'draft';
const _publishedStatus = 'published';

/// The write was refused: RLS matched no row, which is what a hidden
/// guide or another author's guide looks like from the client
/// (`guides_update` is `author_id = auth.uid() and status <> 'hidden'`).
class GuideWriteRejectedException implements Exception {
  const GuideWriteRejectedException([
    this.message = 'This guide can no longer be edited',
  ]);

  final String message;

  @override
  String toString() => 'GuideWriteRejectedException: $message';
}

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
  String coverUrl(String coverPath) =>
      _client.storage.from(guideImagesBucket).getPublicUrl(coverPath);

  @override
  Future<String> saveDraft(GuideDraft draft) =>
      _write(draft, status: _draftStatus);

  @override
  Future<String> publishGuide(GuideDraft draft) =>
      _write(draft, status: _publishedStatus);

  @override
  Future<void> deleteGuide(String guideId) async {
    final userId = _requireUserId();
    // The author_id filter keeps a mistyped id from even reaching RLS.
    await _send(
      _client
          .from(_guidesTable)
          .delete()
          .eq('id', guideId)
          .eq('author_id', userId)
          .select('id'),
    );
  }

  /// Inserts a new row or updates the existing one, and returns its id.
  /// Writes go to `guides`; `guide_feed` is a read-only view.
  Future<String> _write(GuideDraft draft, {required String status}) async {
    final userId = _requireUserId();
    final id = draft.id;
    if (id == null) {
      // guides.id is server-generated, so the insert reads it back.
      final rows = await _send(
        _client
            .from(_guidesTable)
            .insert(guideDraftPayload(draft, status: status, authorId: userId))
            .select('id'),
      );
      return rows.single['id'] as String;
    }
    final rows = await _send(
      _client
          .from(_guidesTable)
          .update(guideDraftPayload(draft, status: status))
          .eq('id', id)
          .eq('author_id', userId)
          .select('id'),
    );
    if (rows.isEmpty) {
      // RLS matched no row: the guide is hidden, or not this author's.
      throw const GuideWriteRejectedException();
    }
    return rows.single['id'] as String;
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null) throw const AuthRequiredException();
    return userId;
  }

  /// Runs [request] once, with the app-wide timeout and without
  /// postgrest's automatic GET retries (plan/09 § Errors). A request that
  /// never got an answer becomes [NetworkException].
  Future<PostgrestList> _send(
    PostgrestBuilder<PostgrestList, PostgrestList, PostgrestList> request,
  ) async {
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
