/// Maps a notification tap payload to the route it should open.
///
/// Care payloads have the form `care?date=YYYY-MM-DD` (plan/05). Anything else,
/// including a malformed or impossible date, falls back to the care schedule
/// without a date.
String routeForPayload(String? payload) {
  if (payload == null) return _careFallback;
  final uri = Uri.tryParse(payload);
  if (uri == null || uri.path != 'care') return _careFallback;
  final date = uri.queryParameters['date'];
  if (date == null || !_isCalendarDate(date)) return _careFallback;
  return '/care?date=$date';
}

const _careFallback = '/care';

final _datePattern = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$');

/// Strict `YYYY-MM-DD` check. The round-trip rejects rollover such as
/// `2026-02-30`, which `DateTime.utc` would otherwise silently normalize.
bool _isCalendarDate(String raw) {
  final match = _datePattern.firstMatch(raw);
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.utc(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day;
}
