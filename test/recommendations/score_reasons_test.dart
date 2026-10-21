import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/score_reasons.dart';

import 'fixtures/baton_rouge.dart';
import 'fixtures/scored.dart';

List<ScoreRow> rowsFor(Plant plant, UserContext ctx, GrowSetup setup) =>
    scoreRows(
      plant: plant,
      ctx: ctx,
      setup: setup,
      compat: scorePlant(plant, ctx, setup, workedExampleDate),
    );

/// Worked-example outdoor rows for [plant] with the monthStrip replaced.
List<ScoreRow> rowsWithStrip(Plant plant, List<bool> strip) {
  final base = scorePlant(
    plant,
    workedExample,
    GrowSetup.outdoor,
    workedExampleDate,
  );
  return scoreRows(
    plant: plant,
    ctx: workedExample,
    setup: GrowSetup.outdoor,
    compat: Compatibility(
      score: base.score,
      level: base.level,
      fits: base.fits,
      inSeason: base.inSeason,
      outdoorViable: base.outdoorViable,
      monthStrip: strip,
    ),
  );
}

String reasonFor(List<ScoreRow> rows, ScoreFactor factor) =>
    rows.singleWhere((r) => r.factor == factor).reason;

void main() {
  final plants = loadReferencePlants();

  group('bars', () {
    test('lavender percents match the worked example', () {
      final rows = rowsFor(
        plants['english-lavender']!,
        workedExample,
        GrowSetup.outdoor,
      );
      expect(rows.map((r) => r.percent), [80, 50, 100, 100, 30, 50]);
    });

    test('basil earns every bar in full', () {
      final rows = rowsFor(
        plants['sweet-basil']!,
        workedExample,
        GrowSetup.outdoor,
      );
      expect(rows.map((r) => r.percent), everyElement(100));
    });

    test('rows follow ScoreFactor order with the six labels', () {
      final rows = rowsFor(plants['kale']!, workedExample, GrowSetup.outdoor);
      expect(rows.map((r) => r.factor), ScoreFactor.values);
      expect(ScoreFactor.values.map((f) => f.label), [
        'Climate',
        'Light',
        'Space',
        'Care time',
        'Your goals',
        'Experience',
      ]);
    });

    test('percent rounds the fit to a whole number', () {
      const row = ScoreRow(factor: ScoreFactor.light, fit: 0.125, reason: '');
      expect(row.percent, 13);
    });
  });

  group('climate', () {
    test('annual lists the months that are fully in season', () {
      final strip = List.filled(12, false)
        ..[3] = true
        ..[4] = true
        ..[5] = true;
      final rows = rowsWithStrip(plants['kale']!, strip);
      expect(
        reasonFor(rows, ScoreFactor.climate),
        'Grows well here: Apr, May, Jun',
      );
    });

    test('annual with no fully in-season months says so', () {
      final rows = rowsWithStrip(plants['kale']!, List.filled(12, false));
      expect(
        reasonFor(rows, ScoreFactor.climate),
        'No months fully in season here',
      );
    });

    test('perennial outdoor shows hardiness zones against the user zone', () {
      final plant = kaleWith({
        'lifecycle': 'perennial',
        'zones': {'min': '10a', 'max': '12b'},
      });
      final rows = rowsFor(plant, workedExample, GrowSetup.outdoor);
      expect(
        reasonFor(rows, ScoreFactor.climate),
        "Hardy in zones 10a–12b; you're in 8b",
      );
    });

    test('indoor temperature copy uses the 65–75 °F band', () {
      final suits = rowsFor(
        kaleWith({
          'growTempF': {'min': 65, 'max': 75},
        }),
        workedExample,
        GrowSetup.indoor,
      );
      expect(
        reasonFor(suits, ScoreFactor.climate),
        'Indoor temperatures suit it',
      );

      final lowMax = rowsFor(
        kaleWith({
          'growTempF': {'min': 65, 'max': 74},
        }),
        workedExample,
        GrowSetup.indoor,
      );
      expect(
        reasonFor(lowMax, ScoreFactor.climate),
        'Indoor temperatures partly suit it',
      );
    });

    test('low humidity adds a dislike note when outdoor air is humid', () {
      final rows = rowsFor(
        kaleWith({'humidity': 'low'}),
        workedExample,
        GrowSetup.outdoor,
      );
      expect(
        reasonFor(rows, ScoreFactor.climate),
        endsWith(' · dislikes humidity'),
      );
    });

    test('high humidity wants more humidity indoors at 40 % RH', () {
      final rows = rowsFor(
        kaleWith({'humidity': 'high'}),
        workedExample,
        GrowSetup.indoor,
      );
      expect(
        reasonFor(rows, ScoreFactor.climate),
        endsWith(' · wants more humidity'),
      );
    });

    test('no humidity note when the air already suits the plant', () {
      final rows = rowsFor(
        kaleWith({'humidity': 'high'}),
        workedExample,
        GrowSetup.outdoor,
      );
      expect(reasonFor(rows, ScoreFactor.climate), isNot(contains('humidity')));
    });
  });

  test('light names the plant needs and the spot', () {
    final rows = rowsFor(plants['kale']!, workedExample, GrowSetup.outdoor);
    expect(
      reasonFor(rows, ScoreFactor.light),
      'Needs partial sun or full sun; your spot gets partial sun',
    );
  });

  group('space', () {
    test('shows the plant footprint against the space area', () {
      final rows = rowsFor(plants['kale']!, workedExample, GrowSetup.outdoor);
      expect(
        reasonFor(rows, ScoreFactor.space),
        'Needs ~2 sq ft; you have 32 sq ft',
      );
    });

    test('keeps one decimal for fractional footprints', () {
      final rows = rowsFor(
        kaleWith({
          'space': {
            'sqFtPerPlant': 2.5,
            'containerOk': true,
            'minContainerGal': 3,
            'indoorOk': false,
          },
        }),
        workedExample,
        GrowSetup.outdoor,
      );
      expect(
        reasonFor(rows, ScoreFactor.space),
        'Needs ~2.5 sq ft; you have 32 sq ft',
      );
    });

    test('container spaces reject plants that are not container-ok', () {
      final rows = rowsFor(
        kaleWith({
          'space': {
            'sqFtPerPlant': 2,
            'containerOk': false,
            'minContainerGal': 3,
            'indoorOk': true,
          },
        }),
        workedExample,
        GrowSetup.outdoor,
      );
      expect(reasonFor(rows, ScoreFactor.space), 'Not suited to containers');
    });

    test('indoor setup ignores the container rule', () {
      final rows = rowsFor(
        kaleWith({
          'space': {
            'sqFtPerPlant': 2,
            'containerOk': false,
            'minContainerGal': 3,
            'indoorOk': true,
          },
        }),
        workedExample,
        GrowSetup.indoor,
      );
      expect(
        reasonFor(rows, ScoreFactor.space),
        'Needs ~2 sq ft; you have 32 sq ft',
      );
    });

    test('indoor setup rejects plants that are not indoor-ok', () {
      final rows = rowsFor(plants['kale']!, workedExample, GrowSetup.indoor);
      expect(reasonFor(rows, ScoreFactor.space), 'Not an indoor plant');
    });
  });

  group('care time', () {
    test('outdoor uses the outdoor watering interval', () {
      final rows = rowsFor(plants['kale']!, workedExample, GrowSetup.outdoor);
      expect(
        reasonFor(rows, ScoreFactor.care),
        'Water every ~3 days; you have 4 care days',
      );
    });

    test('indoor uses the indoor watering interval', () {
      final rows = rowsFor(
        kaleWith({
          'water': {
            'need': 'medium',
            'everyDaysOutdoor': 3,
            'everyDaysIndoor': 5,
          },
        }),
        workedExample,
        GrowSetup.indoor,
      );
      expect(
        reasonFor(rows, ScoreFactor.care),
        'Water every ~5 days; you have 4 care days',
      );
    });
  });

  group('goals', () {
    test('names the matched purpose', () {
      final rows = rowsFor(plants['kale']!, workedExample, GrowSetup.outdoor);
      expect(reasonFor(rows, ScoreFactor.goals), 'Matches: food');
    });

    test('says so when no purpose matches a goal', () {
      final rows = rowsFor(
        kaleWith({
          'purposes': ['design'],
        }),
        workedExample,
        GrowSetup.outdoor,
      );
      expect(reasonFor(rows, ScoreFactor.goals), 'Not one of your goals');
    });

    test('says so when the user picked no food or design goals', () {
      final ctx = UserContext(
        profile: profileWith(goals: const []),
        space: workedExample.space,
        climate: workedExample.climate,
      );
      final rows = rowsFor(plants['kale']!, ctx, GrowSetup.outdoor);
      expect(reasonFor(rows, ScoreFactor.goals), 'No specific goals to match');
    });
  });

  group('experience', () {
    test('maps difficulty 1 to Easy', () {
      final rows = rowsFor(plants['kale']!, workedExample, GrowSetup.outdoor);
      expect(reasonFor(rows, ScoreFactor.experience), 'Difficulty: Easy');
    });

    test('maps difficulty 2 to Moderate', () {
      final rows = rowsFor(
        kaleWith({'difficulty': 2}),
        workedExample,
        GrowSetup.outdoor,
      );
      expect(reasonFor(rows, ScoreFactor.experience), 'Difficulty: Moderate');
    });

    test('maps difficulty 3 to Challenging', () {
      final rows = rowsFor(
        kaleWith({'difficulty': 3}),
        workedExample,
        GrowSetup.outdoor,
      );
      expect(
        reasonFor(rows, ScoreFactor.experience),
        'Difficulty: Challenging',
      );
    });
  });
}
