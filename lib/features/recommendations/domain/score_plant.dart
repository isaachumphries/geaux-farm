import 'dart:math' as math;

import '../../catalog/domain/plant.dart';
import '../../climate/domain/climate_profile.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/domain/space.dart';
import '../../onboarding/domain/user_profile.dart';
import 'compat_level.dart';
import 'compatibility.dart';
import 'in_season.dart';
import 'indoor_climate.dart';

/// Points each factor adds to the 0–100 score; the values sum to 100.
const scoreWeights = {
  'climate': 35,
  'light': 20,
  'space': 15,
  'care': 15,
  'goals': 10,
  'experience': 5,
};

/// plan/04 § Scoring. [p] must be [Plant.scorable].
Compatibility scorePlant(
  Plant p,
  UserContext ctx,
  GrowSetup setup,
  DateTime today,
) {
  if (!p.scorable) {
    throw ArgumentError.value(p.id, 'p', 'plant is not scorable');
  }
  final outdoor = setup == GrowSetup.outdoor;
  final months = outdoor ? ctx.climate.months : indoorClimateMonths;
  final outdoorClimate = _outdoorClimateFit(p, ctx.climate);

  final fits = <String, double>{
    'climate': outdoor ? outdoorClimate : _indoorClimateFit(p),
    'light': lightFit(userSun(ctx.space, setup), p.sun!),
    'space': _spaceFit(p, ctx.space, setup),
    'care': careFit(
      outdoor ? p.water!.everyDaysOutdoor : p.water!.everyDaysIndoor,
      ctx.profile.availability.careDays,
    ),
    'goals': goalsFit(ctx.profile.goals, p.purposes),
    'experience': experienceFit(p.difficulty, ctx.profile.experience),
  };
  final score = scoreWeights.entries
      .fold<double>(0, (sum, e) => sum + e.value * fits[e.key]!)
      .round();

  return Compatibility(
    score: score,
    level: compatLevelFor(score),
    fits: Map.unmodifiable(fits),
    inSeason: inSeason(p, months, today.month),
    outdoorViable: outdoorClimate >= 0.5,
    monthStrip: List.unmodifiable([
      for (var m = 1; m <= 12; m++) inSeason(p, months, m),
    ]),
  );
}

/// Outdoor climate fit including the humidity multiplier.
double _outdoorClimateFit(Plant p, ClimateProfile climate) {
  final double fit;
  if (p.lifecycle == Lifecycle.perennial) {
    final user = zoneNumericValue(climate.zone);
    final range = p.zoneNumeric!;
    final outside = user < range.min
        ? range.min - user
        : (user > range.max ? user - range.max : 0.0);
    fit = outside == 0 ? 1 : (outside <= 1.0 ? 0.5 : 0);
  } else {
    // Annual and biennial: 1 if any month is in season, else the best
    // share of growing-window months that pass.
    fit = _annualClimateFit(p, climate.months);
  }
  return fit * humidityMultiplier(p.humidity, climate.annualRhPct);
}

double _annualClimateFit(Plant p, List<ClimateMonth> months) {
  for (var m = 1; m <= 12; m++) {
    if (inSeason(p, months, m)) return 1;
  }
  final n = seasonWindowMonths(p);
  var best = 0;
  for (var start = 0; start < 12; start++) {
    var passing = 0;
    for (var k = 0; k < n; k++) {
      if (growMonthOk(p, months, start + k)) passing++;
    }
    best = math.max(best, passing);
  }
  return best / n;
}

double _indoorClimateFit(Plant p) =>
    (indoorTempsSuit(p) ? 1.0 : 0.5) *
    humidityMultiplier(p.humidity, indoorRhPct);

/// Whether the grow-temperature range covers the 65–75 °F indoor band.
bool indoorTempsSuit(Plant p) {
  final g = p.growTempF!;
  return g.min <= 65 && g.max >= 75;
}

double humidityMultiplier(Humidity h, double rhPct) =>
    (h == Humidity.low && rhPct >= 70) || (h == Humidity.high && rhPct < 45)
    ? 0.8
    : 1.0;

SunLevel userSun(Space space, GrowSetup setup) => switch (setup) {
  GrowSetup.outdoor => space.sun,
  GrowSetup.indoor =>
    space.type == SpaceType.windowsill ? space.sun : SunLevel.partial,
  GrowSetup.greenhouse => SunLevel.full,
};

/// Distance from [user] to the nearest level in [plant]: 0 → 1, 1 → 0.5,
/// 2 → 0.
double lightFit(SunLevel user, List<SunLevel> plant) {
  final d = plant.map((s) => (s.index - user.index).abs()).reduce(math.min);
  return switch (d) {
    0 => 1,
    1 => 0.5,
    _ => 0,
  };
}

double _spaceFit(Plant p, Space space, GrowSetup setup) {
  final s = p.space!;
  final ratio = math.min(1.0, space.areaSqFt / s.sqFtPerPlant);
  if (setup == GrowSetup.indoor) return s.indoorOk ? ratio : 0;
  if (space.type == SpaceType.windowsill || space.type == SpaceType.balcony) {
    return s.containerOk ? ratio : 0;
  }
  return ratio;
}

/// Waterings per week the plant needs: `clamp(ceil(7 / everyDays), 1, 7)`.
int requiredCareDays(int everyDays) => (7 / everyDays).ceil().clamp(1, 7);

double careFit(int everyDays, int careDays) =>
    math.min(1.0, careDays / requiredCareDays(everyDays));

/// S = goals ∩ {food, design}: empty → 1, overlaps purposes → 1, else 0.3.
double goalsFit(List<Goal> goals, List<PlantPurpose> purposes) {
  final s = {
    if (goals.contains(Goal.food)) PlantPurpose.food,
    if (goals.contains(Goal.design)) PlantPurpose.design,
  };
  if (s.isEmpty || purposes.any(s.contains)) return 1;
  return 0.3;
}

/// d = difficulty − level (beginner 1 … expert 3): ≤ 0 → 1, 1 → 0.5,
/// 2 → 0.2.
double experienceFit(int difficulty, Experience level) {
  final d = difficulty - (level.index + 1);
  if (d <= 0) return 1;
  if (d == 1) return 0.5;
  return 0.2;
}
