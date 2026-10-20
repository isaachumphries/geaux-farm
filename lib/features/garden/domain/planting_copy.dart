import 'package:intl/intl.dart';

import '../../care/domain/care_event.dart';
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
String stageLine(GrowthStage stage, DateTime plantedOn, DateTime today) {
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

/// What kind of plant it is, as a friendly noun ("veggie", "herb").
String categoryNoun(PlantCategory c) => switch (c) {
  PlantCategory.vegetable => 'veggie',
  PlantCategory.herb => 'herb',
  PlantCategory.fruit => 'fruit',
  PlantCategory.flower => 'flower',
  PlantCategory.shrub => 'shrub',
  PlantCategory.houseplant => 'houseplant',
};

/// A short note for the planting's detail screen that changes with the
/// plant's category and where it is in its life: what to watch for now.
String stageNote(Plant p, GrowthStage stage) {
  final name = p.commonName;
  return switch (stage) {
    GrowthStage.sprouting => switch (p.category) {
      PlantCategory.herb || PlantCategory.vegetable =>
      'Seedlings are tender. Keep the soil evenly moist, not soggy.',
      _ => 'Keep the soil lightly moist while $name gets going.',
    },
    GrowthStage.growing => switch (p.category) {
      PlantCategory.vegetable =>
      'Steady water and sun now mean a bigger harvest later.',
      PlantCategory.herb =>
      'Pinch the tips often. It keeps $name bushy and full.',
      PlantCategory.fruit =>
      'Watch for flowers. Fruit follows, so keep watering steady.',
      PlantCategory.flower =>
      'Buds are on the way. Feed lightly and give it full light.',
      PlantCategory.shrub =>
      'Roots are spreading. Deep, less frequent watering helps.',
      PlantCategory.houseplant =>
      'Turn the pot now and then so it grows evenly.',
    },
    GrowthStage.readyToHarvest => switch (p.category) {
      PlantCategory.herb => 'Snip what you need. More grows back.',
      PlantCategory.fruit => 'Pick fruit as it ripens to keep more coming.',
      _ => '$name is ready. Harvest often to keep it producing.',
    },
    GrowthStage.blooming =>
    'In bloom! Remove spent flowers to keep new ones coming.',
    GrowthStage.established =>
    '$name has settled in. It needs less fuss from here.',
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

/// "Today · 6:12 AM" for [at] on [today], otherwise "Sun, Oct 4".
String careLogDate(DateTime at, DateTime today) {
  if (calendarDay(at) == calendarDay(today)) {
    return 'Today · ${DateFormat('h:mm a', 'en_US').format(at)}';
  }
  return DateFormat('EEE, MMM d', 'en_US').format(at);
}

/// Water chip text for a due day: "Water now" when overdue, "Water today",
/// "Water tomorrow", or "Water Sat" within the week.
String waterChipLabel(DateTime due, DateTime today) {
  final days = daysFrom(today, due);
  if (days < 0) return 'Water now';
  if (days == 0) return 'Water today';
  if (days == 1) return 'Water tomorrow';
  return 'Water ${DateFormat('EEE', 'en_US').format(due)}';
}

/// GD-02 header chip: "Next water Sat", "Next water today", or "Water
/// now" when overdue.
String nextWaterLabel(DateTime due, DateTime today) {
  final days = daysFrom(today, due);
  if (days < 0) return 'Water now';
  if (days == 0) return 'Next water today';
  if (days == 1) return 'Next water tomorrow';
  return 'Next water ${DateFormat('EEE', 'en_US').format(due)}';
}

/// When an upcoming care job is due: "Overdue since Mon, Oct 5", "Due
/// today", "Due tomorrow", or "Due Sat, Oct 10".
String dueLabel(DateTime due, DateTime today) {
  final days = daysFrom(today, due);
  final date = DateFormat('EEE, MMM d', 'en_US').format(due);
  if (days < 0) return 'Overdue since $date';
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'Due $date';
}

/// "Every 14 days" for a catalog task.
String everyLabel(int days) => switch (days) {
  1 => 'Every day',
  7 => 'Every week',
  14 => 'Every 2 weeks',
  30 => 'Every month',
  _ => 'Every $days days',
};