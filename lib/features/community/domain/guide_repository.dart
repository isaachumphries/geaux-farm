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

  /// The published guide with [id]. Throws [GuideNotFoundException] when
  /// there is none, or it is hidden or not published.
  Future<Guide> fetchGuide(String id);

  /// Inserts the signed-in user's `guide_stars` row for [id]. Already
  /// starred is success. Throws `AuthRequiredException` (core/http.dart)
  /// when signed out. The client never writes `star_count`: a trigger owns
  /// it (plan/07 § Star).
  Future<void> starGuide(String id);

  /// Deletes the signed-in user's `guide_stars` row for [id]. Not starred is
  /// success. Throws `AuthRequiredException` when signed out.
  Future<void> unstarGuide(String id);

  /// The public URL of a cover stored at [coverPath].
  String coverUrl(String coverPath);
}

/// No published guide has the requested id.
class GuideNotFoundException implements Exception {
  const GuideNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'GuideNotFoundException($id)';
}
