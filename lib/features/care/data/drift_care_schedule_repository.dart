import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../domain/care_event.dart';
import '../domain/care_schedule_repository.dart';

final careScheduleRepositoryProvider = Provider<CareScheduleRepository>(
  (ref) => DriftCareScheduleRepository(ref.watch(appDatabaseProvider)),
);

/// Drift-backed [CareScheduleRepository] over the `care_events` table.
class DriftCareScheduleRepository implements CareScheduleRepository {
  DriftCareScheduleRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final Random _random;

  @override
  Stream<List<CareEvent>> watchCareEvents() => _db
      .select(_db.careEventsTable)
      .watch()
      .map((rows) => rows.map(_careEvent).toList());

  @override
  Future<void> logCareEvent({
    required String plantingId,
    required CareEventType type,
    required DateTime at,
    String? note,
  }) async {
    await _db
        .into(_db.careEventsTable)
        .insert(
          CareEventsTableCompanion.insert(
            id: _uuidV4(),
            plantingId: plantingId,
            type: type,
            at: at,
            note: Value(note),
          ),
        );
  }

  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

CareEvent _careEvent(CareEventRow r) => CareEvent(
  id: r.id,
  plantingId: r.plantingId,
  type: r.type,
  at: r.at,
  note: r.note,
  photoPath: r.photoPath,
);
