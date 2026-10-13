/// Weekly free time from OB-05 (plan/02 § OB-05 Availability).
///
/// `days` has 7 entries, index 0 = Monday through index 6 = Sunday. Bit `b`
/// of `days[i]` means block `b` is free on that weekday. Block `b` covers
/// `06:00 + 2·b` to `08:00 + 2·b` local time, so block 0 is 06:00–08:00 and
/// block 6 is 18:00–20:00.
class Availability {
  const Availability(this.days);

  final List<int> days;

  /// Number of weekdays with at least one free block.
  int get careDays => days.where((d) => d != 0).length;

  /// Total free blocks across the week × 2 hours.
  int get hoursPerWeek {
    var blocks = 0;
    for (final d in days) {
      for (var b = 0; b < 8; b++) {
        if (d & (1 << b) != 0) blocks++;
      }
    }
    return blocks * 2;
  }

  /// Whether block [block0to7] is free on ISO weekday [weekday1to7]
  /// (1 = Monday, 7 = Sunday).
  bool isFree(int weekday1to7, int block0to7) =>
      days[weekday1to7 - 1] & (1 << block0to7) != 0;
}
