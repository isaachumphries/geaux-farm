import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';

// Keys, defaults, foreign keys and enum storage from plan/09 § Drift schema.
// Column names and nullability are pinned in app_database_test.dart.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<QueryRow>> tableInfo(String table) =>
      db.customSelect('PRAGMA table_info($table)').get();

  Future<List<String>> raw(String sql) async => [
    for (final row in await db.customSelect(sql).get())
      row.data.values.single as String,
  ];

  Future<void> insertPlanting(
    String id, {
    GrowSetup setup = GrowSetup.outdoor,
    PlantingStatus status = PlantingStatus.active,
  }) => db
      .into(db.plantingsTable)
      .insert(
        PlantingsTableCompanion.insert(
          id: id,
          plantId: 'kale',
          spaceId: 'space-1',
          nickname: 'Kale',
          setup: setup,
          inContainer: false,
          startMethod: 'seed',
          status: status,
          createdAt: DateTime(2026, 10, 1),
        ),
      );

  Future<void> insertSpace(String id, SpaceType type, SunLevel sun) => db
      .into(db.spacesTable)
      .insert(
        SpacesTableCompanion.insert(
          id: id,
          type: type,
          areaSqFt: 10,
          sun: sun,
          sunUnsure: false,
          rainExposed: true,
          inContainerDefault: false,
          isPrimary: false,
        ),
      );

  UserProfileTableCompanion profile({
    String city = 'Baton Rouge',
    Experience experience = Experience.beginner,
    HeardFrom? heardFrom,
  }) => UserProfileTableCompanion.insert(
    id: const Value(1),
    city: city,
    admin1: 'Louisiana',
    countryCode: 'US',
    lat: 30.45,
    lon: -91.19,
    timezone: 'America/Chicago',
    goals: const [Goal.food],
    experience: experience,
    heardFrom: Value(heardFrom),
    availability: const Availability([0, 0, 0, 0, 0, 0, 2]),
    units: 'imperial',
  );

  group('primary keys', () {
    test('each table is keyed on its plan/09 key column', () async {
      const keys = {
        'user_profile': {'id'},
        'spaces': {'id'},
        'climate_months': {'month'},
        'climate_meta': {'id'},
        'weather_days': {'date'},
        'weather_current': {'id'},
        'plantings': {'id'},
        'care_events': {'id'},
        'guide_projects': {'id'},
      };
      for (final MapEntry(key: table, value: expected) in keys.entries) {
        final pk = {
          for (final c in await tableInfo(table))
            if (c.read<int>('pk') > 0) c.read<String>('name'),
        };
        expect(pk, expected, reason: table);
      }
    });

    test('a second planting with the same id is rejected', () async {
      await insertPlanting('p1');
      await expectLater(insertPlanting('p1'), throwsA(isA<SqliteException>()));
      expect(await db.select(db.plantingsTable).get(), hasLength(1));
    });

    test('upserting the singleton profile row replaces it', () async {
      // profile_writer saves onboarding with insertOnConflictUpdate on id 1.
      await db.into(db.userProfileTable).insertOnConflictUpdate(profile());
      await db
          .into(db.userProfileTable)
          .insertOnConflictUpdate(profile(city: 'Lafayette'));
      final rows = await db.select(db.userProfileTable).get();
      expect(rows.map((r) => (r.id, r.city)), [(1, 'Lafayette')]);
    });
  });

  test('only the three user_profile flags carry plan/09 defaults', () async {
    const defaults = {
      'user_profile': {
        'notifications_enabled': '1',
        'notification_permission_asked': '0',
        'first_plant_prompt_dismissed': '0',
      },
    };
    for (final table in db.allTables.map((t) => t.actualTableName)) {
      final actual = {
        for (final c in await tableInfo(table))
          if (c.read<String?>('dflt_value') case final String v)
            c.read<String>('name'): v,
      };
      expect(actual, defaults[table] ?? isEmpty, reason: table);
    }
  });

  group('care_events.planting_id foreign key', () {
    test('rejects an event for a planting that does not exist', () async {
      await expectLater(
        db
            .into(db.careEventsTable)
            .insert(
              CareEventsTableCompanion.insert(
                id: 'e1',
                plantingId: 'missing',
                type: CareEventType.water,
                at: DateTime(2026, 10, 2),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
      expect(await db.select(db.careEventsTable).get(), isEmpty);
    });
  });

  group('enum columns store the Dart enum name', () {
    test('spaces.type and spaces.sun', () async {
      for (final type in SpaceType.values) {
        await insertSpace(type.name, type, SunLevel.values[type.index % 3]);
      }
      expect(
        await raw('SELECT type FROM spaces ORDER BY rowid'),
        SpaceType.values.map((t) => t.name),
      );
      expect(await raw('SELECT sun FROM spaces ORDER BY rowid'), [
        'shade',
        'partial',
        'full',
        'shade',
        'partial',
      ]);
      final rows = await db.select(db.spacesTable).get();
      expect(rows.map((r) => r.type), SpaceType.values);
    });

    test('plantings.setup and plantings.status', () async {
      for (final status in PlantingStatus.values) {
        await insertPlanting(
          status.name,
          setup: GrowSetup.values[status.index % 3],
          status: status,
        );
      }
      expect(
        await raw('SELECT status FROM plantings ORDER BY rowid'),
        PlantingStatus.values.map((s) => s.name),
      );
      expect(await raw('SELECT setup FROM plantings ORDER BY rowid'), [
        'outdoor',
        'indoor',
        'greenhouse',
        'outdoor',
      ]);
      final rows = await db.select(db.plantingsTable).get();
      expect(rows.map((r) => r.status), PlantingStatus.values);
    });

    test('user_profile.experience and heard_from', () async {
      await db
          .into(db.userProfileTable)
          .insert(
            profile(
              experience: Experience.intermediate,
              heardFrom: HeardFrom.friendFamily,
            ),
          );
      expect(await raw('SELECT experience FROM user_profile'), [
        'intermediate',
      ]);
      expect(await raw('SELECT heard_from FROM user_profile'), [
        'friendFamily',
      ]);
    });

    test('climate_meta.zone_source', () async {
      await db
          .into(db.climateMetaTable)
          .insert(
            ClimateMetaTableCompanion.insert(
              id: const Value(1),
              annualExtremeMinF: 22.1,
              annualPrecipIn: 60.2,
              annualRhPct: 74,
              zone: '9a',
              zoneSource: ZoneSource.computed,
              lat: 30.45,
              lon: -91.19,
              computedAt: DateTime(2026, 10, 1),
            ),
          );
      expect(await raw('SELECT zone_source FROM climate_meta'), ['computed']);
    });
  });
}
