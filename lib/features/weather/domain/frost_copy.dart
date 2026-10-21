import 'package:intl/intl.dart';

/// `First fall frost ~Nov 30`, or `Fall frost is rare` when the climate
/// profile has no fall frost date. Null (line hidden) south of the equator.
/// Pure: no clock, no Flutter. Mirrors `frostLine` for the spring date.
String? fallFrostLine(int? firstFallFrostDoy, double lat) {
  if (lat < 0) return null;
  if (firstFallFrostDoy == null) return 'Fall frost is rare';
  // Day of year in a non-leap year, matching how frost dates are shown.
  final date = DateTime.utc(2025).add(Duration(days: firstFallFrostDoy - 1));
  return 'First fall frost ~${DateFormat('MMM d', 'en_US').format(date)}';
}
