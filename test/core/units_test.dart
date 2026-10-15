import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/units.dart';

void main() {
  group('fahrenheitToCelsiusDisplay', () {
    final cases = <double, num>{
      32.0: 0,
      212.0: 100,
      -40.0: -40,
      70.0: 21,
      75.0: 24,
    };
    cases.forEach((f, c) {
      test('$f °F → $c °C', () {
        expect(fahrenheitToCelsiusDisplay(f), c);
      });
    });
  });

  group('inchesToMillimetersDisplay', () {
    final cases = <double, num>{0.0: 0.0, 0.1: 2.5, 1.0: 25.4, 1.23: 31.2};
    cases.forEach((inches, mm) {
      test('$inches in → $mm mm', () {
        expect(inchesToMillimetersDisplay(inches), mm);
      });
    });
  });
}
