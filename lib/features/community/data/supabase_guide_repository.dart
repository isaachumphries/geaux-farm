import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/http.dart';
import '../domain/guide.dart';
import '../domain/guide_feed_query.dart';
import '../domain/guide_repository.dart';
import '../domain/guide_validation.dart';
import '../domain/report_reason.dart';
import 'guide_feed_request.dart';
import 'guide_json.dart';

/// Storage bucket of guide covers and step images (0001_init.sql).
const guideImagesBucket = 'guide-images';

/// Postgres `unique_violation`: the `guide_stars` and `guide_reports`
/// primary keys.
const _uniqueViolation = '23505';

/// Writes always target the table, never the `guide_feed` view.
const _guidesTable = 'guides';

/// The author's `profiles` row embedded in a `guides` read, for the
/// username a card shows (`guide_feed` joins it in the view). Named by its
/// foreign key: guide_stars, guide_grows and guide_reports also link guides
/// to profiles, and PostgREST refuses an ambiguous embed (PGRST201).
const _authorEmbed =
    'author:profiles!guides_author_id_fkey(username, display_name)';

const _draftStatus = 'draft';
const _publishedStatus = 'published';

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
      _client
          .from('guide_stars')
          .select('guide_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false),
    );
    // A set literal keeps insertion order, so the newest star stays first.
    return {for (final row in rows) row['guide_id'] as String};
  }

  @override
  Future<List<Guide>> fetchGuidesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _send(
      _client.from('guide_feed').select().inFilter('id', ids),
    );
    final byId = {
      for (final row in rows) row['id'] as String: guideFromJson(row),
    };
    return [for (final id in ids) ?byId[id]];
  }

  @override
  Future<List<OwnGuide>> fetchMyGuides() async {
    final userId = _requireUserId();
    // Read from the table, not guide_feed, so drafts and hidden guides come
    // too; guides_read lets an author read every row they wrote, and the
    // author_id filter keeps other authors' published guides out.
    final rows = await _send(
      _client
          .from(_guidesTable)
          .select('*, $_authorEmbed')
          .eq('author_id', userId)
          .order('updated_at', ascending: false),
    );
    return [for (final row in rows) ownGuideFromJson(row)];
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

  @override
  Future<EditableGuide> fetchDraft(String id) async {
    final userId = _requireUserId();
    final rows = await _send(
      _client
          .from(_guidesTable)
          .select()
          .eq('id', id)
          .eq('author_id', userId)
          .limit(1),
    );
    if (rows.isEmpty) throw GuideNotFoundException(id);
    return editableGuideFromJson(rows.first);
  }

  @override
  Future<String> saveDraft(GuideDraft draft) =>
      _write(draft, status: _draftStatus);

  @override
  Future<String> publishGuide(GuideDraft draft) =>
      _write(draft, status: _publishedStatus);

  @override
  Future<String> insertRemixDraft(Map<String, dynamic> payload) async {
    final userId = _requireUserId();
    // guides.id is server-generated, so the insert reads it back.
    final rows = await _send(
      _client
          .from(_guidesTable)
          .insert({...payload, 'author_id': userId})
          .select('id'),
    );
    return rows.single['id'] as String;
  }

  @override
  Future<void> deleteGuide(String guideId) async {
    final userId = _requireUserId();
    // The author_id filter keeps a mistyped id from even reaching RLS.
    final rows = await _send(
      _client
          .from(_guidesTable)
          .delete()
          .eq('id', guideId)
          .eq('author_id', userId)
          .select('id'),
    );
    if (rows.isEmpty) {
      // RLS matched no row: not this author's guide, or already gone.
      throw const GuideWriteRejectedException(
        'This guide can no longer be deleted',
      );
    }
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
