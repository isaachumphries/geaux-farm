import 'climate_profile.dart';

/// One day of the Open-Meteo archive. Any field may be null; nulls are
/// skipped per field (plan/04 § Climate profile).
class DailyClimateRow {
  const DailyClimateRow({
    required this.date,
    this.minF,
    this.maxF,
    this.precipIn,
    this.rhPct,
    this.cloudPct,
    this.sunshineS,
  });

  final DateTime date;
  final double? minF, maxF, precipIn, rhPct, cloudPct, sunshineS;
}

/// The year-level values of a climate profile.
class AnnualClimate {
  const AnnualClimate({
    required this.extremeMinF,
    required this.precipIn,
    required this.rhPct,
  });

  final double extremeMinF, precipIn, rhPct;
}

double? _mean(Iterable<double?> values) {
  var sum = 0.0;
  var n = 0;
  for (final v in values) {
    if (v == null) continue;
    sum += v;
    n++;
  }
  return n == 0 ? null : sum / n;
}

double _require(double? value, String what) =>
    value ?? (throw FormatException('No archive data for $what'));

int _yearCount(List<DailyClimateRow> rows) =>
    rows.map((r) => r.date.year).toSet().length;

/// The 12 calendar-month normals across every year in [rows], January
/// first. `precipIn` is the month's total over all years divided by the
/// number of years. Throws [FormatException] when a month has no value for
/// a field.
List<ClimateMonth> monthlyNormals(List<DailyClimateRow> rows) {
  final years = _yearCount(rows);
  return [
    for (var m = 1; m <= 12; m++)
      () {
        final days = rows.where((r) => r.date.month == m).toList();
        final precip = days.where((r) => r.precipIn != null);
        if (precip.isEmpty) throw FormatException('No precipitation in $m');
        return ClimateMonth(
          month: m,
          avgLowF: _require(_mean(days.map((r) => r.minF)), 'min $m'),
          avgHighF: _require(_mean(days.map((r) => r.maxF)), 'max $m'),
          precipIn: precip.fold(0.0, (s, r) => s + r.precipIn!) / years,
          rhPct: _require(_mean(days.map((r) => r.rhPct)), 'RH $m'),
          cloudPct: _require(_mean(days.map((r) => r.cloudPct)), 'cloud $m'),
          sunshineHours:
              _require(_mean(days.map((r) => r.sunshineS)), 'sun $m') / 3600,
        );
      }(),
  ];
}

/// Annual values: the mean of each year's lowest daily minimum, the sum of
/// the monthly [months] precipitation, and the mean of every daily RH.
AnnualClimate annualValues(
  List<DailyClimateRow> rows,
  List<ClimateMonth> months,
) {
  final lowestByYear = <int, double>{};
  for (final r in rows) {
    final min = r.minF;
    if (min == null) continue;
    final current = lowestByYear[r.date.year];
    if (current == null || min < current) lowestByYear[r.date.year] = min;
  }
  return AnnualClimate(
    extremeMinF: _require(_mean(lowestByYear.values), 'annual minimum'),
    precipIn: months.fold(0.0, (s, m) => s + m.precipIn),
    rhPct: _require(_mean(rows.map((r) => r.rhPct)), 'annual RH'),
  );
}
