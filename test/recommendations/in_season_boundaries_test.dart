// plan/04 § In-season rule and § Scoring (Climate, outdoor annual), pinned
// at exact boundaries on synthetic climates. Default month: low 50, high 70,
// meanF 60.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/in_season.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';

import 'fixtures/baton_rouge.dart';
import 'fixtures/scored.dart';
import 'fixtures/synthetic_climate.dart';

Compatibility outdoor(Plant p, List<ClimateMonth> months) => scorePlant(
  p,
  contextIn(climateWith(months: months)),
  GrowSetup.outdoor,
  workedExampleDate,
);

void main() {
  final flat = monthsOf();

  group('plantable: plantTempF.min ≤ meanF ≤ plantTempF.max', () {
    Plant plant(num min, num max) =>
        windowPlant(plantMin: min, plantMax: max, growMin: 0, growMax: 100);

    test('meanF equal to both bounds is plantable', () {
      expect(inSeason(plant(60, 60), flat, 5), isTrue);
    });
    test('meanF just below min is not', () {
      expect(inSeason(plant(60.1, 80), flat, 5), isFalse);
    });
    test('meanF just above max is not', () {
      expect(inSeason(plant(40, 59.9), flat, 5), isFalse);
    });
  });

  group('window month: avgLowF ≥ growTempF.min and avgHighF ≤ max', () {
    Plant plant(num min, num max) =>
        windowPlant(plantMin: 0, plantMax: 100, growMin: min, growMax: max);

    test('low and high equal to the bounds pass', () {
      expect(inSeason(plant(50, 70), flat, 5), isTrue);
    });
    test('low just below growTempF.min fails', () {
      expect(inSeason(plant(50.1, 70), flat, 5), isFalse);
    });
    test('high just above growTempF.max fails', () {
      expect(inSeason(plant(50, 69.9), flat, 5), isFalse);
    });
    test('the planting month itself is checked (k = 0)', () {
      final coldApril = monthsOf(overrides: {4: (40, 70)});
      expect(inSeason(plant(50, 70), coldApril, 4), isFalse);
      expect(inSeason(plant(50, 70), coldApril, 5), isTrue);
    });
  });

  group('n = min(12, ceil((starts[0].daysMax + productiveDays) / 30))', () {
    // Only April is too hot for growTempF.max 75; plant in January.
    final hotApril = monthsOf(overrides: {4: (50, 80)});
    bool janWith(Map<String, dynamic> changes) => inSeason(
      kaleWith({
        'plantTempF': {'min': 0, 'max': 100},
        'growTempF': {'min': 0, 'max': 75},
        'productiveDays': 0,
        ...changes,
      }),
      hotApril,
      1,
    );
    Map<String, dynamic> start(int daysMin, int daysMax) => {
      'method': 'transplant',
      'daysMin': daysMin,
      'daysMax': daysMax,
    };

    test('90 days → 3 months (Jan–Mar) passes', () {
      expect(
        janWith({
          'starts': [start(90, 90)],
        }),
        isTrue,
      );
    });
    test('91 days rounds up to 4 months and reaches April', () {
      expect(
        janWith({
          'starts': [start(91, 91)],
        }),
        isFalse,
      );
    });
    test('uses daysMax, not daysMin', () {
      expect(
        janWith({
          'starts': [start(30, 91)],
        }),
        isFalse,
      );
    });
    test('uses starts[0], not a later start', () {
      expect(
        janWith({
          'starts': [start(90, 90), start(120, 120)],
        }),
        isTrue,
      );
    });
    test('adds productiveDays', () {
      expect(
        janWith({
          'starts': [start(60, 60)],
          'productiveDays': 31,
        }),
        isFalse,
      );
    });
  });

  group('window wraps December → January', () {
    final hotJanuary = monthsOf(overrides: {1: (50, 80)});
    Plant plant(int days) => windowPlant(
      plantMin: 0,
      plantMax: 100,
      growMin: 0,
      growMax: 75,
      windowDays: days,
    );

    test('December alone passes', () {
      expect(inSeason(plant(30), hotJanuary, 12), isTrue);
    });
    test('December with a 2-month window reads January and fails', () {
      expect(inSeason(plant(60), hotJanuary, 12), isFalse);
    });
    test('November with a 3-month window reads January and fails', () {
      expect(inSeason(plant(90), hotJanuary, 11), isFalse);
      expect(inSeason(plant(60), hotJanuary, 11), isTrue);
    });
  });

  group('outdoor annual climate fit', () {
    test('plantable only in December → fit 1, strip shows only Dec', () {
      // December meanF 70; every other month 60.
      final months = monthsOf(overrides: {12: (60, 80)});
      final p = windowPlant(
        plantMin: 65,
        plantMax: 75,
        growMin: 0,
        growMax: 100,
      );
      final c = outdoor(p, months);
      expect(c.fits['climate'], 1);
      expect(c.monthStrip, [...List.filled(11, false), true]);
    });

    test('best window may start in December and wrap', () {
      // Never plantable. Only Dec, Jan, Feb pass growTempF.max 75, so the
      // only 3-of-3 window is Dec–Feb.
      final months = monthsOf(
        overrides: {for (var m = 3; m <= 11; m++) m: (50, 80)},
      );
      final p = windowPlant(
        plantMin: 200,
        plantMax: 201,
        growMin: 0,
        growMax: 75,
        windowDays: 90,
      );
      expect(outdoor(p, months).fits['climate'], 1);
    });

    test('window is capped at 12 months', () {
      // 400 days → n = 12. Only July fails: best 11 of 12 (13 would give
      // 12 of 13).
      final months = monthsOf(overrides: {7: (50, 80)});
      final p = windowPlant(
        plantMin: 200,
        plantMax: 201,
        growMin: 0,
        growMax: 75,
        windowDays: 400,
      );
      expect(seasonWindowMonths(p), 12);
      expect(outdoor(p, months).fits['climate'], closeTo(11 / 12, 1e-9));
    });
  });
}
