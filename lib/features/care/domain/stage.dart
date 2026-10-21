import '../../catalog/domain/plant.dart';
import '../../garden/domain/planting.dart';
import 'schedule_math.dart';

/// Stage label shown on a planting card. Derived on read, never stored.
enum PlantingStage {
  sprouting('Sprouting'),
  growing('Growing'),
  readyToHarvest('Ready to harvest'),
  blooming('Blooming'),
  established('Established');

  const PlantingStage(this.label);

  final String label;
}

class StageReading {
  const StageReading({
    required this.stage,
    required this.progress,
    required this.showsProgressRing,
  });

  final PlantingStage stage;

  /// Share of the catalog's days-to-maturity elapsed, 0 to 1.
  final double progress;
  final bool showsProgressRing;
}

const _sproutingDays = 10;

/// Stage for [pl] on [today]. Seeds show Sprouting for their first
/// [_sproutingDays] days. After that, the stage follows [progress] until
/// the planting reaches maturity, then follows the plant's maturity kind.
StageReading stageOf(Planting pl, Plant p, DateTime today) {
  final planted = pl.plantedOn;
  if (planted == null) {
    throw StateError('Planting ${pl.id} has no plantedOn date');
  }
  final daysSince = daysBetween(dayOf(planted), dayOf(today));
  final progress = _progressFor(p, pl.startMethod, daysSince);
  return StageReading(
    stage: _stageFor(pl, p, daysSince, progress),
    progress: progress,
    showsProgressRing: p.maturityKind != MaturityKind.foliage,
  );
}

PlantingStage _stageFor(Planting pl, Plant p, int daysSince, double progress) {
  if (pl.startMethod == StartMethod.seed.json && daysSince < _sproutingDays) {
    return PlantingStage.sprouting;
  }
  if (progress < 1) return PlantingStage.growing;
  return switch (p.maturityKind) {
    MaturityKind.harvest => PlantingStage.readyToHarvest,
    MaturityKind.bloom => PlantingStage.blooming,
    MaturityKind.establish => PlantingStage.established,
    MaturityKind.foliage => PlantingStage.growing,
  };
}

double _progressFor(Plant p, String startMethod, int daysSince) {
  final start = _startFor(p, startMethod);
  if (start == null) return 0;
  if (start.daysMin <= 0) return 1;
  return (daysSince / start.daysMin).clamp(0.0, 1.0);
}

/// The catalog start entry matching [startMethod], falling back to the
/// first entry. Null when the plant lists no starts.
PlantStart? _startFor(Plant p, String startMethod) {
  final starts = p.starts;
  if (starts == null || starts.isEmpty) return null;
  for (final s in starts) {
    if (s.method.json == startMethod) return s;
  }
  return starts.first;
}
