import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/in_season.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';

import 'fixtures/baton_rouge.dart';

/// Weighted points per fit: climate|light|space|care|goals|experience.
List<double> points(Compatibility c) => [
  35 * c.fits['climate']!,
  20 * c.fits['light']!,
  15 * c.fits['space']!,
  15 * c.fits['care']!,
  10 * c.fits['goals']!,
  5 * c.fits['experience']!,
];

void main() {
  final plants = loadReferencePlants();
  Compatibility score(String id, {UserContext? ctx}) => scorePlant(
    plants[id]!,
    ctx ?? workedExample,
    GrowSetup.outdoor,
    workedExampleDate,
  );

  group('worked example (plan/04 expected results)', () {
    final expected = {
      'kale': (
        [35.0, 20.0, 15.0, 15.0, 10.0, 5.0],
        100,
        CompatLevel.great,
        true,
      ),
      'english-lavender': (
        [28.0, 10.0, 15.0, 15.0, 3.0, 2.5],
        74,
        CompatLevel.good,
        true,
      ),
      'sweet-basil': (
        [35.0, 20.0, 15.0, 15.0, 10.0, 5.0],
        100,
        CompatLevel.great,
        false,
      ),
      'cherry-tomato': (
        [35.0, 10.0, 15.0, 15.0, 10.0, 2.5],
        88,
        CompatLevel.great,
        false,
      ),
    };
    expected.forEach((id, e) {
      test(id, () {
        final c = score(id);
        expect(points(c), [for (final v in e.$1) closeTo(v, 1e-9)]);
        expect(c.score, e.$2);
        expect(c.level, e.$3);
        expect(c.inSeason, e.$4);
        expect(c.outdoorViable, isTrue);
      });
    });
  });

  test('lavender rounds 73.5 up to 74', () {
    final sum = points(score('english-lavender')).reduce((a, b) => a + b);
    expect(sum, closeTo(73.5, 1e-9));
    expect(score('english-lavender').score, 74);
  });

  test('monthStrip has 12 entries matching inSeason for each month', () {
    for (final id in plants.keys) {
      final strip = score(id).monthStrip;
      expect(strip, hasLength(12));
      for (var m = 1; m <= 12; m++) {
        expect(strip[m - 1], inSeason(plants[id]!, batonRougeMonths, m));
      }
    }
    expect(score('kale').monthStrip[9], isTrue);
    expect(score('sweet-basil').monthStrip[3], isTrue);
  });

  test('reverse list order gives identical results', () {
    final forward = {for (final id in plants.keys) id: score(id)};
    for (final id in plants.keys.toList().reversed) {
      final c = score(id);
      expect(c.score, forward[id]!.score);
      expect(c.inSeason, forward[id]!.inSeason);
      expect(c.fits, forward[id]!.fits);
    }
  });

  test('default user 18 sq ft balcony scores like 32 sq ft', () {
    for (final id in plants.keys) {
      expect(plants[id]!.space!.sqFtPerPlant, lessThanOrEqualTo(18));
      final c = score(id, ctx: defaultUser);
      expect(c.fits['space'], 1.0, reason: id);
      expect(c.score, score(id).score, reason: id);
      expect(c.inSeason, score(id).inSeason, reason: id);
    }
  });

  group('indoor and greenhouse setups', () {
    Compatibility setup(String id, GrowSetup s) =>
        scorePlant(plants[id]!, workedExample, s, workedExampleDate);

    test('indoor RH 40 skips the dry-air penalty for lavender', () {
      // Outdoors RH 75 ≥ 70 costs low-humidity lavender ×0.8; indoors does not.
      expect(setup('english-lavender', GrowSetup.indoor).fits['climate'], 1.0);
      expect(
        setup('english-lavender', GrowSetup.greenhouse).fits['climate'],
        1.0,
      );
    });

    test('indoor ignores zones and uses the fixed indoor months', () {
      final c = setup('sweet-basil', GrowSetup.indoor);
      expect(c.inSeason, isTrue);
      expect(c.monthStrip, everyElement(isTrue));
      expect(c.outdoorViable, isTrue);
    });

    test('light: balcony indoor = partial, greenhouse = full', () {
      expect(setup('cherry-tomato', GrowSetup.indoor).fits['light'], 0.5);
      expect(setup('cherry-tomato', GrowSetup.greenhouse).fits['light'], 1.0);
    });

    test('space: indoor needs indoorOk', () {
      expect(setup('cherry-tomato', GrowSetup.indoor).fits['space'], 0.0);
      expect(setup('sweet-basil', GrowSetup.indoor).fits['space'], 1.0);
    });

    test('care uses everyDaysIndoor off the outdoor setup', () {
      // Lavender: outdoor every 7 days, indoor every 10 → both need 1 day.
      // Basil: outdoor every 2 → 4 days; indoor every 3 → 3 days.
      expect(setup('sweet-basil', GrowSetup.indoor).fits['care'], 1.0);
      final oneDay = UserContext(
        profile: profileWith(
          availability: const Availability([64, 0, 0, 0, 0, 0, 0]),
        ),
        space: workedExample.space,
        climate: batonRougeClimate,
      );
      expect(
        scorePlant(
          plants['sweet-basil']!,
          oneDay,
          GrowSetup.outdoor,
          workedExampleDate,
        ).fits['care'],
        closeTo(1 / 4, 1e-9),
      );
      expect(
        scorePlant(
          plants['sweet-basil']!,
          oneDay,
          GrowSetup.indoor,
          workedExampleDate,
        ).fits['care'],
        closeTo(1 / 3, 1e-9),
      );
    });
  });

  test('annual never in season: best share of window months', () {
    // Never plantable (no meanF in 95–99). growTempF max 70 passes only
    // Dec, Jan, Feb (highs 66.3, 60.6, 65.9): best 3 of n = 5 → 0.6.
    final json = Map<String, dynamic>.of(rawKale())
      ..['plantTempF'] = {'min': 95, 'max': 99}
      ..['growTempF'] = {'min': 20, 'max': 70};
    final c = scorePlant(
      Plant.fromJson(json),
      workedExample,
      GrowSetup.outdoor,
      workedExampleDate,
    );
    expect(c.fits['climate'], closeTo(0.6, 1e-9));
    expect(c.outdoorViable, isTrue);
    expect(c.monthStrip, everyElement(isFalse));
  });
}
