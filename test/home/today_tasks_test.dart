import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';
import 'package:geaux_farm/features/home/domain/today_tasks.dart';

final _today = DateTime(2026, 10, 7);

ScheduledCareTask _task(
  String name,
  DateTime slot, {
  bool overdue = false,
  bool outside = false,
  CareTaskKind kind = CareTaskKind.water,
}) => ScheduledCareTask(
  plantingId: name,
  nickname: name,
  kind: kind,
  due: DateTime(slot.year, slot.month, slot.day),
  slot: CareSlot(start: slot, outsideFreeTimes: outside),
  overdue: overdue,
);

List<String> _names(TodayGroup g) => [for (final t in g.tasks) t.nickname];

void main() {
  test('block 6 and block 1 tasks: the 08:00 group comes first', () {
    // Block start hour = 6 + 2·block: block 1 is 08:00, block 6 is 18:00.
    final groups = todayGroups([
      _task('Basil', DateTime(2026, 10, 7, 18)),
      _task('Kale', DateTime(2026, 10, 7, 8)),
      _task('Mint', DateTime(2026, 10, 7, 18), kind: CareTaskKind.prune),
    ], _today);

    expect(
      [for (final g in groups) g.start],
      [DateTime(2026, 10, 7, 8), DateTime(2026, 10, 7, 18)],
    );
    expect(_names(groups[0]), ['Kale']);
    expect(_names(groups[1]), ['Basil', 'Mint']);
  });

  test('only today; overdue tasks are left for CR-01', () {
    final groups = todayGroups([
      _task('Tomorrow', DateTime(2026, 10, 8, 8)),
      _task('Yesterday', DateTime(2026, 10, 6, 8)),
      _task('Late', DateTime(2026, 10, 7, 8), overdue: true),
      _task('Today', DateTime(2026, 10, 7, 10)),
    ], _today);

    expect(groups, hasLength(1));
    expect(_names(groups.single), ['Today']);
  });

  test('tasks outside the free times come last, with no start', () {
    final groups = todayGroups([
      _task('Outside', DateTime(2026, 10, 7, 8), outside: true),
      _task('Evening', DateTime(2026, 10, 7, 18)),
    ], _today);

    expect(
      [for (final g in groups) g.start],
      [DateTime(2026, 10, 7, 18), null],
    );
    expect(_names(groups.last), ['Outside']);
  });

  test('no tasks today → no groups', () {
    expect(
      todayGroups([_task('Later', DateTime(2026, 10, 9, 8))], _today),
      isEmpty,
    );
    expect(todayGroups(const [], _today), isEmpty);
  });
}
