import '../../care/domain/care_event.dart';
import '../../catalog/domain/plant.dart';
import 'planting.dart';

/// Local calendar day of [t], with the time of day dropped.
DateTime calendarDay(DateTime t) => DateTime(t.year, t.month, t.day);

/// [d] moved by [days] calendar days. Built from date fields, so DST never
/// shifts the result.
DateTime plusDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Whole calendar days from [from] to [to]. UTC keeps DST out of the count.
int daysFrom(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Where a planting is in its life, derived on read and never stored.
enum GrowthStage {
  sprouting('Sprouting'),
  growing('Growing'),
  readyToHarvest('Ready to harvest'),
  blooming('Blooming'),
  established('Established');

  const GrowthStage(this.label);

  final String label;
}

class GrowthReading {
  const GrowthReading({
    required this.stage,
    required this.progress,
    required this.showsProgressRing,
  });

  final GrowthStage stage;

  /// Share of the catalog's days-to-maturity elapsed, 0 to 1.
  final double progress;
  final bool showsProgressRing;
}

/// Seeds show Sprouting for this many days after planting.
const _sproutingDays = 10;

/// The catalog start that matches how [pl] was started, falling back to the
/// plant's first start. Null when the plant lists none.
PlantStart? startFor(Plant p, Planting pl) {
  final starts = p.starts;
  if (starts == null || starts.isEmpty) return null;
  for (final s in starts) {
    if (s.method.json == pl.startMethod) return s;
  }
  return starts.first;
}

/// Stage of [pl] on [today]. Seeds sprout for their first [_sproutingDays]
/// days; after that the plant grows until the catalog's minimum days to
/// maturity, then follows its maturity kind. Null without a planted date.
GrowthReading? growthOf(Planting pl, Plant p, DateTime today) {
  final planted = pl.plantedOn;
  if (planted == null) return null;
  final daysSince = daysFrom(planted, today);
  final start = startFor(p, pl);
  final progress = start == null
      ? 0.0
      : start.daysMin <= 0
      ? 1.0
      : (daysSince / start.daysMin).clamp(0.0, 1.0);

  final GrowthStage stage;
  if (pl.startMethod == StartMethod.seed.json && daysSince < _sproutingDays) {
    stage = GrowthStage.sprouting;
  } else if (progress < 1) {
    stage = GrowthStage.growing;
  } else {
    stage = switch (p.maturityKind) {
      MaturityKind.harvest => GrowthStage.readyToHarvest,
      MaturityKind.bloom => GrowthStage.blooming,
      MaturityKind.establish => GrowthStage.established,
      MaturityKind.foliage => GrowthStage.growing,
    };
  }
  return GrowthReading(
    stage: stage,
    progress: progress,
    showsProgressRing: p.maturityKind != MaturityKind.foliage,
  );
}

/// One care job on one planting and the day it is next due.
class CareDue {
  const CareDue({required this.type, required this.due, this.note});

  /// The event that completes this job when logged.
  final CareEventType type;
  final DateTime due;

  /// The catalog's note for the job, e.g. "Pick the outer leaves".
  final String? note;
}

/// Care shows jobs due from now through this many days ahead.
const careWindowDays = 7;

/// Care jobs for an active [pl] due by [today] + [careWindowDays] - 1,
/// overdue ones included, soonest first.
///
/// Watering repeats every `water.everyDaysOutdoor` days outdoors and
/// `everyDaysIndoor` otherwise, counted from the last water or skip (or the
/// planted day, when it is due right away). Catalog tasks repeat every
/// `everyDays` from the last event that completes them or from the planted
/// day; harvest appears only once the plant has matured.
///
/// This is a simple stand-in for the weather-aware care schedule; when that
/// lands, the garden screens should read it instead.
List<CareDue> careDueFor(
    Planting pl,
    Plant p,
    List<CareEvent> events,
    DateTime today,
    ) {
  final planted = pl.plantedOn;
  if (pl.status != PlantingStatus.active || planted == null) return const [];
  final plantedDay = calendarDay(planted);
  final windowEnd = plusDays(calendarDay(today), careWindowDays - 1);

  DateTime? last(bool Function(CareEvent) matches) {
    DateTime? latest;
    for (final e in events) {
      if (e.plantingId != pl.id || !matches(e)) continue;
      final d = calendarDay(e.at);
      if (latest == null || d.isAfter(latest)) latest = d;
    }
    return latest;
  }

  final jobs = <CareDue>[];
  final water = p.water;
  if (water != null) {
    final lastWater = last(
          (e) => e.type == CareEventType.water || e.type == CareEventType.skipWater,
    );
    final every = pl.setup == GrowSetup.outdoor
        ? water.everyDaysOutdoor
        : water.everyDaysIndoor;
    jobs.add(
      CareDue(
        type: CareEventType.water,
        due: lastWater == null ? plantedDay : plusDays(lastWater, every),
      ),
    );
  }

  final progress = growthOf(pl, p, today)?.progress ?? 0;
  for (final task in p.care.tasks) {
    if (task.type == TaskType.harvest && progress < 1) continue;
    final type = switch (task.type) {
      TaskType.fertilize => CareEventType.fertilize,
      TaskType.prune => CareEventType.prune,
      TaskType.harvest => CareEventType.harvest,
      TaskType.other => CareEventType.note,
    };
    final done = last(
          (e) =>
      e.type == type &&
          (task.type != TaskType.other || e.note == task.note),
    );
    jobs.add(
      CareDue(
        type: type,
        due: plusDays(done ?? plantedDay, task.everyDays),
        note: task.note,
      ),
    );
  }

  return [
    for (final j in jobs)
      if (!j.due.isAfter(windowEnd)) j,
  ]..sort((a, b) => a.due.compareTo(b.due));
}