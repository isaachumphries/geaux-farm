import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/units.dart';

/// plan/06 § Units: °C = (°F − 32) × 5/9 shown as an integer; mm = in ×
/// 25.4 shown to 1 decimal. These cases sit on the rounding edges, where
/// floor, ceil or truncation would show a different number.
void main() {
  group('°C rounds to the nearest integer', () {
    final cases = <(double, int)>[
      (33.0, 1), // 0.56 rounds up
      (32.5, 0), // 0.28 rounds down
      (31.0, -1), // -0.56 rounds away from zero
      (31.5, 0), // -0.28 rounds toward zero
      (0.0, -18), // -17.78
      (100.0, 38), // 37.78
    ];
    for (final (f, c) in cases) {
      test('$f °F → $c °C', () => expect(fahrenheitToCelsiusDisplay(f), c));
    }
  });

  group('mm rounds to the nearest 0.1', () {
    final cases = <(double, double)>[
      (0.07, 1.8), // 1.778 rounds up
      (0.3, 7.6), // 7.62 rounds down
      (0.002, 0.1), // 0.0508 rounds up
      (0.0019, 0.0), // 0.04826 rounds down
      (2.0, 50.8),
    ];
    for (final (inches, mm) in cases) {
      test(
        '$inches in → $mm mm',
        () => expect(inchesToMillimetersDisplay(inches), mm),
      );
    }
  });
}
