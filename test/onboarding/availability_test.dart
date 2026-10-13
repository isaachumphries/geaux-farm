import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';

void main() {
  const a = Availability([64, 0, 64, 0, 0, 2, 2]);

  test('careDays counts non-zero weekdays', () {
    expect(a.careDays, 4);
  });

  test('hoursPerWeek is set bits × 2', () {
    expect(a.hoursPerWeek, 8);
    expect(const Availability([255, 0, 0, 0, 0, 0, 1]).hoursPerWeek, 18);
  });

  group('isFree', () {
    final cases = <(int, int, bool)>[
      (1, 6, true),
      (3, 6, true),
      (6, 1, true),
      (7, 1, true),
      (1, 0, false),
      (2, 6, false),
      (6, 0, false),
    ];
    for (final (day, block, expected) in cases) {
      test('weekday $day block $block → $expected', () {
        expect(a.isFree(day, block), expected);
      });
    }
  });
}
