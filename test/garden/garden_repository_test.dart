import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/data/garden_repository.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';

import '../recommendations/fixtures/baton_rouge.dart';
import 'garden_harness.dart';

void main() {
  late AppDatabase db;
  late GardenRepository repo;
  final kale = Plant.fromJson(rawKale());

  setUp(() async {
    db = openGardenDb();
    await seedSpace(db);
    repo = GardenRepository(db, now: () => gardenNow, random: Random(7));
  });

  Future<PlantingRow> addKale({
    String nickname = '',
    DateTime? plantedOn,
  }) async {
    final id = await repo.addPlanting(
      plant: kale,
      spaceId: 's1',
      nickname: nickname,
      setup: GrowSetup.outdoor,
      inContainer: true,
      startMethod: StartMethod.seed,
      plantedOn: plantedOn ?? DateTime(2026, 10, 1),
    );
    return (db.select(
      db.plantingsTable,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  group('addPlanting (PD-02 "Add to my garden")', () {
    test('inserts an active planting with the chosen setup', () async {
      final row = await addKale(nickname: 'Big Kale');
      expect(row.plantId, 'kale');
      expect(row.spaceId, 's1');
      expect(row.nickname, 'Big Kale');
      expect(row.setup, GrowSetup.outdoor);
      expect(row.inContainer, isTrue);
      expect(row.startMethod, 'seed');
      expect(row.plantedOn, DateTime(2026, 10, 1));
      expect(row.status, PlantingStatus.active);
      expect(row.createdAt, gardenNow);
      expect(row.projectId, isNull);
    });

    test('a blank nickname falls back to the common name', () async {
      expect((await addKale(nickname: '')).nickname, 'Kale');
      expect((await addKale(nickname: '   ')).nickname, 'Kale');
    });

    test('a nickname is trimmed', () async {
      expect((await addKale(nickname: '  Greenie ')).nickname, 'Greenie');
    });

    test('returns a v4 UUID, a new one each time', () async {
      final a = await addKale();
      final b = await addKale();
      final v4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(a.id, matches(v4));
      expect(b.id, matches(v4));
      expect(a.id, isNot(b.id));
    });
  });

  group('logCare', () {
    late String id;
    setUp(() async => id = (await addKale()).id);

    Future<List<CareEventRow>> events() => db.select(db.careEventsTable).get();

    test('records the type against the planting at the current time', () async {
      await repo.logCare(id, CareEventType.water);
      final e = (await events()).single;
      expect(e.plantingId, id);
      expect(e.type, CareEventType.water);
      expect(e.at, gardenNow);
      expect(e.note, isNull);
    });

    test('skip is stored as skip_water', () async {
      await repo.logCare(id, CareEventType.skipWater);
      final raw = await db
          .customSelect('SELECT type FROM care_events')
          .getSingle();
      expect(raw.read<String>('type'), 'skip_water');
    });

    test('a note is trimmed and kept', () async {
      await repo.logCare(id, CareEventType.note, note: '  New leaves!  ');
      expect((await events()).single.note, 'New leaves!');
    });

    test('a blank note is stored as no note', () async {
      await repo.logCare(id, CareEventType.note, note: '   ');
      expect((await events()).single.note, isNull);
    });

    test('each event gets its own id', () async {
      await repo.logCare(id, CareEventType.water);
      await repo.logCare(id, CareEventType.water);
      final ids = (await events()).map((e) => e.id).toSet();
      expect(ids, hasLength(2));
    });
  });

  group('setStatus', () {
    test('changes the status and keeps the row and its care log', () async {
      final id = (await addKale()).id;
      await repo.logCare(id, CareEventType.water);
      await repo.setStatus(id, PlantingStatus.harvested);
      var rows = await db.select(db.plantingsTable).get();
      expect(rows.single.status, PlantingStatus.harvested);
      expect(rows.single.nickname, 'Kale');

      await repo.setStatus(id, PlantingStatus.removed);
      rows = await db.select(db.plantingsTable).get();
      expect(rows.single.status, PlantingStatus.removed);
      expect(await db.select(db.careEventsTable).get(), hasLength(1));
    });

    test('touches only the named planting', () async {
      final a = (await addKale()).id;
      final b = (await addKale()).id;
      await repo.setStatus(a, PlantingStatus.removed);
      final byId = {
        for (final r in await db.select(db.plantingsTable).get())
          r.id: r.status,
      };
      expect(byId[a], PlantingStatus.removed);
      expect(byId[b], PlantingStatus.active);
    });
  });
}
