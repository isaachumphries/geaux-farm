import '../../catalog/domain/plant.dart';
import 'planting.dart';

/// Local calendar day of [t], with the time of day dropped.
DateTime calendarDay(DateTime t) => DateTime(t.year, t.month, t.day);

/// [d] moved by [days] calendar days. Built from date fields, so DST never
/// shifts the result.
DateTime plusDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Whole calendar days from [from] to [to]. UTC keeps DST out of the count.
int daysFrom(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The catalog start that matches how [pl] was started, falling back to the
/// plant's first start. Null when the plant lists none.
PlantStart? startFor(Plant p, Planting pl) {
  final starts = p.starts;
  if (starts == null || starts.isEmpty) return null;
  for (final s in starts) {
    if (s.method.json == pl.startMethod) return s;
  }
  return starts.first;
}
