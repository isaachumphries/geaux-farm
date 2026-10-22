import 'package:intl/intl.dart';

import '../../care/domain/care_event.dart';
import '../../care/domain/stage.dart';
import '../../catalog/domain/plant.dart';
import '../../onboarding/domain/space.dart';
import 'growth.dart';
import 'planting.dart';

/// "Balcony", "Yard bed": a space type as a card label.
String spaceLabel(SpaceType type) => switch (type) {
  SpaceType.windowsill => 'Windowsill',
  SpaceType.balcony => 'Balcony',
  SpaceType.smallYard => 'Yard bed',
  SpaceType.largeYard => 'Yard',
  SpaceType.communityPlot => 'Community plot',
};

String growSetupLabel(GrowSetup s) => switch (s) {
  GrowSetup.outdoor => 'Outdoors',
  GrowSetup.indoor => 'Indoors',
  GrowSetup.greenhouse => 'Greenhouse',
};

/// "Balcony · Outdoors" (GD-01), or just the setup when the space is
/// unknown.
String whereLabel(SpaceType? space, GrowSetup setup) => space == null
    ? growSetupLabel(setup)
    : '${spaceLabel(space)} · ${growSetupLabel(setup)}';

/// "Growing · Day 18"; "Planted today" on day 0.
String stageLine(PlantingStage stage, DateTime plantedOn, DateTime today) {
  final day = daysFrom(plantedOn, today);
  if (day <= 0) return 'Planted today';
  return '${stage.label} · Day $day';
}

/// When the planting should mature, from its planted date and the
/// catalog's day range for its start, worded for the plant's maturity
/// kind: "Harvest window: Nov 8 – Nov 23", "Blooms Nov 8 – Nov 23",
/// "Settled in by Jan 5", or "Grows year-round". Null when there is no
/// planted date or no start data.
String? maturityLine(Plant p, Planting pl) {
  if (p.maturityKind == MaturityKind.foliage) return 'Grows year-round';
  final planted = pl.plantedOn;
  final start = startFor(p, pl);
  if (planted == null || start == null) return null;
  final fmt = DateFormat('MMM d', 'en_US');
  final from = fmt.format(plusDays(calendarDay(planted), start.daysMin));
  final to = fmt.format(plusDays(calendarDay(planted), start.daysMax));
  return switch (p.maturityKind) {
    MaturityKind.harvest => 'Harvest window: $from – $to',
    MaturityKind.bloom => 'Blooms $from – $to',
    MaturityKind.establish => 'Settled in by $to',
    MaturityKind.foliage => 'Grows year-round',
  };
}

/// Care-log wording for one event.
String careEventLabel(CareEvent e) => switch (e.type) {
  CareEventType.water => 'Watered',
  CareEventType.skipWater => 'Skipped watering',
  CareEventType.fertilize => 'Fertilized',
  CareEventType.prune => 'Pruned',
  CareEventType.harvest => 'Harvested',
  CareEventType.note => e.note == null ? 'Note' : '“${e.note}”',
};

/// "Today · 6:12 AM" for [at] on [today], otherwise "Sun, Oct 4 · 8:00 AM"
/// (plan/05 GD-02: each log row shows its date and time).
String careLogDate(DateTime at, DateTime today) {
  final time = DateFormat('h:mm a', 'en_US').format(at);
  if (calendarDay(at) == calendarDay(today)) return 'Today · $time';
  return '${DateFormat('EEE, MMM d', 'en_US').format(at)} · $time';
}

/// A planted date in the care log, which has no time of day: "Today" or
/// "Sun, Oct 4".
String plantedLogDate(DateTime plantedOn, DateTime today) =>
    calendarDay(plantedOn) == calendarDay(today)
    ? 'Today'
    : DateFormat('EEE, MMM d', 'en_US').format(plantedOn);

/// Water chip text for a due day: "Water now" when overdue, "Water today",
/// "Water tomorrow", or "Water Sat" within the week.
String waterChipLabel(DateTime due, DateTime today) {
  final days = daysFrom(today, due);
  if (days < 0) return 'Water now';
  if (days == 0) return 'Water today';
  if (days == 1) return 'Water tomorrow';
  return 'Water ${DateFormat('EEE', 'en_US').format(due)}';
}

/// GD-02 next-water chip (#30): "Next water: Thu, Oct 8 · 8:00 AM", the
/// day and start of the free-time slot the watering goes in. [clock] is the
/// slot's start already in the device's time format, or "Outside your free
/// times".
String nextWaterLabel(DateTime slotStart, String clock) =>
    'Next water: ${DateFormat('EEE, MMM d', 'en_US').format(slotStart)} · '
    '$clock';

/// "Every 14 days" for a catalog task.
String everyLabel(int days) => switch (days) {
  1 => 'Every day',
  7 => 'Every week',
  14 => 'Every 2 weeks',
  30 => 'Every month',
  _ => 'Every $days days',
};
