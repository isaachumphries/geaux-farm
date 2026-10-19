import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/domain/frost_copy.dart';

void main() {
  group('fallFrostLine', () {
    test('null fall frost reads as rare', () {
      expect(fallFrostLine(null, 30.45), 'Fall frost is rare');
    });

    test('day 334 is Nov 30', () {
      expect(fallFrostLine(334, 30.45), 'First fall frost ~Nov 30');
    });

    test('southern hemisphere hides the line', () {
      expect(fallFrostLine(334, -27.5), isNull);
      expect(fallFrostLine(null, -27.5), isNull);
    });

    test('equator counts as northern', () {
      expect(fallFrostLine(null, 0), 'Fall frost is rare');
    });
  });
}
