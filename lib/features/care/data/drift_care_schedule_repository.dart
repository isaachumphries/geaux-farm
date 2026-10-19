import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../domain/care_event.dart';
import '../domain/care_schedule_repository.dart';

final careScheduleRepositoryProvider = Provider<CareScheduleRepository>(
  (ref) => DriftCareScheduleRepository(ref.watch(appDatabaseProvider)),
);

/// Drift-backed [CareScheduleRepository] over the `care_events` table.
class DriftCareScheduleRepository implements CareScheduleRepository {
  DriftCareScheduleRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<CareEvent>> watchCareEvents() => _db
      .select(_db.careEventsTable)
      .watch()
      .map((rows) => rows.map(_careEvent).toList());
}

CareEvent _careEvent(CareEventRow r) => CareEvent(
  id: r.id,
  plantingId: r.plantingId,
  type: r.type,
  at: r.at,
  note: r.note,
  photoPath: r.photoPath,
);
