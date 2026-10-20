import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/data/drift_care_schedule_repository.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
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

  test('maps care events from the database', () async {
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

    final events = await repo.watchCareEvents().first;
    expect(events.single.type, CareEventType.water);
  });

  test('logCareEvent stores one event the stream then emits', () async {
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
    final at = DateTime(2026, 10, 5, 9, 30);

    await repo.logCareEvent(
      plantingId: 'p1',
      type: CareEventType.fertilize,
      at: at,
    );
    await repo.logCareEvent(
      plantingId: 'p1',
      type: CareEventType.note,
      at: at,
      note: 'Check',
    );

    final events = await repo.watchCareEvents().first;
    expect(events, hasLength(2));
    final fertilize = events.firstWhere(
      (e) => e.type == CareEventType.fertilize,
    );
    expect(fertilize.plantingId, 'p1');
    expect(fertilize.at, at);
    expect(fertilize.note, isNull);
    expect(
      events.firstWhere((e) => e.type == CareEventType.note).note,
      'Check',
    );
    expect(events.map((e) => e.id).toSet(), hasLength(2));
    expect(
      events.first.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
