import '../../climate/domain/climate_profile.dart';

/// Relative humidity assumed indoors and in a greenhouse (plan/04 § Indoor
/// and greenhouse model).
const double indoorRhPct = 40;

/// Fixed indoor and greenhouse climate: every month 65–75 °F (meanF 70).
/// Index 0 = January.
final List<ClimateMonth> indoorClimateMonths = List.unmodifiable([
  for (var m = 1; m <= 12; m++)
    ClimateMonth(
      month: m,
      avgLowF: 65,
      avgHighF: 75,
      precipIn: 0,
      rhPct: indoorRhPct,
      cloudPct: 0,
      sunshineHours: 0,
    ),
]);
