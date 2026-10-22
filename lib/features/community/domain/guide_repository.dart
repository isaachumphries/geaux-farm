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

  /// The signed-in author's own guide [id] for the editor, read from
  /// `guides` so drafts and hidden guides load too (`guides_read` lets an
  /// author read every row they wrote). Throws [AuthRequiredException]
  /// when signed out, without sending a request, and
  /// [GuideNotFoundException] when the author has no guide [id].
  Future<EditableGuide> fetchDraft(String id);

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

/// The `guides.status` values (0001_init.sql).
enum GuideStatus { draft, published, hidden }

/// An author's own guide as the editor opens it: the draft to edit and
/// the row's current status. A published guide is edited in place, so the
/// editor never offers to demote it back to a draft.
typedef EditableGuide = ({GuideDraft draft, GuideStatus status});

/// No guide the caller can read has the requested id: [fetchGuide] sees
/// published guides, [fetchDraft] the caller's own guides of any status.
class GuideNotFoundException implements Exception {
  const GuideNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'GuideNotFoundException($id)';
}

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
