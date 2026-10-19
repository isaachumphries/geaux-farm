import '../../garden/domain/planting.dart';
import '../../onboarding/domain/availability.dart';
import '../../onboarding/domain/space.dart';
import 'care_event.dart';

/// Read side of the care schedule: the rows [buildCareSchedule] needs.
/// Drift-backed in the app (`data/`), an in-memory fake in tests. Availability
/// editing and the full care repository belong to #33, which may extend or
/// replace this interface.
abstract interface class CareScheduleRepository {
  Stream<List<Planting>> watchPlantings();

  Stream<List<Space>> watchSpaces();

  Stream<List<CareEvent>> watchCareEvents();

  Stream<Availability> watchAvailability();

  /// `(lat, lon)` from the user profile; weather is fetched for this place.
  Stream<(double lat, double lon)> watchLocation();
}
