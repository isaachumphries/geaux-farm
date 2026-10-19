import '../../catalog/domain/plant.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/domain/availability.dart';
import '../../onboarding/domain/space.dart';
import '../../weather/domain/weather.dart';
import 'care_event.dart';
import 'care_tasks.dart';
import 'schedule_math.dart';
import 'slot.dart';
import 'stage.dart';
import 'water_due.dart';

/// The care list shows tasks due today through this many days ahead.
const _taskWindowDays = 7;

/// What a scheduled task asks the user to do.
enum CareTaskKind { water, fertilize, prune, harvest, other }

/// One care task on one planting, with the free-time slot it goes in.
class ScheduledCareTask {
  const ScheduledCareTask({
    required this.plantingId,
    required this.nickname,
    required this.kind,
    required this.due,
    required this.slot,
    required this.overdue,
    this.note,
  });

  final String plantingId;
  final String nickname;
  final CareTaskKind kind;

  /// Local day the task is due.
  final DateTime due;
  final CareSlot slot;

  /// True when [due] is before today.
  final bool overdue;
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledCareTask &&
          other.plantingId == plantingId &&
          other.nickname == nickname &&
          other.kind == kind &&
          other.due == due &&
          other.slot == slot &&
          other.overdue == overdue &&
          other.note == note;

  @override
  int get hashCode =>
      Object.hash(plantingId, nickname, kind, due, slot, overdue, note);

  @override
  String toString() =>
      'ScheduledCareTask($plantingId, $kind, due $due, $slot, '
      'overdue: $overdue)';
}

/// The care list for [today] (local midnight). [now] is the moment used to
/// skip free blocks that already started.
///
/// Only active plantings with a planting date contribute. Water comes from
/// [waterDue] when the plant has a water need. Catalog tasks come from
/// [planCareTask], gated by [showsCareTask]. Tasks due after today + 6 are
/// left out. Overdue tasks stay in and are flagged. Sorted by slot start,
/// then nickname.
List<ScheduledCareTask> buildCareSchedule({
  required DateTime today,
  required DateTime now,
  required List<Planting> plantings,
  required Map<String, Plant> plantsById,
  required Map<String, Space> spacesById,
  required List<CareEvent> events,
  required Availability availability,
  required Map<DateTime, WeatherDay> days,
}) {
  final todayDay = dayOf(today);
  final windowEnd = addDays(todayDay, _taskWindowDays - 1);
  final tasks = <ScheduledCareTask>[];

  for (final pl in plantings) {
    if (pl.status != PlantingStatus.active || pl.plantedOn == null) continue;
    final p = plantsById[pl.plantId];
    if (p == null) {
      throw StateError('No catalog plant ${pl.plantId} for planting ${pl.id}');
    }
    final space = spacesById[pl.spaceId];
    if (space == null) {
      throw StateError('No space ${pl.spaceId} for planting ${pl.id}');
    }

    void add(CareTaskKind kind, DateTime due, String? note) {
      if (due.isAfter(windowEnd)) return;
      tasks.add(
        ScheduledCareTask(
          plantingId: pl.id,
          nickname: pl.nickname,
          kind: kind,
          due: due,
          slot: findSlot(due, availability, now),
          overdue: due.isBefore(todayDay),
          note: note,
        ),
      );
    }

    if (p.water != null) {
      add(
        CareTaskKind.water,
        waterDue(pl, p, space, events, days, todayDay),
        null,
      );
    }
    final progress = stageOf(pl, p, todayDay).progress;
    for (final task in p.care.tasks) {
      if (!showsCareTask(task, progress)) continue;
      final planned = planCareTask(pl, task, events);
      add(_kindOf(planned.kind), planned.due, planned.note);
    }
  }

  tasks.sort((a, b) {
    final bySlot = a.slot.start.compareTo(b.slot.start);
    return bySlot != 0 ? bySlot : a.nickname.compareTo(b.nickname);
  });
  return tasks;
}

CareTaskKind _kindOf(TaskType type) => switch (type) {
  TaskType.fertilize => CareTaskKind.fertilize,
  TaskType.prune => CareTaskKind.prune,
  TaskType.harvest => CareTaskKind.harvest,
  TaskType.other => CareTaskKind.other,
};
