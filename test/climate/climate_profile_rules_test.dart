import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/climate_normals.dart';
import 'package:geaux_farm/features/climate/domain/frost_dates.dart';
import 'package:geaux_farm/features/climate/domain/zone_calculator.dart';

import 'baton_rouge_archive.dart';

/// Edges of the plan/04 § Climate profile rules not pinned elsewhere.
void main() {
  group('step 4 computed zone boundaries (z = min + 60)', () {
    final cases = <(double, String)>[
      (19.64, '8b'), // Baton Rouge fixture: z 79.64
      (-60.01, '1a'), // z just below 0
      (-55.01, '1a'), // z mod 10 = 4.99 → a
      (-45.01, '2a'), // z 14.99 → a, number 2
      (-45, '2b'), // z 15 → b
      (59.99, '12b'), // z 119.99 → number 12
      (60, '13a'), // z 120 → number 13
      (65, '13b'), // z 125 → b, still 13
      (70, '13a'), // z 130 → number 14 clamped to 13
    ];
    for (final (min, zone) in cases) {
      test('$min °F → $zone', () => expect(computeZone(min), zone));
    }
  });

  test('step 3 annualRhPct is the mean of every daily RH, not of months', () {
    // One day at 10 % in each month except July, which has 31 days at 90 %.
    // The mean of the monthly means would be (11 × 10 + 90) / 12 ≈ 16.7.
    final rows = [
      for (var m = 1; m <= 12; m++)
        for (var d = 1; d <= (m == 7 ? 31 : 1); d++)
          DailyClimateRow(
            date: DateTime(2021, m, d),
            minF: 40,
            maxF: 60,
            precipIn: 0,
            rhPct: m == 7 ? 90 : 10,
            cloudPct: 40,
            sunshineS: 3600,
          ),
    ];
    final annual = annualValues(rows, monthlyNormals(rows));
    expect(annual.rhPct, closeTo((11 * 10 + 31 * 90) / 42, 1e-9));
  });

  test('step 5 frost dates are computed at the equator (lat 0 ≥ 0)', () {
    final rows = archiveFixtureRows();
    final atZero = frostDates(rows, 0);
    expect(atZero.lastSpringFrostDoy, 51);
    expect(frostDates(rows, -0.01).lastSpringFrostDoy, isNull);
  });
}
