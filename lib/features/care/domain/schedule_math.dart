import 'care_event.dart';

/// Local calendar day of [t], with the time of day dropped.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// [d] moved by [days] calendar days. Built from date fields, so DST never
/// shifts the result.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Whole calendar days from [from] to [to]. UTC keeps DST out of the count.
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Latest local day among this planting's events that satisfy [matches], or
/// null when none does.
DateTime? lastEventDay(
  String plantingId,
  Iterable<CareEvent> events,
  bool Function(CareEvent event) matches,
) {
  DateTime? last;
  for (final e in events) {
    if (e.plantingId != plantingId || !matches(e)) continue;
    final d = dayOf(e.at);
    if (last == null || d.isAfter(last)) last = d;
  }
  return last;
}
