import 'guide.dart';
import 'guide_feed_query.dart';
import 'guide_validation.dart';
import 'report_reason.dart';

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

  /// Inserts the signed-in user's `guide_reports` row for [id] (plan/07 §
  /// Moderation). Reporting the same guide a second time is success and
  /// leaves the first row alone, because one report per user per guide is
  /// the table's primary key. The client never writes `report_count` or
  /// `status`: the `apply_report` trigger hides a guide on the 3rd
  /// distinct reporter.
  ///
  /// Throws `AuthRequiredException` when signed out, and [ArgumentError]
  /// when [note] is longer than [maxReportNoteLength].
  Future<void> reportGuide(
    String id, {
    required ReportReason reason,
    String? note,
  });

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

/// No published guide has the requested id.
class GuideNotFoundException implements Exception {
  const GuideNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'GuideNotFoundException($id)';
}
