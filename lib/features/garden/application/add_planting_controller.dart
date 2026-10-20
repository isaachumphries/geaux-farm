import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../care/application/care_schedule_provider.dart';
import '../../catalog/domain/plant.dart';
import '../data/garden_repository.dart';
import 'grow_setup_controller.dart';

/// PD-02 "Add to my garden": inserts the active planting, then asks for a
/// care recompute so its first watering lands in the schedule and the
/// reminders (#21) follow.
class AddPlantingController {
  AddPlantingController(this._repository, this._recompute);

  final GardenRepository _repository;
  final void Function() _recompute;

  /// Adds [plant] as set up in [setup] and returns the new planting's id.
  /// Throws, without recomputing, when the setup has no start method or
  /// the insert fails.
  Future<String> addPlanting(Plant plant, GrowSetupState setup) async {
    final start = setup.startMethod;
    if (start == null) {
      throw StateError('${plant.id} has no start method to plant from');
    }
    final id = await _repository.addPlanting(
      plant: plant,
      spaceId: setup.spaceId,
      nickname: setup.nickname,
      setup: setup.setup,
      inContainer: setup.inContainer,
      startMethod: start,
      plantedOn: setup.plantedOn,
    );
    _recompute();
    return id;
  }
}

/// The recompute rebuilds `careScheduleProvider`. The reminder sync (#21)
/// listens to it and reschedules from the fresh tasks.
final addPlantingControllerProvider = Provider<AddPlantingController>(
  (ref) => AddPlantingController(
    ref.watch(gardenRepositoryProvider),
    () => ref.invalidate(careScheduleProvider),
  ),
);
