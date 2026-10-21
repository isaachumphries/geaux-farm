/// Why a guide was reported (plan/07 § Moderation).
///
/// [wireValue] is what `guide_reports.reason` stores, and the
/// `reason in ('spam','unsafe','offensive','other')` check in
/// `0001_init.sql` is exactly this set.
enum ReportReason {
  spam('Spam'),
  unsafe('Unsafe'),
  offensive('Offensive'),
  other('Other');

  const ReportReason(this.label);

  /// Shown in the report sheet. The plan names the reasons but has no
  /// sheet copy of its own, so these are the reason names capitalised.
  final String label;

  /// The value stored in `guide_reports.reason`.
  String get wireValue => name;
}

/// The longest note `guide_reports.note` accepts (plan/07 § Moderation,
/// `check (char_length(note) <= 200)`).
const maxReportNoteLength = 200;

/// Whether [note] fits `guide_reports.note`. The note is optional, so null
/// and empty both pass; only length is checked here.
bool isValidReportNote(String? note) =>
    note == null || note.length <= maxReportNoteLength;
