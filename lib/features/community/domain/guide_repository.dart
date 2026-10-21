import 'guide.dart';
import 'guide_feed_query.dart';
import 'guide_validation.dart';

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

  /// Saves [draft] with `status = 'draft'` and returns its guide id: an
  /// insert when the draft has no id yet, otherwise an update in place.
  ///
  /// Throws [AuthRequiredException] when signed out, without sending a
  /// request (plan/07 § Editor: sign-in is asked for first).
  Future<String> saveDraft(GuideDraft draft);

  /// Saves [draft] with `status = 'published'` and returns its guide id.
  /// Publishing an already-published guide updates it in place, which
  /// leaves `published_at` as the trigger first set it.
  Future<String> publishGuide(GuideDraft draft);

  /// Deletes the signed-in author's own guide. RLS rejects deleting
  /// anyone else's.
  Future<void> deleteGuide(String guideId);
}
