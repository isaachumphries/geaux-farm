// Synthetic climates and plants for pinning plan/04 thresholds exactly,
// where the Baton Rouge normals don't land on a boundary.
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';

import 'baton_rouge.dart';
import 'scored.dart';

/// Twelve months (index 0 = January) at [low]–[high] °F, with 1-based
/// [overrides] month → (low, high).
List<ClimateMonth> monthsOf({
  double low = 50,
  double high = 70,
  Map<int, (double, double)> overrides = const {},
}) => [
  for (var m = 1; m <= 12; m++)
    ClimateMonth(
      month: m,
      avgLowF: overrides[m]?.$1 ?? low,
      avgHighF: overrides[m]?.$2 ?? high,
      precipIn: 0,
      rhPct: 50,
      cloudPct: 0,
      sunshineHours: 0,
    ),
];

/// The Baton Rouge profile with selected values replaced.
ClimateProfile climateWith({
  List<ClimateMonth>? months,
  double? annualRhPct,
  String? zone,
}) => ClimateProfile(
  months: months ?? batonRougeMonths,
  annualExtremeMinF: batonRougeClimate.annualExtremeMinF,
  annualPrecipIn: batonRougeClimate.annualPrecipIn,
  annualRhPct: annualRhPct ?? batonRougeClimate.annualRhPct,
  zone: zone ?? batonRougeClimate.zone,
  zoneSource: batonRougeClimate.zoneSource,
  lastSpringFrostDoy: batonRougeClimate.lastSpringFrostDoy,
  firstFallFrostDoy: batonRougeClimate.firstFallFrostDoy,
  computedAt: batonRougeClimate.computedAt,
);

/// The worked-example user (32 sq ft partial-sun balcony) in [climate].
UserContext contextIn(ClimateProfile climate) => UserContext(
  profile: workedExample.profile,
  space: workedExample.space,
  climate: climate,
);

/// Kale reshaped so its growing window is exactly ceil([windowDays] / 30)
/// months (productiveDays 0), with the given temperature ranges.
Plant windowPlant({
  required num plantMin,
  required num plantMax,
  required num growMin,
  required num growMax,
  int windowDays = 30,
  String lifecycle = 'annual',
}) => kaleWith({
  'lifecycle': lifecycle,
  'plantTempF': {'min': plantMin, 'max': plantMax},
  'growTempF': {'min': growMin, 'max': growMax},
  'starts': [
    {'method': 'transplant', 'daysMin': windowDays, 'daysMax': windowDays},
  ],
  'productiveDays': 0,
});
