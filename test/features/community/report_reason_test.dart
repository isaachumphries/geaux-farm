import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/domain/report_reason.dart';

// plan/07 § Moderation: reasons spam, unsafe, offensive, other, plus an
// optional note of at most 200 characters. The wire values are the
// `reason in (...)` check in 0001_init.sql, so they are a contract with
// the database, not display text.

void main() {
  test('every reason maps to its lowercase name on the wire', () {
    expect(ReportReason.spam.wireValue, 'spam');
    expect(ReportReason.unsafe.wireValue, 'unsafe');
    expect(ReportReason.offensive.wireValue, 'offensive');
    expect(ReportReason.other.wireValue, 'other');
  });

  test('the four reasons are the four the check constraint allows', () {
    expect(ReportReason.values.map((r) => r.wireValue), [
      'spam',
      'unsafe',
      'offensive',
      'other',
    ]);
  });

  test('a note of exactly 200 characters is accepted, 201 is not', () {
    expect(maxReportNoteLength, 200);
    expect(isValidReportNote('x' * 200), isTrue);
    expect(isValidReportNote('x' * 201), isFalse);
  });

  test('the note is optional', () {
    expect(isValidReportNote(null), isTrue);
    expect(isValidReportNote(''), isTrue);
  });
}
