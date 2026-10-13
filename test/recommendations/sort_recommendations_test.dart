import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/compat_level.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/sort_recommendations.dart';

import 'fixtures/baton_rouge.dart';

/// Kale reshaped with a new id, name and difficulty.
Plant variant(String id, String name, int difficulty) => Plant.fromJson({
  ...rawKale(),
  'id': id,
  'commonName': name,
  'difficulty': difficulty,
});

ScoredPlant scored(Plant p, {required int score, required bool inSeason}) =>
    ScoredPlant(
      p,
      Compatibility(
        score: score,
        level: compatLevelFor(score),
        fits: const {},
        inSeason: inSeason,
        outdoorViable: true,
        monthStrip: List.filled(12, inSeason),
      ),
    );

List<String> ids(List<ScoredPlant> items) =>
    items.map((s) => s.plant.id).toList();

void main() {
  final plants = loadReferencePlants();

  test('worked example sorts kale, lavender, basil, tomato', () {
    final items = [
      for (final p in plants.values)
        ScoredPlant(
          p,
          scorePlant(p, workedExample, GrowSetup.outdoor, workedExampleDate),
        ),
    ];
    const expected = [
      'kale',
      'english-lavender',
      'sweet-basil',
      'cherry-tomato',
    ];
    expect(ids(sortRecommendations(items)), expected);
    expect(ids(sortRecommendations(items.reversed.toList())), expected);
  });

  test('inSeason outranks a higher score', () {
    final a = scored(variant('a', 'A', 1), score: 40, inSeason: true);
    final b = scored(variant('b', 'B', 1), score: 100, inSeason: false);
    expect(ids(sortRecommendations([b, a])), ['a', 'b']);
  });

  test('score breaks inSeason ties, high first', () {
    final a = scored(variant('a', 'Zed', 3), score: 90, inSeason: true);
    final b = scored(variant('b', 'Abe', 1), score: 89, inSeason: true);
    expect(ids(sortRecommendations([b, a])), ['a', 'b']);
  });

  test('difficulty breaks score ties, easy first', () {
    final a = scored(variant('a', 'Zed', 1), score: 80, inSeason: false);
    final b = scored(variant('b', 'Abe', 2), score: 80, inSeason: false);
    expect(ids(sortRecommendations([b, a])), ['a', 'b']);
  });

  test('commonName breaks difficulty ties, A to Z', () {
    final a = scored(variant('a', 'Abe', 2), score: 80, inSeason: false);
    final b = scored(variant('b', 'Zed', 2), score: 80, inSeason: false);
    expect(ids(sortRecommendations([b, a])), ['a', 'b']);
  });

  test('non-scorable plants are excluded', () {
    final unscorable = Plant.fromJson({...rawKale(), 'id': 'x', 'water': null});
    expect(unscorable.scorable, isFalse);
    final items = [
      scored(unscorable, score: 100, inSeason: true),
      scored(variant('a', 'A', 1), score: 50, inSeason: false),
    ];
    expect(ids(sortRecommendations(items)), ['a']);
  });
}
