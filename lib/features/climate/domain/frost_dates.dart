import 'climate_normals.dart';

/// Typical frost days of year; null when frost is rare (fewer than 3 of
/// the years had one) or in the southern hemisphere.
class FrostDates {
  const FrostDates({this.lastSpringFrostDoy, this.firstFallFrostDoy});

  final int? lastSpringFrostDoy, firstFallFrostDoy;
}

/// Years that must have the event before a date is stored.
const _minYearsWithFrost = 3;

const _frostF = 32.0;

int _dayOfYear(DateTime d) =>
    DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(d.year)).inDays +
    1;

/// Median of [days]; with an even count, the mean of the two middle values
/// rounded to the nearest integer.
int _median(List<int> days) {
  final sorted = [...days]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

/// Last spring frost (latest Jan 1–Jul 31 day with a min ≤ 32 °F) and
/// first fall frost (earliest Aug 1–Dec 31 day) per year, then the median
/// across years (plan/04 § Climate profile step 5). Only for `lat >= 0`.
FrostDates frostDates(List<DailyClimateRow> rows, double lat) {
  if (lat < 0) return const FrostDates();
  final spring = <int, int>{};
  final fall = <int, int>{};
  for (final r in rows) {
    final min = r.minF;
    if (min == null || min > _frostF) continue;
    final year = r.date.year;
    final doy = _dayOfYear(r.date);
    if (r.date.month <= 7) {
      if (doy > (spring[year] ?? 0)) spring[year] = doy;
    } else {
      if (doy < (fall[year] ?? 367)) fall[year] = doy;
    }
  }
  int? typical(Map<int, int> byYear) => byYear.length >= _minYearsWithFrost
      ? _median(byYear.values.toList())
      : null;
  return FrostDates(
    lastSpringFrostDoy: typical(spring),
    firstFallFrostDoy: typical(fall),
  );
}
