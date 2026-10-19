import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/stage.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';

import '../recommendations/fixtures/baton_rouge.dart';

final _planted = DateTime(2026, 5, 1);

DateTime _day(int n) => _planted.add(Duration(days: n));

Planting _planting({String startMethod = 'transplant'}) => Planting(
  id: 'p1',
  plantId: 'cherry-tomato',
  spaceId: 's1',
  nickname: 'Tomato',
  setup: GrowSetup.outdoor,
  inContainer: false,
  startMethod: startMethod,
  plantedOn: _planted,
  status: PlantingStatus.active,
  createdAt: DateTime(2026, 4, 1),
);

/// Kale's raw record with starts and maturity replaced.
Plant _plant({
  required List<Map<String, dynamic>>? starts,
  required String maturityKind,
}) {
  final raw = rawKale();
  return Plant.fromJson({
    ...raw,
    'id': 'cherry-tomato',
    'starts': starts,
    'maturityKind': maturityKind,
  });
}

const _transplant55 = {'method': 'transplant', 'daysMin': 55, 'daysMax': 70};
const _seed85 = {'method': 'seed', 'daysMin': 85, 'daysMax': 100};

void main() {
  final tomato = _plant(
    starts: const [_transplant55, _seed85],
    maturityKind: 'harvest',
  );

  group('stageOf', () {
    test('seed in its first 10 days shows Sprouting', () {
      final r = stageOf(_planting(startMethod: 'seed'), tomato, _day(5));
      expect(r.stage, PlantingStage.sprouting);
    });

    test('seed after 10 days is Growing', () {
      final r = stageOf(_planting(startMethod: 'seed'), tomato, _day(10));
      expect(r.stage, PlantingStage.growing);
    });

    test('transplant before maturity is Growing with partial progress', () {
      final r = stageOf(_planting(), tomato, _day(30));
      expect(r.stage, PlantingStage.growing);
      expect(r.progress, closeTo(30 / 55, 1e-9));
      expect(r.showsProgressRing, isTrue);
    });

    test('transplant at maturity on a harvest plant is Ready to harvest', () {
      final r = stageOf(_planting(), tomato, _day(70));
      expect(r.stage, PlantingStage.readyToHarvest);
      expect(r.progress, 1);
    });

    test('progress stays clamped at 1 well past maturity', () {
      final r = stageOf(_planting(), tomato, _day(500));
      expect(r.progress, 1);
      expect(r.stage, PlantingStage.readyToHarvest);
    });

    test('bloom maturity at maturity shows Blooming', () {
      final bloom = _plant(
        starts: const [_transplant55],
        maturityKind: 'bloom',
      );
      expect(
        stageOf(_planting(), bloom, _day(60)).stage,
        PlantingStage.blooming,
      );
    });

    test('establish maturity at maturity shows Established', () {
      final establish = _plant(
        starts: const [_transplant55],
        maturityKind: 'establish',
      );
      expect(
        stageOf(_planting(), establish, _day(60)).stage,
        PlantingStage.established,
      );
    });

    test('foliage plant stays Growing and hides the progress ring', () {
      final foliage = _plant(
        starts: const [_transplant55],
        maturityKind: 'foliage',
      );
      final r = stageOf(_planting(), foliage, _day(70));
      expect(r.stage, PlantingStage.growing);
      expect(r.showsProgressRing, isFalse);
    });

    test('unknown start method falls back to the first catalog start', () {
      final r = stageOf(_planting(startMethod: 'cutting'), tomato, _day(30));
      expect(r.progress, closeTo(30 / 55, 1e-9));
    });

    test('plant with no starts reports zero progress', () {
      final noStarts = _plant(starts: null, maturityKind: 'harvest');
      final r = stageOf(_planting(), noStarts, _day(70));
      expect(r.progress, 0);
      expect(r.stage, PlantingStage.growing);
    });

    test('throws when plantedOn is null', () {
      final unplanted = Planting(
        id: 'p1',
        plantId: 'cherry-tomato',
        spaceId: 's1',
        nickname: 'Tomato',
        setup: GrowSetup.outdoor,
        inContainer: false,
        startMethod: 'transplant',
        status: PlantingStatus.planned,
        createdAt: DateTime(2026, 4, 1),
      );
      expect(
        () => stageOf(unplanted, tomato, _day(5)),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('stage labels match the card copy', () {
    expect(PlantingStage.sprouting.label, 'Sprouting');
    expect(PlantingStage.growing.label, 'Growing');
    expect(PlantingStage.readyToHarvest.label, 'Ready to harvest');
    expect(PlantingStage.blooming.label, 'Blooming');
    expect(PlantingStage.established.label, 'Established');
  });
}
