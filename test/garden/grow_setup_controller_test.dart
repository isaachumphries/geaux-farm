import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/application/grow_setup_controller.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/compat_level.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';

import '../recommendations/fixtures/scored.dart';
import 'garden_harness.dart';

final _today = DateTime(2026, 10, 7);

Compatibility _compat(int score, {bool outdoorViable = true}) => Compatibility(
  score: score,
  level: compatLevelFor(score),
  fits: const {},
  inSeason: true,
  outdoorViable: outdoorViable,
  monthStrip: List.filled(12, true),
);

/// Records each (plant, setup) it scores and answers from [scores].
class _FakeScorer {
  _FakeScorer(this.scores);

  final Map<GrowSetup, Compatibility> scores;
  final calls = <(String, GrowSetup)>[];
  final _gates = <GrowSetup, Completer<void>>{};

  /// Holds the score for [setup] until [release] is called.
  void hold(GrowSetup setup) => _gates[setup] = Completer<void>();
  void release(GrowSetup setup) => _gates.remove(setup)!.complete();

  Future<Compatibility> call(Plant plant, GrowSetup setup) async {
    calls.add((plant.id, setup));
    await _gates[setup]?.future;
    return scores[setup]!;
  }
}

/// A container over an in-memory database holding one [space], and the
/// controller for [plant] once the space has loaded.
Future<(ProviderContainer, _FakeScorer)> _setUp({
  SpaceType space = SpaceType.balcony,
  bool inContainerDefault = true,
  ScoredPlant? plant,
  Map<GrowSetup, Compatibility>? scores,
}) async {
  final db = openGardenDb();
  await seedSpace(db, type: space, inContainerDefault: inContainerDefault);
  final scorer = _FakeScorer(
    scores ??
        {
          GrowSetup.outdoor: _compat(82),
          GrowSetup.indoor: _compat(55),
          GrowSetup.greenhouse: _compat(91),
        },
  );
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 9)),
      growScorerProvider.overrideWithValue(scorer.call),
    ],
  );
  addTearDown(container.dispose);
  final p = plant ?? scored(kaleWith({}), score: 82);
  final provider = growSetupControllerProvider(p);
  container.listen(provider, (_, _) {});
  while (container.read(provider) == null) {
    await Future<void>.delayed(Duration.zero);
  }
  return (container, scorer);
}

GrowSetupState _state(ProviderContainer c, ScoredPlant p) =>
    c.read(growSetupControllerProvider(p))!;

GrowSetupController _controller(ProviderContainer c, ScoredPlant p) =>
    c.read(growSetupControllerProvider(p).notifier);

void main() {
  group('defaults', () {
    test('a windowsill starts Indoors, in a container', () async {
      final plant = scored(kaleWith({}));
      final (c, _) = await _setUp(space: SpaceType.windowsill, plant: plant);
      expect(_state(c, plant).setup, GrowSetup.indoor);
      expect(_state(c, plant).inContainer, isTrue);
    });

    test('a balcony starts Outdoors, in a container', () async {
      final plant = scored(kaleWith({}));
      final (c, _) = await _setUp(space: SpaceType.balcony, plant: plant);
      expect(_state(c, plant).setup, GrowSetup.outdoor);
      expect(_state(c, plant).inContainer, isTrue);
    });

    test('a yard starts Outdoors, in the ground', () async {
      final plant = scored(kaleWith({}));
      final (c, _) = await _setUp(
        space: SpaceType.smallYard,
        inContainerDefault: false,
        plant: plant,
      );
      expect(_state(c, plant).setup, GrowSetup.outdoor);
      expect(_state(c, plant).inContainer, isFalse);
    });

    test(
      'the first start method, today, no nickname, the list score',
      () async {
        final plant = scored(kaleWith({}), score: 82);
        final (c, _) = await _setUp(plant: plant);
        final s = _state(c, plant);
        expect(s.startMethod, StartMethod.transplant);
        expect(s.plantedOn, _today);
        expect(s.nickname, '');
        expect(s.compat.score, 82);
        expect(s.spaceId, 's1');
      },
    );

    test('a plant that cannot be potted starts in the ground', () async {
      final plant = scored(
        kaleWith({
          'space': {'sqFtPerPlant': 2, 'containerOk': false, 'indoorOk': false},
        }),
      );
      final (c, _) = await _setUp(space: SpaceType.windowsill, plant: plant);
      expect(_state(c, plant).inContainer, isFalse);
    });
  });

  group('setup re-scores', () {
    test('each change runs scorePlant for the new setup', () async {
      final plant = scored(kaleWith({}), score: 82);
      final (c, scorer) = await _setUp(plant: plant);

      await _controller(c, plant).setSetup(GrowSetup.indoor);
      expect(_state(c, plant).compat.score, 55);
      await _controller(c, plant).setSetup(GrowSetup.greenhouse);
      expect(_state(c, plant).compat.score, 91);

      expect(scorer.calls, [
        ('kale', GrowSetup.indoor),
        ('kale', GrowSetup.greenhouse),
      ]);
    });

    test('picking the current setup does not re-score', () async {
      final plant = scored(kaleWith({}));
      final (c, scorer) = await _setUp(plant: plant);
      await _controller(c, plant).setSetup(GrowSetup.outdoor);
      expect(scorer.calls, isEmpty);
    });

    test(
      'a slow score for an older setup does not overwrite a newer one',
      () async {
        final plant = scored(kaleWith({}), score: 82);
        final (c, scorer) = await _setUp(plant: plant);
        scorer.hold(GrowSetup.indoor);

        final slow = _controller(c, plant).setSetup(GrowSetup.indoor);
        await _controller(c, plant).setSetup(GrowSetup.greenhouse);
        scorer.release(GrowSetup.indoor);
        await slow;

        expect(_state(c, plant).setup, GrowSetup.greenhouse);
        expect(_state(c, plant).compat.score, 91);
      },
    );
  });

  group('outdoor warning', () {
    test('Outdoors for a plant that is not outdoor-viable', () async {
      final plant = scored(kaleWith({}), outdoorViable: false);
      final (c, _) = await _setUp(
        plant: plant,
        scores: {
          GrowSetup.outdoor: _compat(30, outdoorViable: false),
          GrowSetup.indoor: _compat(70, outdoorViable: false),
          GrowSetup.greenhouse: _compat(75, outdoorViable: false),
        },
      );
      expect(_state(c, plant).outdoorWarning, isTrue);

      await _controller(c, plant).setSetup(GrowSetup.indoor);
      expect(_state(c, plant).outdoorWarning, isFalse);
      await _controller(c, plant).setSetup(GrowSetup.greenhouse);
      expect(_state(c, plant).outdoorWarning, isFalse);
    });

    test('never for an outdoor-viable plant', () async {
      final plant = scored(kaleWith({}));
      final (c, _) = await _setUp(plant: plant);
      expect(_state(c, plant).outdoorWarning, isFalse);
    });
  });

  group('planted date', () {
    test('today−365 through today, nothing outside', () {
      expect(plantedOnAllowed(DateTime(2025, 10, 7), _today), isTrue);
      expect(plantedOnAllowed(_today, _today), isTrue);
      expect(
        plantedOnAllowed(DateTime(2025, 10, 6), _today),
        isFalse,
        reason: 'today−366',
      );
      expect(plantedOnAllowed(DateTime(2026, 10, 8), _today), isFalse);
      expect(earliestPlantedOn(_today), DateTime(2025, 10, 7));
    });

    test('a leap year keeps the range at 365 days', () {
      final today = DateTime(2028, 3, 1);
      expect(earliestPlantedOn(today), DateTime(2027, 3, 2));
      expect(plantedOnAllowed(DateTime(2027, 3, 1), today), isFalse);
    });

    test('the controller ignores dates outside the range', () async {
      final plant = scored(kaleWith({}));
      final (c, _) = await _setUp(plant: plant);
      final controller = _controller(c, plant);

      controller.setPlantedOn(DateTime(2025, 10, 6));
      expect(_state(c, plant).plantedOn, _today);
      controller.setPlantedOn(DateTime(2026, 10, 8));
      expect(_state(c, plant).plantedOn, _today);
      controller.setPlantedOn(DateTime(2025, 10, 7, 15));
      expect(_state(c, plant).plantedOn, DateTime(2025, 10, 7));
    });
  });

  test('container, start method, and nickname are recorded', () async {
    final plant = scored(kaleWith({}));
    final (c, _) = await _setUp(plant: plant);
    _controller(c, plant)
      ..setInContainer(false)
      ..setStartMethod(StartMethod.seed)
      ..setNickname('Big Kale');
    final s = _state(c, plant);
    expect(s.inContainer, isFalse);
    expect(s.startMethod, StartMethod.seed);
    expect(s.nickname, 'Big Kale');
  });
}
