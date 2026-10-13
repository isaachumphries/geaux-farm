import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';

void main() {
  test('meanF is the average of avgLowF and avgHighF', () {
    const m = ClimateMonth(
      month: 10,
      avgLowF: 62.6,
      avgHighF: 81.1,
      precipIn: 2.12,
      rhPct: 69,
      cloudPct: 0,
      sunshineHours: 0,
    );
    expect(m.meanF, closeTo(71.85, 1e-9));
  });
}
