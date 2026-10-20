import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/garden/data/plantings_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';

import '../../helpers/in_memory_database.dart';

// The table-backed stream providers re-emit on every insert, update and
// delete, so screens follow the device-local data (plan/09 § Drift schema).
// First emissions and column mapping are in profile_providers_test.dart.
void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    container = ProviderContainer(overrides: [inMemoryDatabaseOverride()]);
    addTearDown(container.dispose);
    db = container.read(appDatabaseProvider);
  });

  /// Keeps [provider] listened to and returns a reader for its latest value
  /// once drift's re-query has landed.
  Future<T> Function() follow<T>(StreamProvider<T> provider) {
    container.listen(provider, (_, _) {});
    return () async {
      await pumpEventQueue();
      return container.read(provider).requireValue;
    };
  }

  SpacesTableCompanion space(String id, {bool primary = false}) =>
      SpacesTableCompanion.insert(
        id: id,
        type: SpaceType.balcony,
        areaSqFt: 20,
        sun: SunLevel.partial,
        sunUnsure: false,
        rainExposed: true,
        inContainerDefault: true,
        isPrimary: primary,
      );

  Future<void> insertPlanting(String id) => db
      .into(db.plantingsTable)
      .insert(
        PlantingsTableCompanion.insert(
          id: id,
          plantId: 'basil',
          spaceId: 's1',
          nickname: id,
          setup: GrowSetup.outdoor,
          inContainer: true,
          startMethod: 'seed',
          status: PlantingStatus.planned,
          createdAt: DateTime(2026, 10, 1),
        ),
      );

  test('spacesProvider follows insert, update and delete', () async {
    final spaces = follow(spacesProvider);
    expect(await spaces(), isEmpty);

    await db.into(db.spacesTable).insert(space('s1'));
    await db.into(db.spacesTable).insert(space('s2'));
    expect((await spaces()).map((s) => s.id), unorderedEquals(['s1', 's2']));

    await (db.update(db.spacesTable)..where((t) => t.id.equals('s2'))).write(
      const SpacesTableCompanion(areaSqFt: Value(400)),
    );
    expect((await spaces()).firstWhere((s) => s.id == 's2').areaSqFt, 400);

    await (db.delete(db.spacesTable)..where((t) => t.id.equals('s1'))).go();
    expect((await spaces()).map((s) => s.id), ['s2']);
  });

  test('primarySpaceProvider moves with is_primary', () async {
    final primary = follow(primarySpaceProvider);
    await db.into(db.spacesTable).insert(space('s1', primary: true));
    await db.into(db.spacesTable).insert(space('s2'));
    expect((await primary()).id, 's1');

    await db.transaction(() async {
      await db
          .update(db.spacesTable)
          .write(const SpacesTableCompanion(isPrimary: Value(false)));
      await (db.update(db.spacesTable)..where((t) => t.id.equals('s2'))).write(
        const SpacesTableCompanion(isPrimary: Value(true)),
      );
    });
    expect((await primary()).id, 's2');

    await db.delete(db.spacesTable).go();
    expect(await primary(), same(defaultSpace));
  });

  test('userProfileProvider follows update and falls back on delete', () async {
    final profile = follow(userProfileProvider);
    await db
        .into(db.userProfileTable)
        .insert(
          UserProfileTableCompanion.insert(
            id: const Value(1),
            city: 'Baton Rouge',
            admin1: 'Louisiana',
            countryCode: 'US',
            lat: 30.45,
            lon: -91.19,
            timezone: 'America/Chicago',
            goals: const [Goal.food],
            experience: Experience.beginner,
            availability: const Availability([0, 0, 0, 0, 0, 0, 2]),
            units: 'imperial',
          ),
        );
    expect((await profile()).notificationsEnabled, isTrue);

    await db
        .update(db.userProfileTable)
        .write(
          const UserProfileTableCompanion(notificationsEnabled: Value(false)),
        );
    expect((await profile()).notificationsEnabled, isFalse);

    await db.delete(db.userProfileTable).go();
    expect(await profile(), same(defaultUserProfile));
  });

  test('plantingsProvider follows a status change and a delete', () async {
    final plantings = follow(plantingsProvider);
    await insertPlanting('p1');
    await insertPlanting('p2');
    expect((await plantings()).map((p) => p.id), ['p1', 'p2']);

    await (db.update(db.plantingsTable)..where((t) => t.id.equals('p1'))).write(
      const PlantingsTableCompanion(status: Value(PlantingStatus.harvested)),
    );
    expect((await plantings()).first.status, PlantingStatus.harvested);

    await (db.delete(db.plantingsTable)..where((t) => t.id.equals('p2'))).go();
    expect((await plantings()).map((p) => p.id), ['p1']);
  });

  test('careEventsProvider re-emits when a planting delete cascades', () async {
    // plan/09: care_events.planting_id cascades. The delete only touches
    // `plantings`, so the events stream must still learn about it.
    final events = follow(careEventsProvider);
    await insertPlanting('p1');
    await insertPlanting('p2');
    for (final (id, planting) in [('e1', 'p1'), ('e2', 'p2')]) {
      await db
          .into(db.careEventsTable)
          .insert(
            CareEventsTableCompanion.insert(
              id: id,
              plantingId: planting,
              type: CareEventType.water,
              at: DateTime(2026, 10, 2),
            ),
          );
    }
    expect(
      (await events()).map((e) => e.plantingId),
      unorderedEquals(['p1', 'p2']),
    );

    await (db.delete(db.plantingsTable)..where((t) => t.id.equals('p1'))).go();
    expect((await events()).map((e) => e.plantingId), ['p2']);
  });
}
