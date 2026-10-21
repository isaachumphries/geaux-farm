import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/http.dart';
import '../domain/guide.dart';
import '../domain/guide_feed_query.dart';
import '../domain/guide_repository.dart';
import 'guide_feed_request.dart';
import 'guide_json.dart';

/// Storage bucket of guide covers and step images (0001_init.sql).
const guideImagesBucket = 'guide-images';

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
