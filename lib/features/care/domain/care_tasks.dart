import '../../catalog/domain/plant.dart';
import '../../garden/domain/planting.dart';
import 'care_event.dart';
import 'schedule_math.dart';

/// One catalog care task on one planting, with the local day it is next due.
class PlantingTask {
  const PlantingTask({
    required this.plantingId,
    required this.kind,
    required this.due,
    this.note,
  });

  final String plantingId;
  final TaskType kind;
  final DateTime due;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is PlantingTask &&
      other.plantingId == plantingId &&
      other.kind == kind &&
      other.due == due &&
      other.note == note;

  @override
  int get hashCode => Object.hash(plantingId, kind, due, note);
}

/// Next due day for [task] on [pl]. The clock restarts from the last event
/// that completes the task, or from planting day when none exists.
PlantingTask planCareTask(
  Planting pl,
  CareTask task,
  List<CareEvent> events,
) {
  final last = lastEventDay(pl.id, events, _completes(task));
  final anchor = last ?? _plantedDay(pl);
  return PlantingTask(
    plantingId: pl.id,
    kind: task.type,
    due: addDays(anchor, task.everyDays),
    note: task.note,
  );
}

/// Whether [task] belongs on the schedule at growth [progress] (0 to 1).
/// Harvest is shown only once the planting has reached maturity.
bool showsCareTask(CareTask task, double progress) =>
    task.type != TaskType.harvest || progress >= 1;

bool Function(CareEvent) _completes(CareTask task) => switch (task.type) {
  TaskType.fertilize => (e) => e.type == CareEventType.fertilize,
  TaskType.prune => (e) => e.type == CareEventType.prune,
  TaskType.harvest => (e) => e.type == CareEventType.harvest,
  TaskType.other =>
    (e) => e.type == CareEventType.note && e.note == task.note,
};

DateTime _plantedDay(Planting pl) {
  final planted = pl.plantedOn;
  if (planted == null) {
    throw StateError('Planting ${pl.id} has no plantedOn date');
  }
  return dayOf(planted);
}
