import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertPlanting(String id) => db
      .into(db.plantingsTable)
      .insert(
        PlantingsTableCompanion.insert(
          id: id,
          plantId: 'kale',
          spaceId: 'space-1',
          nickname: 'Kale',
          setup: GrowSetup.outdoor,
          inContainer: true,
          startMethod: 'seed',
          status: PlantingStatus.active,
          createdAt: DateTime(2026, 10, 1),
        ),
      );

  Future<void> insertEvent(String id, String plantingId, CareEventType type) =>
      db
          .into(db.careEventsTable)
          .insert(
            CareEventsTableCompanion.insert(
              id: id,
              plantingId: plantingId,
              type: type,
              at: DateTime(2026, 10, 2),
            ),
          );

  test('schemaVersion is 1', () {
    expect(db.schemaVersion, 1);
  });

  test('opens with the nine plan/09 tables', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    expect(rows.map((r) => r.read<String>('name')).toSet(), {
      'user_profile',
      'spaces',
      'climate_months',
      'climate_meta',
      'weather_days',
      'weather_current',
      'plantings',
      'care_events',
      'guide_projects',
    });
  });

  test('columns have the plan/09 names and nullability', () async {
    // Nullable columns per table; every other column is NOT NULL.
    const nullable = {
      'user_profile': {
        'postcode',
        'goal_other_text',
        'heard_from',
        'heard_other_text',
        'onboarding_completed_at',
      },
      'spaces': <String>{},
      'climate_months': <String>{},
      'climate_meta': {'last_spring_frost_doy', 'first_fall_frost_doy'},
      'weather_days': {'precip_prob', 'uv_max'},
      'weather_current': <String>{},
      'plantings': {'planted_on', 'project_id'},
      'care_events': {'note', 'photo_path'},
      'guide_projects': {'cover_url'},
    };
    const columnCounts = {
      'user_profile': 19,
      'spaces': 8,
      'climate_months': 7,
      'climate_meta': 11,
      'weather_days': 13,
      'weather_current': 3,
      'plantings': 11,
      'care_events': 6,
      'guide_projects': 7,
    };
    for (final table in nullable.keys) {
      final cols = await db.customSelect('PRAGMA table_info($table)').get();
      expect(cols, hasLength(columnCounts[table]), reason: table);
      final actualNullable = {
        for (final c in cols)
          if (c.read<int>('notnull') == 0) c.read<String>('name'),
      };
      expect(actualNullable, nullable[table], reason: table);
    }
  });

  test('foreign keys are on', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test('deleting a planting deletes its care events', () async {
    await insertPlanting('p1');
    await insertPlanting('p2');
    await insertEvent('e1', 'p1', CareEventType.water);
    await insertEvent('e2', 'p1', CareEventType.note);
    await insertEvent('e3', 'p2', CareEventType.water);

    await (db.delete(db.plantingsTable)..where((t) => t.id.equals('p1'))).go();

    final left = await db.select(db.careEventsTable).get();
    expect(left.where((e) => e.plantingId == 'p1'), isEmpty);
    expect(left.map((e) => e.id), ['e3']);
  });

  test('each CareEventType round-trips as snake_case text', () async {
    await insertPlanting('p1');
    for (final type in CareEventType.values) {
      await insertEvent('e-${type.name}', 'p1', type);
    }

    final events = await db.select(db.careEventsTable).get();
    expect(events.map((e) => e.type).toSet(), CareEventType.values.toSet());

    final stored = await db
        .customSelect('SELECT type FROM care_events ORDER BY rowid')
        .get();
    expect(stored.map((r) => r.read<String>('type')), [
      'water',
      'skip_water',
      'fertilize',
      'prune',
      'harvest',
      'note',
    ]);
  });
}
