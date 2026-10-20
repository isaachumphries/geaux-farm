import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../care/domain/care_event.dart';
import '../../catalog/domain/plant.dart';
import '../../recommendations/application/clock_provider.dart';
import '../domain/planting.dart';

/// Writes to My Garden: new plantings (PD-02 "Add to my garden"), care
/// logged from GD-02, and status changes (harvested, removed).
class GardenRepository {
  GardenRepository(this._db, {required this.now, Random? random})
      : _random = random ?? Random.secure();

  final AppDatabase _db;
  final DateTime Function() now;
  final Random _random;

  /// Adds an active planting and returns its id. A blank [nickname] falls
  /// back to the plant's common name.
  Future<String> addPlanting({
    required Plant plant,
    required String spaceId,
    required String nickname,
    required GrowSetup setup,
    required bool inContainer,
    required StartMethod startMethod,
    required DateTime plantedOn,
  }) async {
    final id = _uuidV4();
    final name = nickname.trim();
    await _db
        .into(_db.plantingsTable)
        .insert(
      PlantingsTableCompanion.insert(
        id: id,
        plantId: plant.id,
        spaceId: spaceId,
        nickname: name.isEmpty ? plant.commonName : name,
        setup: setup,
        inContainer: inContainer,
        startMethod: startMethod.json,
        plantedOn: Value(plantedOn),
        status: PlantingStatus.active,
        createdAt: now(),
      ),
    );
    return id;
  }

  /// Logs [type] against [plantingId] at the current time.
  Future<void> logCare(String plantingId, CareEventType type, {String? note}) {
    final text = note?.trim();
    return _db
        .into(_db.careEventsTable)
        .insert(
      CareEventsTableCompanion.insert(
        id: _uuidV4(),
        plantingId: plantingId,
        type: type,
        at: now(),
        note: Value(text == null || text.isEmpty ? null : text),
      ),
    );
  }

  /// Moves a planting to [status], e.g. harvested or removed. Rows are
  /// kept so the care log survives.
  Future<void> setStatus(String plantingId, PlantingStatus status) async {
    final query = _db.update(_db.plantingsTable)
      ..where((t) => t.id.equals(plantingId));
    await query.write(PlantingsTableCompanion(status: Value(status)));
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

final gardenRepositoryProvider = Provider<GardenRepository>(
      (ref) => GardenRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  ),
);