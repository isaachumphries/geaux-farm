import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/growth.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';

import '../recommendations/fixtures/baton_rouge.dart';

final _planted = DateTime(2026, 8, 1);

DateTime _day(int n) => plusDays(_planted, n);

Planting _planting({
  String plantId = 'kale',
  String startMethod = 'transplant',
  GrowSetup setup = GrowSetup.indoor,
  PlantingStatus status = PlantingStatus.active,
  DateTime? plantedOn,
  bool planted = true,
}) => Planting(
  id: 'p1',
  plantId: plantId,
  spaceId: 's1',
  nickname: 'Mine',
  setup: setup,
  inContainer: true,
  startMethod: startMethod,
  plantedOn: planted ? (plantedOn ?? _planted) : null,
  status: status,
  createdAt: DateTime(2026, 7, 1),
);

/// Kale's record with [changes] over the top-level fields.
Plant _kale([Map<String, dynamic> changes = const {}]) =>
    Plant.fromJson({...rawKale(), ...changes});

CareEvent _event(CareEventType type, DateTime at, {String? note, String? id}) =>
    CareEvent(
      id: id ?? '${type.name}-$at',
      plantingId: 'p1',
      type: type,
      at: at,
      note: note,
    );

void main() {
  final plants = loadReferencePlants();
  final tomato = plants['cherry-tomato']!; // transplant daysMin 55
  final lavender = plants['english-lavender']!;

  group('growthOf (plan/05 Stage)', () {
    test('seed start, 5 days in: Sprouting', () {
      final r = growthOf(_planting(startMethod: 'seed'), tomato, _day(5))!;
      expect(r.stage, GrowthStage.sprouting);
      expect(r.stage.label, 'Sprouting');
    });

    test('seed sprouts through day 9 and grows from day 10', () {
      final seed = _planting(startMethod: 'seed');
      expect(growthOf(seed, tomato, _day(9))!.stage, GrowthStage.sprouting);
      expect(growthOf(seed, tomato, _day(10))!.stage, GrowthStage.growing);
    });

    test('transplant never sprouts, even on day 0', () {
      final r = growthOf(_planting(), tomato, _day(0))!;
      expect(r.stage, GrowthStage.growing);
      expect(r.progress, 0);
    });

    test('cherry tomato transplant, 30 days in: Growing', () {
      final r = growthOf(_planting(), tomato, _day(30))!;
      expect(r.stage.label, 'Growing');
      expect(r.progress, closeTo(30 / 55, 1e-9));
    });

    test('cherry tomato transplant, 70 days in: Ready to harvest', () {
      final r = growthOf(_planting(), tomato, _day(70))!;
      expect(r.stage.label, 'Ready to harvest');
      expect(r.progress, 1);
    });

    test('the stage turns at daysMin, not a day before', () {
      expect(
        growthOf(_planting(), tomato, _day(54))!.stage,
        GrowthStage.growing,
      );
      expect(
        growthOf(_planting(), tomato, _day(55))!.stage,
        GrowthStage.readyToHarvest,
      );
    });

    test('progress is daysSince over the start method\'s daysMin', () {
      // Seed daysMin 85, not the transplant's 55.
      final r = growthOf(_planting(startMethod: 'seed'), tomato, _day(34))!;
      expect(r.progress, closeTo(0.4, 1e-9));
    });

    test('a bloom plant is Blooming once mature', () {
      final r = growthOf(_planting(), lavender, _day(60))!;
      expect(r.stage.label, 'Blooming');
    });

    test('an establish plant is Established once mature', () {
      final shrub = _kale({'maturityKind': 'establish'});
      final r = growthOf(_planting(), shrub, _day(50))!;
      expect(r.stage.label, 'Established');
    });

    test('a foliage plant keeps Growing and hides the progress ring', () {
      final pothos = _kale({'maturityKind': 'foliage'});
      final r = growthOf(_planting(), pothos, _day(400))!;
      expect(r.stage, GrowthStage.growing);
      expect(r.showsProgressRing, isFalse);
    });

    test('every other kind shows the progress ring', () {
      for (final kind in ['harvest', 'bloom', 'establish']) {
        final r = growthOf(_planting(), _kale({'maturityKind': kind}), _day(1));
        expect(r!.showsProgressRing, isTrue, reason: kind);
      }
    });

    test('a planting with no planted date has no growth reading', () {
      expect(growthOf(_planting(planted: false), tomato, _day(3)), isNull);
    });

    test('a planted date in the future clamps progress to 0', () {
      final r = growthOf(_planting(), tomato, _day(-4))!;
      expect(r.progress, 0);
      expect(r.stage, GrowthStage.growing);
    });

    test('plant with no starts reads progress 0 and stays Growing', () {
      final r = growthOf(
        _planting(),
        _kale({'starts': <Map<String, dynamic>>[]}),
        _day(200),
      )!;
      expect(r.progress, 0);
      expect(r.stage, GrowthStage.growing);
    });

    test('a start with daysMin 0 is mature at once', () {
      final instant = _kale({
        'starts': [
          {'method': 'transplant', 'daysMin': 0, 'daysMax': 5},
        ],
      });
      final r = growthOf(_planting(), instant, _day(0))!;
      expect(r.progress, 1);
      expect(r.stage, GrowthStage.readyToHarvest);
    });
  });

  group('startFor', () {
    test('picks the start that matches how the planting began', () {
      final seed = startFor(tomato, _planting(startMethod: 'seed'))!;
      expect(seed.method, StartMethod.seed);
      expect(seed.daysMin, 85);
    });

    test('falls back to the first start when the method is not offered', () {
      final s = startFor(lavender, _planting(startMethod: 'seed'))!;
      expect(s.method, StartMethod.transplant);
    });

    test('is null when the plant lists no starts', () {
      final none = _kale({'starts': <Map<String, dynamic>>[]});
      expect(startFor(none, _planting()), isNull);
    });
  });

  group('calendar helpers', () {
    test('calendarDay drops the time of day', () {
      expect(calendarDay(DateTime(2026, 8, 1, 23, 59)), DateTime(2026, 8, 1));
    });

    test('plusDays rolls over month and year ends', () {
      expect(plusDays(DateTime(2026, 12, 30), 3), DateTime(2027, 1, 2));
      expect(plusDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });

    test('daysFrom counts calendar days and ignores the time of day', () {
      expect(daysFrom(DateTime(2026, 8, 1, 23), DateTime(2026, 8, 2, 1)), 1);
      expect(daysFrom(DateTime(2026, 8, 2), DateTime(2026, 8, 1)), -1);
    });

    test('daysFrom is not shifted by a daylight-saving change', () {
      // US clocks went forward on 2026-03-08.
      expect(daysFrom(DateTime(2026, 3, 7), DateTime(2026, 3, 9)), 2);
      expect(daysFrom(DateTime(2026, 10, 31), DateTime(2026, 11, 2)), 2);
    });
  });

  group('careDueFor', () {
    final kale = _kale(); // water every 3 days, harvest 7, fertilize 21

    List<CareDue> due(
      Planting pl,
      Plant p,
      DateTime today, [
      List<CareEvent> events = const [],
    ]) => careDueFor(pl, p, events, today);

    test('only active plantings with a planted date have care', () {
      for (final s in [
        PlantingStatus.planned,
        PlantingStatus.harvested,
        PlantingStatus.removed,
      ]) {
        expect(due(_planting(status: s), kale, _day(5)), isEmpty, reason: '$s');
      }
      expect(due(_planting(planted: false), kale, _day(5)), isEmpty);
    });

    test('a new planting is due its first water on the planted day', () {
      final jobs = due(_planting(), kale, _day(0));
      expect(jobs, hasLength(1));
      expect(jobs.single.type, CareEventType.water);
      expect(jobs.single.due, _day(0));
    });

    test('water repeats from the last water, indoors every 3 days', () {
      final jobs = due(_planting(), kale, _day(2), [
        _event(CareEventType.water, _day(1).add(const Duration(hours: 20))),
      ]);
      expect(jobs.single.due, _day(4));
    });

    test('a skip resets the water clock like a watering', () {
      final jobs = due(_planting(), kale, _day(2), [
        _event(CareEventType.water, _day(0)),
        _event(CareEventType.skipWater, _day(2)),
      ]);
      expect(jobs.single.due, _day(5));
    });

    test('the latest water counts, whatever order events arrive in', () {
      final jobs = due(_planting(), kale, _day(4), [
        _event(CareEventType.water, _day(3)),
        _event(CareEventType.water, _day(1)),
      ]);
      expect(jobs.single.due, _day(6));
    });

    test('events on other plantings are ignored', () {
      final other = CareEvent(
        id: 'x',
        plantingId: 'p2',
        type: CareEventType.water,
        at: _day(2),
      );
      expect(due(_planting(), kale, _day(2), [other]).single.due, _day(0));
    });

    test('indoor and greenhouse use the indoor interval, outdoor its own', () {
      final basil = plants['sweet-basil']!; // outdoor 2 days, indoor 3
      final watered = [_event(CareEventType.water, _day(0))];
      DateTime waterDue(GrowSetup s) =>
          due(_planting(setup: s), basil, _day(1), watered).single.due;
      expect(waterDue(GrowSetup.indoor), _day(3));
      expect(waterDue(GrowSetup.greenhouse), _day(3));
      expect(waterDue(GrowSetup.outdoor), _day(2));
    });

    test('a plant with no water need has no watering job', () {
      final raw = rawKale()..remove('water');
      final dry = Plant.fromJson(raw);
      expect(
        due(
          _planting(),
          dry,
          _day(0),
        ).where((j) => j.type == CareEventType.water),
        isEmpty,
      );
    });

    test('harvest stays hidden until the plant has matured', () {
      // Kale transplant daysMin is 50.
      final early = due(_planting(), kale, _day(49));
      expect(early.map((j) => j.type), isNot(contains(CareEventType.harvest)));
      final mature = due(_planting(), kale, _day(50));
      expect(mature.map((j) => j.type), contains(CareEventType.harvest));
    });

    test('mature plant lists overdue jobs soonest first', () {
      final jobs = due(_planting(), kale, _day(50));
      expect(jobs.map((j) => j.type), [
        CareEventType.water,
        CareEventType.harvest,
        CareEventType.fertilize,
      ]);
      expect(jobs.map((j) => j.due), [_day(0), _day(7), _day(21)]);
      expect(jobs[1].note, 'Pick the outer leaves; leave the center growing');
    });

    test('a task logged resets its own clock only', () {
      final jobs = due(_planting(), kale, _day(50), [
        _event(CareEventType.fertilize, _day(30)),
      ]);
      final fert = jobs.singleWhere((j) => j.type == CareEventType.fertilize);
      expect(fert.due, _day(51));
      final harvest = jobs.singleWhere((j) => j.type == CareEventType.harvest);
      expect(harvest.due, _day(7));
    });

    test('the window runs through today + 6 and no further', () {
      // Fertilize is due on day 21.
      bool listed(int todayOffset) => due(
        _planting(),
        kale,
        _day(todayOffset),
        [_event(CareEventType.water, _day(todayOffset))],
      ).any((j) => j.type == CareEventType.fertilize);
      expect(listed(14), isFalse);
      expect(listed(15), isTrue);
    });

    test('an "other" task is done by a note with the same text', () {
      final aphids = _kale({
        'care': {
          'dailyMinutes': 2,
          'weeklyMinutes': 10,
          'tasks': [
            {'type': 'other', 'everyDays': 14, 'note': 'Check for aphids'},
          ],
        },
      });
      CareDue check(List<CareEvent> events) => due(
        _planting(),
        aphids,
        _day(20),
        events,
      ).singleWhere((j) => j.type == CareEventType.note);

      expect(check(const []).due, _day(14));
      expect(check(const []).note, 'Check for aphids');
      expect(
        check([_event(CareEventType.note, _day(10), note: 'Check for aphids')])
            .due,
        _day(24),
      );
      // A journal note with other text does not complete the task.
      expect(
        check([_event(CareEventType.note, _day(10), note: 'Pretty!')]).due,
        _day(14),
      );
    });

    test('a catalog prune task is its own job', () {
      final p = _kale({
        'care': {
          'dailyMinutes': 2,
          'weeklyMinutes': 10,
          'tasks': [
            {'type': 'prune', 'everyDays': 7, 'note': 'Trim'},
          ],
        },
      });
      final jobs = due(_planting(), p, _day(8));
      expect(jobs.map((j) => j.type), [
        CareEventType.water,
        CareEventType.prune,
      ]);
    });
  });
}
