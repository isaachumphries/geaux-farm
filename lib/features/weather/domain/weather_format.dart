/// Display helpers for WX-01 (pure Dart; callers pass `now` and units).
///
/// Values stay in °F and inches everywhere else; these only decide what the
/// screen writes (plan/06 § Units).
library;

import 'package:intl/intl.dart';

import '../../../core/units.dart';
import 'weather.dart';

/// Cached data older than this, after a failed refresh, also shows the
/// "Showing saved weather" banner (plan/06 § Caching and refresh).
const offlineBannerAfter = Duration(hours: 3);

/// True when a failed refresh left data older than 3 hours (exactly 3 is
/// still quiet).
bool showsOfflineBanner(DateTime fetchedAt, DateTime now) =>
    now.difference(fetchedAt) > offlineBannerAfter;

/// Rain chance at or above this draws blue in the 7-day strip.
const likelyRainPct = 50;

/// A temperature as the user's unit and a whole number, no symbol.
int displayTemp(double fahrenheit, {required bool metric}) =>
    metric ? fahrenheitToCelsiusDisplay(fahrenheit) : fahrenheit.round();

/// Annual rain: whole inches, or whole millimetres when [metric].
String annualRainText(double inches, {required bool metric}) => metric
    ? '${inchesToMillimetersDisplay(inches).round()} mm a year'
    : '${inches.round()} in a year';

/// UV index category on the WHO scale: 0–2 Low, 3–5 Moderate, 6–7 High,
/// 8–10 Very high, 11+ Extreme. The index is rounded first.
String uvLabel(double uvIndex) {
  final uv = uvIndex.round();
  if (uv <= 2) return 'Low';
  if (uv <= 5) return 'Moderate';
  if (uv <= 7) return 'High';
  if (uv <= 10) return 'Very high';
  return 'Extreme';
}

/// `6:59 AM` from a local ISO time such as `2026-10-13T06:59`.
String clockText(String localIso) =>
    DateFormat('h:mm a', 'en_US').format(DateTime.parse(localIso));

/// `11h 42m`, rounded to the nearest minute.
String daylightText(double seconds) {
  final minutes = (seconds / 60).round();
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

/// `TODAY · WED, OCT 7`.
String todayOverline(DateTime date) =>
    'TODAY · ${DateFormat('EEE, MMM d', 'en_US').format(date).toUpperCase()}';

/// `Thu`.
String weekdayShort(DateTime date) => DateFormat('E', 'en_US').format(date);

/// Up to seven rows starting at today's row: the 7-day strip. Empty when the
/// forecast has no row for [today].
List<WeatherDay> nextSevenDays(List<WeatherDay> days, DateTime today) {
  final first = todayRow(days, today);
  if (first == null) return const [];
  final start = days.indexOf(first);
  final end = start + 7 > days.length ? days.length : start + 7;
  return days.sublist(start, end);
}
