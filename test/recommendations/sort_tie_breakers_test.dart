// plan/04 § Sorting: inSeason desc, score desc, difficulty asc, commonName
// asc, with each key only breaking ties of the keys above it.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/sort_recommendations.dart';

import 'fixtures/scored.dart';

ScoredPlant item(
  String id,
  String name, {
  required bool inSeason,
  required int score,
  required int difficulty,
}) => scored(
  kaleWith({'id': id, 'commonName': name, 'difficulty': difficulty}),
  score: score,
  inSeason: inSeason,
);

void main() {
  test('name ties sort by commonName, not id', () {
    final items = [
      item('a-id', 'Zinnia', inSeason: true, score: 80, difficulty: 1),
      item('z-id', 'Aster', inSeason: true, score: 80, difficulty: 1),
    ];
    expect(sortRecommendations(items).map((s) => s.plant.commonName), [
      'Aster',
      'Zinnia',
    ]);
  });

  test('full precedence over a shuffled list', () {
    final items = [
      item('h', 'H', inSeason: false, score: 60, difficulty: 1),
      item('c', 'B', inSeason: true, score: 70, difficulty: 3),
      item('f', 'F', inSeason: false, score: 90, difficulty: 2),
      item('a', 'A', inSeason: true, score: 70, difficulty: 1),
      item('e', 'E', inSeason: false, score: 90, difficulty: 1),
      item('d', 'C', inSeason: true, score: 70, difficulty: 3),
      item('g', 'A', inSeason: false, score: 90, difficulty: 2),
      item('b', 'Z', inSeason: true, score: 95, difficulty: 3),
    ];
    expect(sortRecommendations(items).map((s) => s.plant.id), [
      'b', // in season, highest score despite difficulty 3
      'a', // in season, 70, easiest
      'c', // in season, 70, difficulty 3, "B"
      'd', // in season, 70, difficulty 3, "C"
      'e', // out of season, 90, easiest
      'g', // out of season, 90, difficulty 2, "A"
      'f', // out of season, 90, difficulty 2, "F"
      'h', // out of season, 60
    ]);
  });
}
