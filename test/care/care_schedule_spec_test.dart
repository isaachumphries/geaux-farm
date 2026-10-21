// buildCareSchedule against plan/05 § Other care tasks (recurrence from
// care.tasks, harvest at progress 1), § Watering model (overdue = due <
// today) and § Scheduling into free time (slot from now, outside free times).
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/schedule_math.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';

import '../helpers/care_fixtures.dart';
import '../recommendations/fixtures/baton_rouge.dart';

// carePlanted is Fri 2026-05-01; reference kale is a transplant with
// daysMin 50, medium water in a container, so hot weather makes water due
// the day after L.
DateTime _d(int day, [int hour = 0]) => DateTime(2026, 5, day, hour);

CareEvent _event(
  CareEventType type,
  DateTime at, {
  String plantingId = 'p1',
  String? note,
}) => CareEvent(
  id: '$plantingId-${type.name}-$at',
  plantingId: plantingId,
  type: type,
  at: at,
  note: note,
);

List<ScheduledCareTask> _schedule({
  required DateTime today,
  DateTime? now,
  List<Planting>? plantings,
  Plant? plant,
  List<Map<String, Object>> tasks = const [],
  List<CareEvent> events = const [],
  Availability? availability,
  bool withSpace = true,
}) => buildCareSchedule(
  today: today,
  now: now ?? today,
  plantings: plantings ?? [carePlanting()],
  plantsById: {'kale': plant ?? carePlant(tasks: tasks)},
  spacesById: withSpace ? {'s1': careSpace()} : const {},
  events: events,
  availability: availability ?? careAllFree,
  days: careHotWeather(),
);

ScheduledCareTask _only(List<ScheduledCareTask> tasks, CareTaskKind kind) =>
    tasks.where((t) => t.kind == kind).single;

void main() {
  test('each care.tasks entry recurs from its own last event (§ Other)', () {
    final tasks = _schedule(
      today: _d(8),
      tasks: const [
        {'type': 'fertilize', 'everyDays': 7, 'note': 'Feed'},
        {'type': 'prune', 'everyDays': 10, 'note': 'Trim'},
        {'type': 'other', 'everyDays': 4, 'note': 'Check aphids'},
      ],
      events: [
        _event(CareEventType.fertilize, _d(5, 18)),
        _event(CareEventType.note, _d(6, 9), note: 'Check aphids'),
        _event(CareEventType.water, _d(8, 7)),
      ],
    );
    expect(
      {for (final t in tasks) t.kind: t.due},
      {
        CareTaskKind.water: _d(9),
        CareTaskKind.fertilize: _d(12),
        CareTaskKind.prune: _d(11),
        CareTaskKind.other: _d(10),
      },
    );
    expect(_only(tasks, CareTaskKind.other).note, 'Check aphids');
  });

  test('harvest appears on the day progress reaches 1, not the day before', () {
    const tasks = [
      {'type': 'harvest', 'everyDays': 7, 'note': 'Pick'},
    ];
    final day49 = _schedule(today: addDays(carePlanted, 49), tasks: tasks);
    expect(day49.where((t) => t.kind == CareTaskKind.harvest), isEmpty);
    final day50 = _schedule(today: addDays(carePlanted, 50), tasks: tasks);
    expect(_only(day50, CareTaskKind.harvest).due, addDays(carePlanted, 7));
  });

  test('a task due today is not overdue; due yesterday is', () {
    const tasks = [
      {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
    ];
    expect(
      _only(
        _schedule(today: _d(4), tasks: tasks),
        CareTaskKind.fertilize,
      ).overdue,
      isFalse,
    );
    expect(
      _only(
        _schedule(today: _d(5), tasks: tasks),
        CareTaskKind.fertilize,
      ).overdue,
      isTrue,
    );
  });

  test('a plant with no water data gets care tasks but no water task', () {
    final dry = Plant.fromJson({
      ...rawKale(),
      'water': null,
      'care': {
        'dailyMinutes': 5,
        'weeklyMinutes': 10,
        'tasks': [
          {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
        ],
      },
    });
    final tasks = _schedule(today: _d(4), plant: dry);
    expect(tasks.map((t) => t.kind), [CareTaskKind.fertilize]);
  });

  test('harvested and removed plantings get no tasks', () {
    for (final status in [PlantingStatus.harvested, PlantingStatus.removed]) {
      expect(
        _schedule(
          today: _d(4),
          plantings: [carePlanting(status: status)],
          tasks: const [
            {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
          ],
        ),
        isEmpty,
        reason: status.name,
      );
    }
  });

  test('a free block that started before now is skipped', () {
    final tasks = _schedule(
      today: _d(4),
      now: _d(4, 9),
      tasks: const [
        {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
      ],
    );
    expect(
      _only(tasks, CareTaskKind.fertilize).slot,
      CareSlot(start: _d(4, 10), outsideFreeTimes: false),
    );
  });

  test('no free time puts each task at 08:00 on its due date, flagged', () {
    final tasks = _schedule(
      today: _d(4),
      availability: careFree({}),
      tasks: const [
        {'type': 'fertilize', 'everyDays': 5, 'note': 'Feed'},
      ],
    );
    expect(
      _only(tasks, CareTaskKind.fertilize).slot,
      CareSlot(start: _d(6, 8), outsideFreeTimes: true),
    );
  });

  test('sorts by slot start before nickname', () {
    final tasks = _schedule(
      today: _d(4),
      plantings: [
        carePlanting(id: 'p1', nickname: 'Basil'),
        carePlanting(id: 'p2', nickname: 'Arugula'),
      ],
      tasks: const [
        {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
      ],
      events: [_event(CareEventType.fertilize, _d(3), plantingId: 'p2')],
    ).where((t) => t.kind == CareTaskKind.fertilize).toList();
    expect(tasks.map((t) => t.nickname), ['Basil', 'Arugula']);
    expect(tasks.map((t) => t.slot.start), [_d(4, 6), _d(6, 6)]);
  });

  group('missing references throw StateError', () {
    test('no catalog plant for the planting', () {
      expect(
        () => buildCareSchedule(
          today: _d(4),
          now: _d(4),
          plantings: [carePlanting()],
          plantsById: const {},
          spacesById: {'s1': careSpace()},
          events: const [],
          availability: careAllFree,
          days: const {},
        ),
        throwsStateError,
      );
    });

    test('no space for the planting', () {
      expect(() => _schedule(today: _d(4), withSpace: false), throwsStateError);
    });
  });

  test('ScheduledCareTask equality covers every field', () {
    ScheduledCareTask make({
      String plantingId = 'p1',
      String nickname = 'Kale',
      CareTaskKind kind = CareTaskKind.water,
      int dueDay = 4,
      int slotDay = 4,
      bool outside = false,
      bool overdue = false,
      bool rainSkip = false,
      String? note,
    }) => ScheduledCareTask(
      plantingId: plantingId,
      nickname: nickname,
      kind: kind,
      due: _d(dueDay),
      slot: CareSlot(start: _d(slotDay, 6), outsideFreeTimes: outside),
      overdue: overdue,
      rainSkip: rainSkip,
      note: note,
    );
    expect(make(), make());
    expect(make().hashCode, make().hashCode);
    for (final other in [
      make(plantingId: 'p2'),
      make(nickname: 'Basil'),
      make(kind: CareTaskKind.fertilize),
      make(dueDay: 5),
      make(slotDay: 5),
      make(outside: true),
      make(overdue: true),
      make(rainSkip: true),
      make(note: 'Feed'),
    ]) {
      expect(make(), isNot(other), reason: '$other');
    }
  });
}
