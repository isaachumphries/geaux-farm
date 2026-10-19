import 'care_event.dart';

/// Read side of the care schedule's own table: care events. Planting, space,
/// availability, and location reads come from the shared providers in
/// `garden/` and `onboarding/`, not from this interface.
abstract interface class CareScheduleRepository {
  Stream<List<CareEvent>> watchCareEvents();
}
