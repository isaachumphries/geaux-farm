import 'guide.dart';
import 'guide_feed_query.dart';

/// Community guides (plan/07, plan/09 § Supabase). Presentation and
/// providers depend on this interface only.
///
/// Implementations throw `NetworkException` (core/http.dart) when a request
/// never got a usable answer.
abstract interface class GuideRepository {
  /// One page of the feed: up to [guideFeedPageSize] guides starting at row
  /// [offset], filtered by [query] and then ordered by its sort.
  Future<List<Guide>> fetchFeed(GuideFeedQuery query, {int offset = 0});

  /// The ids of the guides the signed-in user starred; empty when signed
  /// out.
  Future<Set<String>> starredGuideIds();

  /// The public URL of a cover stored at [coverPath].
  String coverUrl(String coverPath);
}
