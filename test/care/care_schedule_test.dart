import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/schedule_math.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';
import 'package:geaux_farm/features/care/domain/water_due.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

import '../helpers/care_fixtures.dart';

List<ScheduledCareTask> _schedule({
  required DateTime today,
  DateTime? now,
  List<Planting>? plantings,
  List<Map<String, Object>> tasks = const [],
  Availability? availability,
  Map<DateTime, WeatherDay>? days,
}) => buildCareSchedule(
  today: today,
  now: now ?? today,
  plantings: plantings ?? [carePlanting()],
  plantsById: {'kale': carePlant(tasks: tasks)},
  spacesById: {'s1': careSpace()},
  events: const [],
  availability: availability ?? careAllFree,
  days: days ?? careHotWeather(),
);

void main() {
  group('buildCareSchedule', () {
    test('includes water once, matching waterDue', () {
      final expected = waterDue(
        carePlanting(),
        carePlant(),
        careSpace(),
        const [],
        careHotWeather(),
        carePlanted,
      );
      final water = _schedule(today: carePlanted)
          .where((t) => t.kind == CareTaskKind.water)
          .toList();
      expect(water, hasLength(1));
      expect(water.single.due, expected);
    });

    test('flags a water task with the rain hint, and no other task', () {
      final today = DateTime(2026, 5, 2);
      final tomorrow = DateTime(2026, 5, 3);
      final base = careHotWeather()[tomorrow]!;
      final rainy = {
        ...careHotWeather(),
        tomorrow: WeatherDay(
          date: base.date,
          weatherCode: base.weatherCode,
          tmaxF: base.tmaxF,
          tminF: base.tminF,
          precipIn: 0.5,
          precipProb: 80,
          uvMax: null,
          sunshineS: 0,
          daylightS: 0,
          et0In: base.et0In,
          sunrise: '',
          sunset: '',
        ),
      };
      const tasks = [
        {'type': 'fertilize', 'everyDays': 1, 'note': 'Feed'},
      ];
      final wet = _schedule(today: today, tasks: tasks, days: rainy);
      expect(
        wet.where((t) => t.kind == CareTaskKind.water).single.rainSkip,
        isTrue,
      );
      expect(
        wet.where((t) => t.kind == CareTaskKind.fertilize).single.rainSkip,
        isFalse,
      );
      final dry = _schedule(today: today, tasks: tasks);
      expect(dry.any((t) => t.rainSkip), isFalse);
    });

    test('leaves out plantings that are not active or lack a date', () {
      expect(
        _schedule(
          today: carePlanted,
          plantings: [carePlanting(status: PlantingStatus.planned)],
        ),
        isEmpty,
      );
      expect(
        _schedule(
          today: carePlanted,
          plantings: [carePlanting(planted: false)],
        ),
        isEmpty,
      );
    });

    test('keeps tasks due within seven days and drops later ones', () {
      final tasks = _schedule(
        today: DateTime(2026, 5, 4),
        tasks: const [
          {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
          {'type': 'prune', 'everyDays': 30, 'note': 'Trim'},
        ],
      );
      final kinds = tasks.map((t) => t.kind).toSet();
      expect(kinds, contains(CareTaskKind.fertilize));
      expect(kinds, isNot(contains(CareTaskKind.prune)));
    });

    test(
      'keeps a task due on the last window day and drops one due after it',
      () {
        final tasks = _schedule(
          today: DateTime(2026, 5, 4),
          tasks: const [
            {'type': 'other', 'everyDays': 9, 'note': 'Last day'},
            {'type': 'other', 'everyDays': 10, 'note': 'First dropped'},
          ],
        );
        final notes = tasks.map((t) => t.note).toSet();
        expect(notes, contains('Last day'));
        expect(notes, isNot(contains('First dropped')));
      },
    );

    test('flags a past-due task as overdue and places it from today', () {
      final tasks = _schedule(
        today: DateTime(2026, 5, 6),
        now: DateTime(2026, 5, 6),
        tasks: const [
          {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
        ],
      );
      final fertilize = tasks
          .where((t) => t.kind == CareTaskKind.fertilize)
          .single;
      expect(fertilize.due, DateTime(2026, 5, 4));
      expect(fertilize.overdue, isTrue);
      expect(
        fertilize.slot,
        CareSlot(start: DateTime(2026, 5, 6, 6), outsideFreeTimes: false),
      );
    });

    test('shows harvest only once the planting is mature', () {
      const harvest = <String, Object>{
        'type': 'harvest',
        'everyDays': 1,
        'note': 'Pick',
      };
      final early = _schedule(
        today: DateTime(2026, 5, 2),
        tasks: const [harvest],
      );
      expect(early.where((t) => t.kind == CareTaskKind.harvest), isEmpty);

      final mature = _schedule(
        today: addDays(carePlanted, 400),
        tasks: const [harvest],
      );
      final pick = mature.where((t) => t.kind == CareTaskKind.harvest).single;
      expect(pick.overdue, isTrue);
    });

    test('sorts by slot start, then nickname', () {
      final tasks = _schedule(
        today: DateTime(2026, 5, 4),
        plantings: [
          carePlanting(id: 'p1', nickname: 'Basil'),
          carePlanting(id: 'p2', nickname: 'Arugula'),
        ],
        tasks: const [
          {'type': 'fertilize', 'everyDays': 3, 'note': 'Feed'},
        ],
      );
      final fertilizeNames = tasks
          .where((t) => t.kind == CareTaskKind.fertilize)
          .map((t) => t.nickname)
          .toList();
      expect(fertilizeNames, ['Arugula', 'Basil']);
    });
  });
}
