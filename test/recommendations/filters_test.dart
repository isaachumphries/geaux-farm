import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/recommendation_filter.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';

import 'fixtures/baton_rouge.dart';

void main() {
  final plants = loadReferencePlants();
  // A shrub so the Shrubs chip has something to find.
  final boxwood = Plant.fromJson({
    ...rawKale(),
    'id': 'boxwood',
    'commonName': 'Boxwood',
    'scientificName': 'Buxus sempervirens',
    'category': 'shrub',
    'purposes': ['design'],
    'care': {'dailyMinutes': 0, 'weeklyMinutes': 20, 'tasks': <Object>[]},
  });
  final items = [
    for (final p in [...plants.values, boxwood])
      ScoredPlant(
        p,
        scorePlant(p, workedExample, GrowSetup.outdoor, workedExampleDate),
      ),
  ];

  List<String> run(RecommendationChip chip, [String query = '']) =>
      applyRecommendationFilter(
        items,
        chip,
        query,
      ).map((s) => s.plant.id).toList();

  final expected = {
    RecommendationChip.all: [
      'kale',
      'cherry-tomato',
      'sweet-basil',
      'english-lavender',
      'boxwood',
    ],
    RecommendationChip.food: ['kale', 'cherry-tomato', 'sweet-basil'],
    RecommendationChip.herbs: ['sweet-basil'],
    RecommendationChip.flowers: ['english-lavender'],
    RecommendationChip.shrubs: ['boxwood'],
    RecommendationChip.indoor: ['sweet-basil'],
    // Boxwood is 20 min/week (Medium); tomato is 30 (Medium).
    RecommendationChip.lowMaintenance: [
      'kale',
      'sweet-basil',
      'english-lavender',
    ],
  };
  expected.forEach((chip, ids) {
    test('chip ${chip.name}', () => expect(run(chip), ids));
  });

  test('chip and search combine with AND', () {
    expect(run(RecommendationChip.herbs, 'basil'), ['sweet-basil']);
    expect(run(RecommendationChip.flowers, 'basil'), isEmpty);
    expect(run(RecommendationChip.food, 'a'), [
      'kale',
      'cherry-tomato',
      'sweet-basil',
    ]);
  });

  test('search is case-insensitive', () {
    expect(run(RecommendationChip.all, 'BASIL'), ['sweet-basil']);
    expect(run(RecommendationChip.all, 'basil'), ['sweet-basil']);
  });

  test('search matches scientificName', () {
    expect(run(RecommendationChip.all, 'lavandula'), ['english-lavender']);
    expect(run(RecommendationChip.all, 'SOLANUM'), ['cherry-tomato']);
  });

  test('search matches commonName only hits', () {
    expect(run(RecommendationChip.all, 'cherry'), ['cherry-tomato']);
  });

  test('no match returns empty', () {
    expect(run(RecommendationChip.all, 'cactus'), isEmpty);
  });
}
