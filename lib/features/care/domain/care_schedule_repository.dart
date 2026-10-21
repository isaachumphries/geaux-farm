import 'care_event.dart';

/// The care schedule's own table: care events. Planting, space,
/// availability, and location reads come from the shared providers in
/// `garden/` and `onboarding/`, not from this interface.
abstract interface class CareScheduleRepository {
  Stream<List<CareEvent>> watchCareEvents();

  /// Appends a care event for [plantingId] at [at]. The next read of
  /// [watchCareEvents] includes it, so the schedule recomputes from it.
  Future<void> logCareEvent({
    required String plantingId,
    required CareEventType type,
    required DateTime at,
    String? note,
  });
}
