// plan/04 § Scoring (Climate 35), § Indoor and greenhouse model, and
// § Outdoor viability, pinned at their thresholds.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';

import 'fixtures/baton_rouge.dart';
import 'fixtures/scored.dart';
import 'fixtures/synthetic_climate.dart';

Compatibility score(Plant p, GrowSetup setup, {double? annualRhPct}) =>
    scorePlant(
      p,
      contextIn(climateWith(annualRhPct: annualRhPct)),
      setup,
      workedExampleDate,
    );

void main() {
  group('humidity multiplier ×0.8', () {
    final cases = <(Humidity, double), double>{
      (Humidity.low, 69.9): 1,
      (Humidity.low, 70): 0.8,
      (Humidity.low, 30): 1,
      (Humidity.high, 45): 1,
      (Humidity.high, 44.9): 0.8,
      (Humidity.high, 90): 1,
      (Humidity.any, 90): 1,
      (Humidity.any, 10): 1,
    };
    cases.forEach((input, expected) {
      test('${input.$1.name} at RH ${input.$2} → $expected', () {
        expect(humidityMultiplier(input.$1, input.$2), expected);
      });
    });

    test('outdoors it reads annualRhPct and scales the climate fit', () {
      // Kale is in season in Baton Rouge (climate 1 before the multiplier).
      final dryLover = kaleWith({'humidity': 'low'});
      expect(
        score(dryLover, GrowSetup.outdoor, annualRhPct: 70).fits['climate'],
        closeTo(0.8, 1e-9),
      );
      expect(
        score(dryLover, GrowSetup.outdoor, annualRhPct: 69.9).fits['climate'],
        1,
      );
      final wetLover = kaleWith({'humidity': 'high'});
      expect(
        score(wetLover, GrowSetup.outdoor, annualRhPct: 44.9).fits['climate'],
        closeTo(0.8, 1e-9),
      );
    });

    test('indoors and in a greenhouse RH is 40 whatever the outdoor RH', () {
      final wetLover = kaleWith({
        'humidity': 'high',
        'growTempF': {'min': 65, 'max': 75},
      });
      for (final setup in [GrowSetup.indoor, GrowSetup.greenhouse]) {
        expect(
          score(wetLover, setup, annualRhPct: 90).fits['climate'],
          closeTo(0.8, 1e-9),
          reason: setup.name,
        );
      }
    });
  });

  group('indoor/greenhouse climate: growTempF.min ≤ 65 && max ≥ 75', () {
    double indoorClimate(num min, num max, {String humidity = 'any'}) => score(
      kaleWith({
        'growTempF': {'min': min, 'max': max},
        'humidity': humidity,
      }),
      GrowSetup.indoor,
    ).fits['climate']!;

    test('65–75 exactly → 1', () {
      expect(indoorClimate(65, 75), 1);
    });
    test('min 65.1 → 0.5', () {
      expect(indoorClimate(65.1, 75), 0.5);
    });
    test('max 74.9 → 0.5', () {
      expect(indoorClimate(65, 74.9), 0.5);
    });
    test('only one bound covered → 0.5', () {
      expect(indoorClimate(66, 100), 0.5);
      expect(indoorClimate(0, 74), 0.5);
    });
    test('0.5 then ×0.8 for a high-humidity plant → 0.4', () {
      expect(indoorClimate(66, 100, humidity: 'high'), closeTo(0.4, 1e-9));
    });
    test('greenhouse uses the same temperature check', () {
      final p = kaleWith({
        'growTempF': {'min': 65.1, 'max': 75},
      });
      expect(score(p, GrowSetup.greenhouse).fits['climate'], 0.5);
    });
  });

  group('outdoorViable = outdoor climate fit ≥ 0.5', () {
    Plant perennial(String min, String max, {String humidity = 'any'}) =>
        kaleWith({
          'lifecycle': 'perennial',
          'zones': {'min': min, 'max': max},
          'humidity': humidity,
        });

    test('exactly 1.0 zone outside (fit 0.5) is viable', () {
      // User 8b = 8.5; 9b = 9.5.
      final c = score(perennial('9b', '11a'), GrowSetup.outdoor);
      expect(c.fits['climate'], 0.5);
      expect(c.outdoorViable, isTrue);
    });

    test('humidity multiplier counts: 0.5 × 0.8 = 0.4 is not viable', () {
      final c = score(
        perennial('9b', '11a', humidity: 'low'),
        GrowSetup.outdoor,
      );
      expect(c.fits['climate'], closeTo(0.4, 1e-9));
      expect(c.outdoorViable, isFalse);
    });

    test('viability reads the outdoor fit even for an indoor setup', () {
      final c = score(perennial('10a', '11a'), GrowSetup.indoor);
      expect(c.fits['climate'], 1);
      expect(c.outdoorViable, isFalse);
    });
  });
}
