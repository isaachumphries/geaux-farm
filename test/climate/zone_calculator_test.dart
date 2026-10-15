import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/zone_calculator.dart';

void main() {
  final cases = <double, String>{
    19.66: '8b', // Baton Rouge: z = 79.66
    -65: '1a', // z = -5 < 0
    -60: '1a', // z = 0
    -55: '1b', // z = 5
    -50.1: '1b', // z = 9.9
    -50: '2a', // z = 10
    120: '13a', // z = 180, number clamped to 13
  };
  cases.forEach((min, zone) {
    test('$min °F → $zone', () => expect(computeZone(min), zone));
  });
}
