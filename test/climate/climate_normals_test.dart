import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/climate_normals.dart';

import 'baton_rouge_archive.dart';

/// One full row per day of [year] with neutral values, so every month has
/// data; [edit] overrides chosen days.
List<DailyClimateRow> _year(
  int year, {
  DailyClimateRow? Function(DateTime day)? edit,
}) {
  final rows = <DailyClimateRow>[];
  for (
    var d = DateTime.utc(year);
    d.year == year;
    d = d.add(const Duration(days: 1))
  ) {
    rows.add(
      edit?.call(d) ??
          DailyClimateRow(
            date: d,
            minF: 50,
            maxF: 70,
            precipIn: 0,
            rhPct: 70,
            cloudPct: 40,
            sunshineS: 36000,
          ),
    );
  }
  return rows;
}

DailyClimateRow _row(
  DateTime d, {
  double? minF = 50,
  double? maxF = 70,
  double? precipIn = 0,
}) => DailyClimateRow(
  date: d,
  minF: minF,
  maxF: maxF,
  precipIn: precipIn,
  rhPct: 70,
  cloudPct: 40,
  sunshineS: 36000,
);

void main() {
  test('null daily values are skipped per field', () {
    // January has only three days: mins 30, null, 40.
    final rows = _year(
      2021,
      edit: (d) {
        if (d.month != 1) return null;
        if (d.day > 3) return null;
        return _row(d, minF: [30.0, null, 40.0][d.day - 1]);
      },
    ).where((r) => r.date.month != 1 || r.date.day <= 3).toList();

    final jan = monthlyNormals(rows).first;
    expect(jan.avgLowF, 35.0);
  });

  test('precipIn is the month total across years divided by the years', () {
    // Five Januaries whose totals add up to 25.0 in.
    final rows = [
      for (var y = 2021; y <= 2025; y++)
        ..._year(
          y,
          edit: (d) => d.month == 1 && d.day == 1
              ? _row(d, precipIn: [3.0, 7.0, 5.0, 4.0, 6.0][y - 2021])
              : null,
        ),
    ];
    expect(monthlyNormals(rows).first.precipIn, closeTo(5.0, 1e-9));
  });

  test('annualExtremeMinF is the mean of each year\'s lowest min', () {
    const lows = [20.0, 25.0, 30.0, 22.0, 18.0];
    final rows = [
      for (var y = 2021; y <= 2025; y++)
        ..._year(
          y,
          edit: (d) =>
              d.month == 2 && d.day == 1 ? _row(d, minF: lows[y - 2021]) : null,
        ),
    ];
    final months = monthlyNormals(rows);
    expect(annualValues(rows, months).extremeMinF, closeTo(23.0, 1e-9));
  });

  test('meanF is (avgLowF + avgHighF) / 2', () {
    final rows = _year(
      2021,
      edit: (d) => d.month == 3 ? _row(d, minF: 41, maxF: 79) : null,
    );
    final march = monthlyNormals(rows)[2];
    expect(march.avgLowF, 41);
    expect(march.avgHighF, 79);
    expect(march.meanF, 60);
  });

  test('a month with no data for a field throws FormatException', () {
    final rows = _year(
      2021,
      edit: (d) => d.month == 6 ? _row(d, maxF: null) : null,
    );
    expect(() => monthlyNormals(rows), throwsFormatException);
  });

  group('Baton Rouge fixture', () {
    final rows = archiveFixtureRows();
    final months = monthlyNormals(rows);

    test('12 months match the recorded values within 0.01', () {
      expect(months, hasLength(12));
      for (final (m, low, high, precip, rh, cloud, sun) in recordedMonths) {
        final got = months[m - 1];
        expect(got.month, m);
        expect(got.avgLowF, closeTo(low, 0.01), reason: 'low $m');
        expect(got.avgHighF, closeTo(high, 0.01), reason: 'high $m');
        expect(got.meanF, closeTo((low + high) / 2, 0.01), reason: 'mean $m');
        expect(got.precipIn, closeTo(precip, 0.01), reason: 'precip $m');
        expect(got.rhPct, closeTo(rh, 0.01), reason: 'rh $m');
        expect(got.cloudPct, closeTo(cloud, 0.01), reason: 'cloud $m');
        expect(got.sunshineHours, closeTo(sun, 0.01), reason: 'sun $m');
      }
    });

    test('12 months stay close to the plan/04 table', () {
      for (final (m, low, high, mean, precip, rh) in planMonths) {
        final got = months[m - 1];
        expect(got.avgLowF, closeTo(low, planTolerance.tempF), reason: '$m');
        expect(got.avgHighF, closeTo(high, planTolerance.tempF), reason: '$m');
        expect(got.meanF, closeTo(mean, planTolerance.tempF), reason: '$m');
        expect(
          got.precipIn,
          closeTo(precip, planTolerance.precipIn),
          reason: '$m',
        );
        expect(got.rhPct, closeTo(rh, planTolerance.rhPct), reason: '$m');
      }
    });

    test('annual values', () {
      final annual = annualValues(rows, months);
      // Yearly lows 17.7, 19.8, 31.1, 18.7, 10.9 (plan/04: 19.66).
      expect(annual.extremeMinF, closeTo(19.64, 0.01));
      expect(annual.precipIn, closeTo(58.18, 0.01));
      // plan/04: 75.
      expect(annual.rhPct, closeTo(75.38, 0.01));
    });
  });
}
