import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/recommendations/domain/in_season.dart';
import 'package:geaux_farm/features/recommendations/domain/indoor_climate.dart';

import 'fixtures/baton_rouge.dart';

void main() {
  final plants = loadReferencePlants();
  bool br(String id, int month) =>
      inSeason(plants[id]!, batonRougeMonths, month);

  test('October: kale and lavender yes, basil and tomato no', () {
    expect(br('kale', 10), isTrue);
    expect(br('english-lavender', 10), isTrue);
    // December avg low 49.7 < growTempF.min 50 inside their windows.
    expect(br('sweet-basil', 10), isFalse);
    expect(br('cherry-tomato', 10), isFalse);
  });

  test('cherry-tomato is in season in March and August', () {
    expect(br('cherry-tomato', 3), isTrue);
    expect(br('cherry-tomato', 8), isTrue);
  });

  test('sweet-basil is in season in April', () {
    expect(br('sweet-basil', 4), isTrue);
  });

  test('plantable bound: basil in March (meanF 63.30 < 65) is out', () {
    expect(br('sweet-basil', 3), isFalse);
  });

  test('window wraps past December: kale in November', () {
    // n = ceil((65 + 60) / 30) = 5 → Nov, Dec, Jan, Feb, Mar all pass.
    expect(br('kale', 11), isTrue);
  });

  test('indoor climate puts basil in season every month', () {
    for (var m = 1; m <= 12; m++) {
      expect(inSeason(plants['sweet-basil']!, indoorClimateMonths, m), isTrue);
    }
  });
}
