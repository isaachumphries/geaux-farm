import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/stage.dart';
import 'package:geaux_farm/features/garden/application/garden_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';

import 'garden_harness.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = openGardenDb();
    await seedSpace(db);
    container = ProviderContainer(overrides: gardenOverrides(db));
    addTearDown(container.dispose);
    // Drift streams only start once something listens to the provider.
    container.listen(gardenProvider, (_, _) {});
    container.listen(careLogProvider, (_, _) {});
  });

  Future<List<PlantingView>> garden() => container.read(gardenProvider.future);

  Future<PlantingView?> view(String id) {
    container.listen(plantingViewProvider(id), (_, _) {});
    return container.read(plantingViewProvider(id).future);
  }

  group('gardenProvider', () {
    test('is empty with no plantings', () async {
      expect(await garden(), isEmpty);
    });

    test('joins each planting with its plant, space, and growth', () async {
      await seedPlanting(
        db,
        nickname: 'Kale',
        plantedOn: DateTime(2026, 9, 17),
      );
      final v = (await garden()).single;
      expect(v.id, 'p1');
      expect(v.plant.commonName, 'Kale');
      expect(v.space?.type, SpaceType.balcony);
      expect(v.growth?.stage, PlantingStage.growing);
      expect(v.growth?.progress, closeTo(20 / 50, 1e-9));
    });

    test('lists plantings oldest first', () async {
      await seedPlanting(db, id: 'new', createdAt: DateTime(2026, 9, 20));
      await seedPlanting(db, id: 'old', createdAt: DateTime(2026, 9, 2));
      expect((await garden()).map((v) => v.id), ['old', 'new']);
    });

    test(
      'leaves out removed plantings but keeps planned and harvested',
      () async {
        await seedPlanting(db, id: 'a', status: PlantingStatus.active);
        await seedPlanting(db, id: 'b', status: PlantingStatus.planned);
        await seedPlanting(db, id: 'c', status: PlantingStatus.harvested);
        await seedPlanting(db, id: 'd', status: PlantingStatus.removed);
        expect((await garden()).map((v) => v.id), ['a', 'b', 'c']);
      },
    );

    test('leaves out a planting whose plant left the catalog', () async {
      await seedPlanting(db, id: 'gone', plantId: 'no-such-plant');
      await seedPlanting(db, id: 'here');
      expect((await garden()).map((v) => v.id), ['here']);
    });

    test('a missing space row gives a null space', () async {
      await seedPlanting(db, spaceId: 'nowhere');
      expect((await garden()).single.space, isNull);
    });

    test('a planting with no planted date has no growth', () async {
      await seedPlanting(db, status: PlantingStatus.planned);
      expect((await garden()).single.growth, isNull);
    });

    test('follows writes to the plantings table', () async {
      expect(await garden(), isEmpty);
      await seedPlanting(db, nickname: 'Fresh');
      await pumpEventQueue();
      expect((await garden()).map((v) => v.planting.nickname), ['Fresh']);
    });
  });

  group('plantingViewProvider', () {
    test('finds a planting by id', () async {
      await seedPlanting(db, id: 'p1');
      final v = await view('p1');
      expect(v?.planting.id, 'p1');
    });

    test('is null for an unknown or removed planting', () async {
      await seedPlanting(db, id: 'gone', status: PlantingStatus.removed);
      expect(await view('gone'), isNull);
      expect(await view('nope'), isNull);
    });
  });

  group('per-planting care', () {
    setUp(() async {
      await seedProfile(db);
      await seedPlanting(db, id: 'p1', plantedOn: DateTime(2026, 10, 1));
      await seedPlanting(db, id: 'p2', plantedOn: DateTime(2026, 10, 1));
    });

    /// Loads everything the per-planting providers read, and keeps it alive.
    Future<void> load() async {
      await view('p1');
      await view('p2');
      await container.read(careLogProvider.future);
      container.listen(plantingEventsProvider('p1'), (_, _) {});
      container.listen(careScheduleProvider, (_, _) {});
      container.listen(plantingTasksProvider('p1'), (_, _) {});
      container.listen(nextWaterProvider('p1'), (_, _) {});
      await container.read(careScheduleProvider.future);
    }

    Future<NextWater?> nextWater(String id) {
      container.listen(nextWaterProvider(id), (_, _) {});
      return container.read(nextWaterProvider(id).future);
    }

    test('events are newest first and belong to one planting', () async {
      await seedCare(db, 'p1', CareEventType.water, DateTime(2026, 10, 2, 8));
      await seedCare(
        db,
        'p1',
        CareEventType.fertilize,
        DateTime(2026, 10, 5, 8),
      );
      await seedCare(db, 'p2', CareEventType.water, DateTime(2026, 10, 6, 8));
      await load();
      final events = container.read(plantingEventsProvider('p1'));
      expect(events.map((e) => e.type), [
        CareEventType.fertilize,
        CareEventType.water,
      ]);
    });

    test('an event keeps its note and photo path', () async {
      await seedCare(
        db,
        'p1',
        CareEventType.note,
        DateTime(2026, 10, 2),
        note: 'Hello',
      );
      await load();
      final e = container.read(plantingEventsProvider('p1')).single;
      expect(e.note, 'Hello');
      expect(e.photoPath, isNull);
    });

    test('tasks are empty until the care list has loaded', () {
      expect(container.read(plantingTasksProvider('p1')), isEmpty);
      expect(container.read(nextWaterProvider('p1')).value, isNull);
    });

    test(
      'next water is the planting\'s water task, after the last water',
      () async {
        await seedCare(db, 'p1', CareEventType.water, DateTime(2026, 10, 6, 8));
        await load();
        // Indoor kale waters every 3 days: Oct 6 + 3.
        expect((await nextWater('p1'))?.due, DateTime(2026, 10, 9));
        // p2 has no water logged, so its first water was due on planting day.
        expect((await nextWater('p2'))?.due, DateTime(2026, 10, 1));
      },
    );

    test('tasks are this planting\'s rows of the care list (CR-01)', () async {
      await load();
      final tasks = container.read(plantingTasksProvider('p1'));
      expect(tasks.map((t) => t.kind), [CareTaskKind.water]);
      final schedule = await container.read(careScheduleProvider.future);
      expect(tasks, [
        for (final t in schedule)
          if (t.plantingId == 'p1') t,
      ]);
    });

    test('next water is the same day and slot CR-01 shows (#30)', () async {
      await seedCare(db, 'p1', CareEventType.water, DateTime(2026, 10, 6, 8));
      await load();
      final water = (await container.read(careScheduleProvider.future))
          .singleWhere(
            (t) => t.plantingId == 'p1' && t.kind == CareTaskKind.water,
          );
      final next = (await nextWater('p1'))!;
      expect(next.due, water.due);
      expect(next.slot, water.slot);
      // Due Fri Oct 9; the latest free block on or before it is Wed 18:00.
      expect(next.slot.start, DateTime(2026, 10, 7, 18));
    });

    test('next water past this week still has a day (#30)', () async {
      await seedPlanting(
        db,
        id: 'zz',
        plantId: 'zz-plant',
        nickname: 'ZZ',
        plantedOn: DateTime(2026, 9, 1),
      );
      await seedCare(db, 'zz', CareEventType.water, DateTime(2026, 10, 6, 8));
      await view('zz');
      await container.read(careLogProvider.future);
      // Indoor ZZ plant waters every 21 days: Oct 6 + 21, outside CR-01's
      // seven days, so only the chip knows it.
      expect((await nextWater('zz'))?.due, DateTime(2026, 10, 27));
      expect(container.read(plantingTasksProvider('zz')), isEmpty);
    });

    test('no next water for a planting that is not active', () async {
      await seedPlanting(
        db,
        id: 'h',
        plantedOn: DateTime(2026, 8, 1),
        status: PlantingStatus.harvested,
      );
      await view('h');
      expect(await nextWater('h'), isNull);
    });
  });
}
