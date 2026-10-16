import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/domain/climate_reveal_format.dart';

import '../recommendations/fixtures/baton_rouge.dart' as fx;

void main() {
  test('Baton Rouge lines match the plan/04 worked example', () {
    final p = fx.batonRougeClimate;
    expect(zoneLine(p), 'Zone 8b');
    expect(summerLine(p), 'Summer highs ~92°F');
    expect(winterLine(p), 'Winter lows ~43°F');
    expect(rainLine(p), '58 in of rain a year');
    expect(humidityLabel(p.annualRhPct), 'Humid');
    expect(frostLine(p.lastSpringFrostDoy, 30.45), 'Last spring frost ~Feb 20');
  });

  test('humidity boundaries', () {
    expect(humidityLabel(70), 'Humid');
    expect(humidityLabel(69.9), 'Moderate');
    expect(humidityLabel(50), 'Moderate');
    expect(humidityLabel(45.1), 'Moderate');
    expect(humidityLabel(45), 'Dry');
  });

  test('frost line: rare, dated, and hidden south of the equator', () {
    expect(frostLine(null, 30.45), 'Frost is rare here');
    expect(frostLine(51, 30.45), 'Last spring frost ~Feb 20');
    expect(frostLine(51, -33.9), isNull);
    expect(frostLine(null, -33.9), isNull);
  });
}
