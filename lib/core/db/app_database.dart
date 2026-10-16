import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/care/domain/care_event.dart';
import '../../features/climate/domain/climate_profile.dart';
import '../../features/garden/domain/planting.dart';
import '../../features/onboarding/domain/availability.dart';
import '../../features/onboarding/domain/space.dart';
import '../../features/onboarding/domain/user_profile.dart';
import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The device-local database (plan/09 § Drift schema). Nothing here syncs
/// to Supabase.
@DriftDatabase(
  tables: [
    UserProfileTable,
    SpacesTable,
    ClimateMonthsTable,
    ClimateMetaTable,
    WeatherDaysTable,
    WeatherCurrentTable,
    PlantingsTable,
    CareEventsTable,
    GuideProjectsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database file. On the web, drift runs SQLite from
  /// `web/sqlite3.wasm` in `web/drift_worker.js`; both must match the
  /// locked `sqlite3` and `drift` versions.
  AppDatabase.open()
    : super(
        driftDatabase(
          name: 'geaux_farm',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  // Every schema change bumps this and adds a step to [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // SQLite leaves foreign keys off per connection; the care_events
    // cascade needs them on.
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

/// The app's single [AppDatabase]. Tests override it with an in-memory
/// database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
