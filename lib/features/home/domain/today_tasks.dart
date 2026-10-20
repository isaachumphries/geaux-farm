import '../../care/domain/care_schedule.dart';

/// One HM-02 "Today" group: the tasks in one free-time slot, or (when
/// [start] is null) those with no free block, which go last.
class TodayGroup {
  const TodayGroup(this.start, this.tasks);

  final DateTime? start;
  final List<ScheduledCareTask> tasks;
}

/// HM-02 "Today" (#73): tasks whose slot is on [today], grouped by slot
/// start, earliest first, so a block-1 08:00 group comes before a block-6
/// 18:00 one. Overdue tasks belong to CR-01's Overdue section and are left
/// out. Tasks outside the user's free times form the last group. Order
/// within a group follows [tasks].
List<TodayGroup> todayGroups(List<ScheduledCareTask> tasks, DateTime today) {
  final timed = <DateTime, List<ScheduledCareTask>>{};
  final outside = <ScheduledCareTask>[];
  for (final t in tasks) {
    final s = t.slot.start;
    if (t.overdue ||
        s.year != today.year ||
        s.month != today.month ||
        s.day != today.day) {
      continue;
    }
    if (t.slot.outsideFreeTimes) {
      outside.add(t);
    } else {
      (timed[s] ??= []).add(t);
    }
  }
  final starts = timed.keys.toList()..sort();
  return [
    for (final s in starts) TodayGroup(s, timed[s]!),
    if (outside.isNotEmpty) TodayGroup(null, outside),
  ];
}
