import '../../onboarding/domain/availability.dart';
import 'schedule_math.dart';

/// Block 0 starts at 06:00; each block is two hours (8 blocks, 06:00–22:00).
const _firstBlockHour = 6;
const _blockHours = 2;
const _blockCount = 8;

/// Days searched forward from today for a free block.
const _windowDays = 14;

/// Start hour used when nothing is free in the window (plan/05 § Scheduling).
const _outsideFreeHour = 8;

/// Where a care task lands in the user's free time.
class CareSlot {
  const CareSlot({required this.start, required this.outsideFreeTimes});

  /// Local start of the slot.
  final DateTime start;

  /// True when no free block exists in the window. [start] is then 08:00 on
  /// the due date, and the UI shows "Outside your free times".
  final bool outsideFreeTimes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareSlot &&
          other.start == start &&
          other.outsideFreeTimes == outsideFreeTimes;

  @override
  int get hashCode => Object.hash(start, outsideFreeTimes);

  @override
  String toString() => 'CareSlot($start, outsideFreeTimes: $outsideFreeTimes)';
}

/// Start of the free block a task due on [due] goes in. See [findSlot].
DateTime slotFor(DateTime due, Availability a, DateTime now) =>
    findSlot(due, a, now).start;

/// Picks the free block for a task due on [due], never earlier than [now]:
/// 1. the latest day on or before [due] (capped at the 14-day window) that
///    has a free block still ahead, using that day's earliest such block;
/// 2. otherwise the earliest such block anywhere in the window (covers
///    overdue tasks, whose due day is already past);
/// 3. otherwise 08:00 on the due date, flagged [CareSlot.outsideFreeTimes].
CareSlot findSlot(DateTime due, Availability a, DateTime now) {
  final today = dayOf(now);
  final dueDay = dayOf(due);
  final lastDay = addDays(today, _windowDays - 1);

  var day = dueDay.isAfter(lastDay) ? lastDay : dueDay;
  for (; !day.isBefore(today); day = _previousDay(day)) {
    final start = _earliestFreeBlock(day, a, now);
    if (start != null) return CareSlot(start: start, outsideFreeTimes: false);
  }
  for (var d = today; !d.isAfter(lastDay); d = addDays(d, 1)) {
    final start = _earliestFreeBlock(d, a, now);
    if (start != null) return CareSlot(start: start, outsideFreeTimes: false);
  }
  return CareSlot(
    start: DateTime(dueDay.year, dueDay.month, dueDay.day, _outsideFreeHour),
    outsideFreeTimes: true,
  );
}

DateTime? _earliestFreeBlock(DateTime day, Availability a, DateTime now) {
  for (var b = 0; b < _blockCount; b++) {
    if (!a.isFree(day.weekday, b)) continue;
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      _firstBlockHour + _blockHours * b,
    );
    if (!start.isBefore(now)) return start;
  }
  return null;
}

DateTime _previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);
