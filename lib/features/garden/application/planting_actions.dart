import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../care/application/care_schedule_provider.dart';
import '../../care/domain/care_event.dart';
import '../data/garden_repository.dart';
import '../domain/planting.dart';

/// The GD-01 and GD-02 actions (#30). Each one writes through
/// [GardenRepository] and then calls the recompute hook exactly once, the
/// same hook PD-02's "Add to my garden" uses.
///
/// Every action except [remove] and [startPlanting] logs exactly one
/// `care_events` row, at the current time.
class PlantingActions {
  PlantingActions(this._repository, this._recompute);

  final GardenRepository _repository;
  final void Function() _recompute;

  /// "Water": logs `water`.
  Future<void> water(String plantingId) =>
      logTask(plantingId, CareEventType.water);

  /// "Skip": logs `skip_water`, which resets the deficit the way water does.
  Future<void> skip(String plantingId) =>
      logTask(plantingId, CareEventType.skipWater);

  /// Logs one event of [type], e.g. a fertilize, prune, or harvest button,
  /// or an upcoming task marked done. [note] names a catalog `other` task.
  Future<void> logTask(
    String plantingId,
    CareEventType type, {
    String? note,
  }) async {
    await _repository.logCare(plantingId, type, note: note);
    _recompute();
  }

  /// "Add note": logs a `note` event with [text]. Blank text is refused.
  Future<void> addNote(String plantingId, String text) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'is blank');
    }
    return logTask(plantingId, CareEventType.note, note: text);
  }

  /// GD-01 "Start planting": planted today and active, with no care event.
  Future<void> startPlanting(String plantingId) async {
    await _repository.startPlanting(plantingId);
    _recompute();
  }

  /// "Mark harvested": one `harvest` event and status harvested.
  Future<void> markHarvested(String plantingId) async {
    await _repository.markHarvested(plantingId);
    _recompute();
  }

  /// "Remove": status removed. The plan has no care event for removal.
  Future<void> remove(String plantingId) async {
    await _repository.setStatus(plantingId, PlantingStatus.removed);
    _recompute();
  }
}

/// The recompute rebuilds `careScheduleProvider`. The reminder sync (#21)
/// listens to it and reschedules from the fresh tasks.
final plantingActionsProvider = Provider<PlantingActions>(
  (ref) => PlantingActions(
    ref.watch(gardenRepositoryProvider),
    () => ref.invalidate(careScheduleProvider),
  ),
);
