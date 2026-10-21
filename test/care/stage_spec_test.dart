// Stage transitions at their exact day boundaries (plan/05 § Plantings,
// "Stage"): seed Sprouting for daysSince < 10, Growing while progress < 1,
// then the maturity kind. daysSince counts local calendar days.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/schedule_math.dart';
import 'package:geaux_farm/features/care/domain/stage.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';

import '../recommendations/fixtures/baton_rouge.dart';

final _planted = DateTime(2026, 4, 1);

DateTime _day(int n) => addDays(_planted, n);

Planting _planting(String startMethod, {DateTime? plantedOn}) => Planting(
  id: 'p1',
  plantId: 'cherry-tomato',
  spaceId: 's1',
  nickname: 'Tomato',
  setup: GrowSetup.outdoor,
  inContainer: false,
  startMethod: startMethod,
  plantedOn: plantedOn ?? _planted,
  status: PlantingStatus.active,
  createdAt: _planted,
);

Plant _plant(List<Map<String, dynamic>> starts) => Plant.fromJson({
  ...rawKale(),
  'id': 'cherry-tomato',
  'starts': starts,
  'maturityKind': 'harvest',
});

final _tomato = _plant(const [
  {'method': 'transplant', 'daysMin': 55, 'daysMax': 70},
  {'method': 'seed', 'daysMin': 85, 'daysMax': 100},
]);

void main() {
  test('seed is Sprouting on day 9 and Growing on day 10', () {
    expect(
      stageOf(_planting('seed'), _tomato, _day(9)).stage,
      PlantingStage.sprouting,
    );
    expect(
      stageOf(_planting('seed'), _tomato, _day(10)).stage,
      PlantingStage.growing,
    );
  });

  test('a transplant is never Sprouting, even on day 0', () {
    expect(
      stageOf(_planting('transplant'), _tomato, _day(0)).stage,
      PlantingStage.growing,
    );
  });

  test('transplant (daysMin 55): Growing on day 54, ready on day 55', () {
    final before = stageOf(_planting('transplant'), _tomato, _day(54));
    expect(before.stage, PlantingStage.growing);
    expect(before.progress, closeTo(54 / 55, 1e-9));

    final at = stageOf(_planting('transplant'), _tomato, _day(55));
    expect(at.stage, PlantingStage.readyToHarvest);
    expect(at.progress, 1);
  });

  test('a seed planting measures progress against the seed daysMin', () {
    final mid = stageOf(_planting('seed'), _tomato, _day(55));
    expect(mid.stage, PlantingStage.growing);
    expect(mid.progress, closeTo(55 / 85, 1e-9));
    expect(
      stageOf(_planting('seed'), _tomato, _day(84)).stage,
      PlantingStage.growing,
    );
    expect(
      stageOf(_planting('seed'), _tomato, _day(85)).stage,
      PlantingStage.readyToHarvest,
    );
  });

  test('Sprouting wins over maturity during the first 10 days', () {
    final quick = _plant(const [
      {'method': 'seed', 'daysMin': 5, 'daysMax': 8},
    ]);
    final r = stageOf(_planting('seed'), quick, _day(7));
    expect(r.progress, 1);
    expect(r.stage, PlantingStage.sprouting);
  });

  test('daysMin 0 counts as mature from planting day', () {
    final instant = _plant(const [
      {'method': 'transplant', 'daysMin': 0, 'daysMax': 0},
    ]);
    final r = stageOf(_planting('transplant'), instant, _day(0));
    expect(r.progress, 1);
    expect(r.stage, PlantingStage.readyToHarvest);
  });

  test('a planting dated after today clamps progress to 0', () {
    final r = stageOf(
      _planting('transplant', plantedOn: _day(5)),
      _tomato,
      _day(0),
    );
    expect(r.progress, 0);
    expect(r.stage, PlantingStage.growing);
  });

  test('daysSince counts calendar days, not elapsed 24h periods', () {
    // Planted 23:00, read 01:00 the next morning: one calendar day.
    final late = _planting('transplant', plantedOn: DateTime(2026, 4, 1, 23));
    expect(
      stageOf(late, _tomato, DateTime(2026, 4, 2, 1)).progress,
      closeTo(1 / 55, 1e-9),
    );
    // Across the US spring DST change (2026-03-08): still 30 days.
    final spring = _planting('transplant', plantedOn: DateTime(2026, 3, 1));
    expect(
      stageOf(spring, _tomato, DateTime(2026, 3, 31)).progress,
      closeTo(30 / 55, 1e-9),
    );
  });
}
