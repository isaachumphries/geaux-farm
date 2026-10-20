import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A guide by the `@geauxfarm` team account with made-up content.
Guide testGuide(
  String id, {
  String title = 'Balcony salsa garden in 4 pots',
  String author = 'geauxfarm',
  int difficulty = 1,
  List<String> spaceTypes = const ['balcony'],
  List<String> tags = const [],
  int stars = 0,
  int grows = 0,
  int remixes = 0,
  int? cost = 35,
  int stars7d = 0,
  String? coverPath,
}) => Guide(
  id: id,
  authorId: 'author-$author',
  authorUsername: author,
  title: title,
  summary: 'A made-up guide.',
  coverPath: coverPath,
  difficulty: difficulty,
  spaceTypes: spaceTypes,
  estCostUsd: cost,
  tags: tags,
  starCount: stars,
  growCount: grows,
  remixCount: remixes,
  stars7d: stars7d,
  publishedAt: DateTime.utc(2026, 10, 1),
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
    this.starred = const {},
    this.failFetch = false,
  });

  /// Rows for a query and offset; the default is an empty feed.
  final List<Guide> Function(GuideFeedQuery query, int offset)? pages;
  final Set<String> starred;

  /// While true, [fetchFeed] throws.
  bool failFetch;

  final fetches = <(GuideFeedQuery, int)>[];
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
    return starred;
  }

  @override
  String coverUrl(String coverPath) => 'http://supabase.test/$coverPath';
}
