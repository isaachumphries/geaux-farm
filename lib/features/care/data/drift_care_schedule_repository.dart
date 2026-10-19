import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/data/default_profile.dart';
import '../../onboarding/domain/availability.dart';
import '../../onboarding/domain/space.dart';
import '../domain/care_event.dart';
import '../domain/care_schedule_repository.dart';

final careScheduleRepositoryProvider = Provider<CareScheduleRepository>(
  (ref) => DriftCareScheduleRepository(ref.watch(appDatabaseProvider)),
);

/// Drift-backed [CareScheduleRepository]. The row mappers mirror the garden
/// and onboarding providers; #33 should reconcile them with its repository.
class DriftCareScheduleRepository implements CareScheduleRepository {
  DriftCareScheduleRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Planting>> watchPlantings() {
    final query = _db.select(_db.plantingsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_planting).toList());
  }

  @override
  Stream<List<Space>> watchSpaces() => _db
      .select(_db.spacesTable)
      .watch()
      .map((rows) => rows.map(_space).toList());

  @override
  Stream<List<CareEvent>> watchCareEvents() => _db
      .select(_db.careEventsTable)
      .watch()
      .map((rows) => rows.map(_careEvent).toList());

  @override
  Stream<Availability> watchAvailability() => _profileRow().map(
    (row) => row?.availability ?? defaultUserProfile.availability,
  );

  @override
  Stream<(double lat, double lon)> watchLocation() => _profileRow().map(
    (row) => row == null
        ? (defaultUserProfile.lat, defaultUserProfile.lon)
        : (row.lat, row.lon),
  );

  /// The `user_profile` row (id 1), or null until onboarding saves one.
  Stream<UserProfileRow?> _profileRow() {
    final query = _db.select(_db.userProfileTable)
      ..where((t) => t.id.equals(1));
    return query.watchSingleOrNull();
  }
}

Planting _planting(PlantingRow r) => Planting(
  id: r.id,
  plantId: r.plantId,
  spaceId: r.spaceId,
  nickname: r.nickname,
  setup: r.setup,
  inContainer: r.inContainer,
  startMethod: r.startMethod,
  plantedOn: r.plantedOn,
  status: r.status,
  projectId: r.projectId,
  createdAt: r.createdAt,
);

Space _space(SpaceRow r) => Space(
  id: r.id,
  type: r.type,
  areaSqFt: r.areaSqFt,
  sun: r.sun,
  sunUnsure: r.sunUnsure,
  rainExposed: r.rainExposed,
  inContainerDefault: r.inContainerDefault,
  isPrimary: r.isPrimary,
);

CareEvent _careEvent(CareEventRow r) => CareEvent(
  id: r.id,
  plantingId: r.plantingId,
  type: r.type,
  at: r.at,
  note: r.note,
  photoPath: r.photoPath,
);
