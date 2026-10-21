import '../../catalog/domain/plant.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/domain/space.dart';
import '../../onboarding/domain/user_profile.dart';
import 'compatibility.dart';
import 'indoor_climate.dart';
import 'score_plant.dart';

/// The six factors of the score, in the order PD-01 lists them.
enum ScoreFactor {
  climate('Climate'),
  light('Light'),
  space('Space'),
  care('Care time'),
  goals('Your goals'),
  experience('Experience');

  const ScoreFactor(this.label);

  final String label;
}

/// One bar of the PD-01 score breakdown.
class ScoreRow {
  const ScoreRow({
    required this.factor,
    required this.fit,
    required this.reason,
  });

  final ScoreFactor factor;

  /// Share of the factor's weight earned, 0–1.
  final double fit;

  /// Plain-language reason printed under the bar.
  final String reason;

  /// [fit] as a whole percent, as shown beside the bar.
  int get percent => (fit * 100).round();
}

const _monthAbbrevs = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Score rows for [plant] in [ScoreFactor] order. [compat] must be the
/// result of `scorePlant` for the same plant, context, and setup.
List<ScoreRow> scoreRows({
  required Plant plant,
  required UserContext ctx,
  required GrowSetup setup,
  required Compatibility compat,
}) => [
  for (final factor in ScoreFactor.values)
    ScoreRow(
      factor: factor,
      fit: compat.fits[factor.name]!,
      reason: _reason(factor, plant, ctx, setup, compat),
    ),
];

String _reason(
  ScoreFactor factor,
  Plant p,
  UserContext ctx,
  GrowSetup setup,
  Compatibility compat,
) => switch (factor) {
  ScoreFactor.climate => _climateReason(p, ctx, setup, compat),
  ScoreFactor.light => _lightReason(p, ctx, setup),
  ScoreFactor.space => _spaceReason(p, ctx.space, setup),
  ScoreFactor.care => _careReason(p, ctx, setup),
  ScoreFactor.goals => _goalsReason(p, ctx.profile.goals),
  ScoreFactor.experience => _experienceReason(p.difficulty),
};

String _climateReason(
  Plant p,
  UserContext ctx,
  GrowSetup setup,
  Compatibility compat,
) {
  final outdoor = setup == GrowSetup.outdoor;
  final rhPct = outdoor ? ctx.climate.annualRhPct : indoorRhPct;
  final base = outdoor
      ? _outdoorClimateText(p, ctx, compat)
      : _indoorClimateText(p);
  if (humidityMultiplier(p.humidity, rhPct) >= 1) return base;
  return p.humidity == Humidity.low
      ? '$base · dislikes humidity'
      : '$base · wants more humidity';
}

String _outdoorClimateText(Plant p, UserContext ctx, Compatibility compat) {
  if (p.lifecycle == Lifecycle.perennial) {
    final zones = p.zones!;
    return 'Hardy in zones ${zones.min}–${zones.max}; '
        "you're in ${ctx.climate.zone}";
  }
  final months = [
    for (var i = 0; i < 12; i++)
      if (compat.monthStrip[i]) _monthAbbrevs[i],
  ];
  return months.isEmpty
      ? 'No months fully in season here'
      : 'Grows well here: ${months.join(', ')}';
}

String _indoorClimateText(Plant p) => indoorTempsSuit(p)
    ? 'Indoor temperatures suit it'
    : 'Indoor temperatures partly suit it';

String _lightReason(Plant p, UserContext ctx, GrowSetup setup) {
  final needs = p.sun!.map(_sunText).join(' or ');
  final spot = _sunText(userSun(ctx.space, setup));
  return 'Needs $needs; your spot gets $spot';
}

String _sunText(SunLevel s) => switch (s) {
  SunLevel.shade => 'shade',
  SunLevel.partial => 'partial sun',
  SunLevel.full => 'full sun',
};

String _spaceReason(Plant p, Space space, GrowSetup setup) {
  final s = p.space!;
  if (setup == GrowSetup.indoor && !s.indoorOk) return 'Not an indoor plant';
  final container =
      space.type == SpaceType.windowsill || space.type == SpaceType.balcony;
  if (setup != GrowSetup.indoor && container && !s.containerOk) {
    return 'Not suited to containers';
  }
  final sqFt = _sqFt(s.sqFtPerPlant);
  return 'Needs ~$sqFt sq ft; you have ${space.areaSqFt} sq ft';
}

String _sqFt(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

String _careReason(Plant p, UserContext ctx, GrowSetup setup) {
  final everyDays = setup == GrowSetup.outdoor
      ? p.water!.everyDaysOutdoor
      : p.water!.everyDaysIndoor;
  final careDays = ctx.profile.availability.careDays;
  return 'Water every ~$everyDays days; you have $careDays care days';
}

String _goalsReason(Plant p, List<Goal> goals) {
  final wanted = {
    if (goals.contains(Goal.food)) PlantPurpose.food,
    if (goals.contains(Goal.design)) PlantPurpose.design,
  };
  if (wanted.isEmpty) return 'No specific goals to match';
  final matched = p.purposes.where(wanted.contains).toList();
  if (matched.isEmpty) return 'Not one of your goals';
  return 'Matches: ${matched.map((purpose) => purpose.name).join(', ')}';
}

String _experienceReason(int difficulty) => switch (difficulty) {
  1 => 'Difficulty: Easy',
  2 => 'Difficulty: Moderate',
  _ => 'Difficulty: Challenging',
};
