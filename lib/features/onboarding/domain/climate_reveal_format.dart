import 'package:intl/intl.dart';

import '../../climate/domain/climate_profile.dart';

/// The lines of the OB-02b climate card (plan/02 § OB-02b Climate reveal).
/// Pure: no clock, no Flutter.

String zoneLine(ClimateProfile p) => 'Zone ${p.zone}';

/// The warmest monthly average high, rounded to a whole °F.
String summerLine(ClimateProfile p) {
  final max = p.months.map((m) => m.avgHighF).reduce((a, b) => a > b ? a : b);
  return 'Summer highs ~${max.round()}°F';
}

/// The coldest monthly average low, rounded to a whole °F.
String winterLine(ClimateProfile p) {
  final min = p.months.map((m) => m.avgLowF).reduce((a, b) => a < b ? a : b);
  return 'Winter lows ~${min.round()}°F';
}

/// The sum of the monthly precipitation, rounded to a whole inch.
String rainLine(ClimateProfile p) {
  final total = p.months.fold<double>(0, (sum, m) => sum + m.precipIn);
  return '${total.round()} in of rain a year';
}

/// `Humid` at 70 % or more, `Dry` at 45 % or less, else `Moderate`.
String humidityLabel(double annualRhPct) {
  if (annualRhPct >= 70) return 'Humid';
  if (annualRhPct <= 45) return 'Dry';
  return 'Moderate';
}

/// `Last spring frost ~Feb 20`, or `Frost is rare here` when the profile
/// has no spring frost date. Null (line hidden) south of the equator.
String? frostLine(int? lastSpringFrostDoy, double lat) {
  if (lat < 0) return null;
  if (lastSpringFrostDoy == null) return 'Frost is rare here';
  // Day of year in a non-leap year, matching how frost dates are shown.
  final date = DateTime.utc(2025).add(Duration(days: lastSpringFrostDoy - 1));
  return 'Last spring frost ~${DateFormat('MMM d', 'en_US').format(date)}';
}
