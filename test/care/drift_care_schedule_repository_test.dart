import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/data/drift_care_schedule_repository.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';

import '../helpers/care_fixtures.dart';

void main() {
  late AppDatabase db;
  late DriftCareScheduleRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftCareScheduleRepository(db);
  });

  tearDown(() async => db.close());

  test('maps plantings, spaces, and care events from the database', () async {
    await db
        .into(db.spacesTable)
        .insert(
          SpacesTableCompanion.insert(
            id: 's1',
            type: SpaceType.balcony,
            areaSqFt: 10,
            sun: SunLevel.full,
            sunUnsure: false,
            rainExposed: true,
            inContainerDefault: true,
            isPrimary: true,
          ),
        );
    await db
        .into(db.plantingsTable)
        .insert(
          PlantingsTableCompanion.insert(
            id: 'p1',
            plantId: 'kale',
            spaceId: 's1',
            nickname: 'Kale',
            setup: GrowSetup.outdoor,
            inContainer: true,
            startMethod: 'transplant',
            plantedOn: Value(carePlanted),
            status: PlantingStatus.active,
            createdAt: carePlanted,
          ),
        );
    await db
        .into(db.careEventsTable)
        .insert(
          CareEventsTableCompanion.insert(
            id: 'e1',
            plantingId: 'p1',
            type: CareEventType.water,
            at: carePlanted,
          ),
        );

    final spaces = await repo.watchSpaces().first;
    expect(spaces.single.id, 's1');
    expect(spaces.single.sun, SunLevel.full);

    final plantings = await repo.watchPlantings().first;
    expect(plantings.single.nickname, 'Kale');
    expect(plantings.single.plantedOn, carePlanted);

    final events = await repo.watchCareEvents().first;
    expect(events.single.type, CareEventType.water);
  });

  test(
    'falls back to the default profile until onboarding saves one',
    () async {
      expect(
        await repo.watchAvailability().first,
        defaultUserProfile.availability,
      );
      expect(await repo.watchLocation().first, (
        defaultUserProfile.lat,
        defaultUserProfile.lon,
      ));
    },
  );
}
