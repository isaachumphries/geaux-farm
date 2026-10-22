import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/care/domain/stage.dart';
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

void main() {
  final plants = loadReferencePlants();
  final tomato = plants['cherry-tomato']!; // transplant daysMin 55
  final lavender = plants['english-lavender']!;

  group('stageOf as GD-01/GD-02 read it (plan/05 Stage)', () {
    test('seed start, 5 days in: Sprouting', () {
      final r = stageOf(_planting(startMethod: 'seed'), tomato, _day(5));
      expect(r.stage, PlantingStage.sprouting);
      expect(r.stage.label, 'Sprouting');
    });

    test('seed sprouts through day 9 and grows from day 10', () {
      final seed = _planting(startMethod: 'seed');
      expect(stageOf(seed, tomato, _day(9)).stage, PlantingStage.sprouting);
      expect(stageOf(seed, tomato, _day(10)).stage, PlantingStage.growing);
    });

    test('transplant never sprouts, even on day 0', () {
      final r = stageOf(_planting(), tomato, _day(0));
      expect(r.stage, PlantingStage.growing);
      expect(r.progress, 0);
    });

    test('cherry tomato transplant, 30 days in: Growing', () {
      final r = stageOf(_planting(), tomato, _day(30));
      expect(r.stage.label, 'Growing');
      expect(r.progress, closeTo(30 / 55, 1e-9));
    });

    test('cherry tomato transplant, 70 days in: Ready to harvest', () {
      final r = stageOf(_planting(), tomato, _day(70));
      expect(r.stage.label, 'Ready to harvest');
      expect(r.progress, 1);
    });

    test('the stage turns at daysMin, not a day before', () {
      expect(
        stageOf(_planting(), tomato, _day(54)).stage,
        PlantingStage.growing,
      );
      expect(
        stageOf(_planting(), tomato, _day(55)).stage,
        PlantingStage.readyToHarvest,
      );
    });

    test('progress is daysSince over the start method\'s daysMin', () {
      // Seed daysMin 85, not the transplant's 55.
      final r = stageOf(_planting(startMethod: 'seed'), tomato, _day(34));
      expect(r.progress, closeTo(0.4, 1e-9));
    });

    test('a bloom plant is Blooming once mature', () {
      final r = stageOf(_planting(), lavender, _day(60));
      expect(r.stage.label, 'Blooming');
    });

    test('an establish plant is Established once mature', () {
      final shrub = _kale({'maturityKind': 'establish'});
      final r = stageOf(_planting(), shrub, _day(50));
      expect(r.stage.label, 'Established');
    });

    test('a foliage plant keeps Growing and hides the progress ring', () {
      final pothos = _kale({'maturityKind': 'foliage'});
      final r = stageOf(_planting(), pothos, _day(400));
      expect(r.stage, PlantingStage.growing);
      expect(r.showsProgressRing, isFalse);
    });

    test('every other kind shows the progress ring', () {
      for (final kind in ['harvest', 'bloom', 'establish']) {
        final r = stageOf(_planting(), _kale({'maturityKind': kind}), _day(1));
        expect(r.showsProgressRing, isTrue, reason: kind);
      }
    });

    test('a planted date in the future clamps progress to 0', () {
      final r = stageOf(_planting(), tomato, _day(-4));
      expect(r.progress, 0);
      expect(r.stage, PlantingStage.growing);
    });

    test('plant with no starts reads progress 0 and stays Growing', () {
      final r = stageOf(
        _planting(),
        _kale({'starts': <Map<String, dynamic>>[]}),
        _day(200),
      );
      expect(r.progress, 0);
      expect(r.stage, PlantingStage.growing);
    });

    test('a start with daysMin 0 is mature at once', () {
      final instant = _kale({
        'starts': [
          {'method': 'transplant', 'daysMin': 0, 'daysMax': 5},
        ],
      });
      final r = stageOf(_planting(), instant, _day(0));
      expect(r.progress, 1);
      expect(r.stage, PlantingStage.readyToHarvest);
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
}
