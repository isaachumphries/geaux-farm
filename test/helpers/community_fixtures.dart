import 'dart:async';

import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide_validation.dart';
import 'package:geaux_farm/features/community/domain/report_reason.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A guide by the `@geauxfarm` team account with made-up content.
Guide testGuide(
  String id, {
  String title = 'Balcony salsa garden in 4 pots',
  String author = 'geauxfarm',
  String? authorId,
  int difficulty = 1,
  List<String> spaceTypes = const ['balcony'],
  List<String> tags = const [],
  int stars = 0,
  int grows = 0,
  int remixes = 0,
  int? cost = 35,
  int stars7d = 0,
  String? coverPath,
  int? setupMinutes,
  List<GuideMaterial> materials = const [],
  List<GuideStep> steps = const [],
  List<String> plantIds = const [],
  String? forkedFrom,
}) => Guide(
  id: id,
  authorId: authorId ?? 'author-$author',
  authorUsername: author,
  title: title,
  summary: 'A made-up guide.',
  coverPath: coverPath,
  difficulty: difficulty,
  spaceTypes: spaceTypes,
  estCostUsd: cost,
  setupMinutes: setupMinutes,
  materials: materials,
  steps: steps,
  plantIds: plantIds,
  forkedFrom: forkedFrom,
  tags: tags,
  starCount: stars,
  growCount: grows,
  remixCount: remixes,
  stars7d: stars7d,
  publishedAt: DateTime.utc(2026, 10, 1),
);

/// [guide] with another star count.
Guide guideWithStars(Guide guide, int stars) => Guide(
  id: guide.id,
  authorId: guide.authorId,
  authorUsername: guide.authorUsername,
  authorDisplayName: guide.authorDisplayName,
  title: guide.title,
  summary: guide.summary,
  coverPath: guide.coverPath,
  difficulty: guide.difficulty,
  spaceTypes: guide.spaceTypes,
  estCostUsd: guide.estCostUsd,
  setupMinutes: guide.setupMinutes,
  materials: guide.materials,
  steps: guide.steps,
  plantIds: guide.plantIds,
  tags: guide.tags,
  forkedFrom: guide.forkedFrom,
  starCount: stars,
  growCount: guide.growCount,
  remixCount: guide.remixCount,
  stars7d: guide.stars7d,
  publishedAt: guide.publishedAt,
);

/// `guide_feed` row JSON for [guide], as PostgREST returns it.
Map<String, Object?> guideRow(Guide guide) => {
  'id': guide.id,
  'author_id': guide.authorId,
  'author_username': guide.authorUsername,
  'author_display_name': null,
  'title': guide.title,
  'summary': guide.summary,
  'cover_path': guide.coverPath,
  'difficulty': guide.difficulty,
  'space_types': guide.spaceTypes,
  'est_cost_usd': guide.estCostUsd,
  'setup_minutes': guide.setupMinutes,
  'materials': <Object?>[],
  'steps': <Object?>[],
  'plant_ids': guide.plantIds,
  'tags': guide.tags,
  'forked_from': null,
  'status': 'published',
  'star_count': guide.starCount,
  'grow_count': guide.growCount,
  'remix_count': guide.remixCount,
  'report_count': 0,
  'created_at': '2026-10-01T00:00:00+00:00',
  'updated_at': '2026-10-01T00:00:00+00:00',
  'published_at': guide.publishedAt?.toIso8601String(),
  'stars_7d': guide.stars7d,
};

/// A [SupabaseClient] whose HTTP layer is [handler]: nothing leaves the
/// process.
SupabaseClient mockSupabase(
  Future<http.Response> Function(http.Request request) handler,
) => SupabaseClient(
  'http://supabase.test',
  'anon-key',
  httpClient: MockClient(handler),
);

/// A [GuideRepository] that answers from [pages] and records every call.
class FakeGuideRepository implements GuideRepository {
  FakeGuideRepository({
    this.pages,
    Set<String> starred = const {},
    this.failFetch = false,
    this.guides = const {},
    this.newGuideId = 'g-new',
    this.writeError,
  }) : starred = {...starred};

  /// Guides [fetchGuide] answers with, by id; any other id is not found.
  /// Their star counts move with [starGuide] and [unstarGuide], like the
  /// trigger-owned count on the server.
  final Map<String, Guide> guides;

  /// Rows for a query and offset; the default is an empty feed.
  final List<Guide> Function(GuideFeedQuery query, int offset)? pages;

  /// The signed-in user's stars: changed by [starGuide] and [unstarGuide].
  final Set<String> starred;

  /// While true, [fetchFeed] throws.
  bool failFetch;

  /// While set, [starredGuideIds] throws it after counting the call.
  Object? starredError;

  /// While set, every write ([starGuide], [unstarGuide], [saveDraft],
  /// [publishGuide], [deleteGuide]) throws it after recording the call.
  Object? writeError;

  /// Held open until completed, to observe the optimistic state.
  Completer<void>? writeGate;

  /// The id an insert returns, standing in for the server-generated one.
  final String newGuideId;

  /// Every draft write, in order, as `(action, draft)`.
  final draftWrites = <(String, GuideDraft)>[];
  final deleted = <String>[];

  final fetches = <(GuideFeedQuery, int)>[];
  final guideFetches = <String>[];

  /// `star:<id>`, `unstar:<id>` and `report:<id>`, in call order.
  final writes = <String>[];

  /// One row per stored report, keyed by guide id. The fake has a single
  /// signed-in user, so guide id stands in for the `(guide_id,
  /// reporter_id)` primary key; it cannot model two reporters on one
  /// guide.
  final reports = <String, ({ReportReason reason, String? note})>{};
  var starredFetches = 0;

  @override
  Future<List<Guide>> fetchFeed(GuideFeedQuery query, {int offset = 0}) async {
    fetches.add((query, offset));
    if (failFetch) throw Exception('offline');
    return pages?.call(query, offset) ?? const [];
  }

  @override
  Future<Set<String>> starredGuideIds() async {
    starredFetches++;
    if (starredError != null) throw starredError!;
    return starred;
  }

  @override
  Future<Guide> fetchGuide(String id) async {
    guideFetches.add(id);
    if (failFetch) throw Exception('offline');
    final guide = guides[id] ?? (throw GuideNotFoundException(id));
    return guideWithStars(guide, guide.starCount + (_starDelta[id] ?? 0));
  }

  final _starDelta = <String, int>{};

  @override
  Future<void> starGuide(String id) async {
    await _write('star:$id');
    if (starred.add(id)) _starDelta[id] = (_starDelta[id] ?? 0) + 1;
  }

  @override
  Future<void> unstarGuide(String id) async {
    await _write('unstar:$id');
    if (starred.remove(id)) _starDelta[id] = (_starDelta[id] ?? 0) - 1;
  }

  @override
  Future<void> reportGuide(
    String id, {
    required ReportReason reason,
    String? note,
  }) async {
    // The real repository validates before it sends, so the fake must
    // not record a write the real one would never make.
    if (!isValidReportNote(note?.trim())) {
      throw ArgumentError.value(note, 'note', 'too long');
    }
    await _write('report:$id');
    // The primary key keeps the first report; a second one changes nothing.
    reports.putIfAbsent(id, () => (reason: reason, note: note));
  }

  Future<void> _write(String call) async {
    writes.add(call);
    await writeGate?.future;
    if (writeError != null) throw writeError!;
  }

  @override
  String coverUrl(String coverPath) => 'http://supabase.test/$coverPath';

  @override
  Future<String> saveDraft(GuideDraft draft) => _writeDraft('saveDraft', draft);

  @override
  Future<String> publishGuide(GuideDraft draft) =>
      _writeDraft('publishGuide', draft);

  @override
  Future<void> deleteGuide(String guideId) async {
    final error = writeError;
    if (error != null) throw error;
    deleted.add(guideId);
  }

  Future<String> _writeDraft(String action, GuideDraft draft) async {
    draftWrites.add((action, draft));
    final error = writeError;
    if (error != null) throw error;
    return draft.id ?? newGuideId;
  }
}
