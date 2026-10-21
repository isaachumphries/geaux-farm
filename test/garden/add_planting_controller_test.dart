import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/application/add_planting_controller.dart';
import 'package:geaux_farm/features/garden/application/grow_setup_controller.dart';
import 'package:geaux_farm/features/garden/data/garden_repository.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';

import '../recommendations/fixtures/scored.dart';
import 'garden_harness.dart';

class _FailingRepository extends GardenRepository {
  _FailingRepository(super.db) : super(now: () => gardenNow);

  @override
  Future<String> addPlanting({
    required Plant plant,
    required String spaceId,
    required String nickname,
    required GrowSetup setup,
    required bool inContainer,
    required StartMethod startMethod,
    required DateTime plantedOn,
  }) => Future.error(StateError('disk full'));
}

GrowSetupState _setup({StartMethod? start = StartMethod.seed}) =>
    GrowSetupState(
      spaceId: 's1',
      setup: GrowSetup.greenhouse,
      inContainer: true,
      startMethod: start,
      plantedOn: DateTime(2026, 9, 30),
      nickname: 'Big Kale',
      compat: scored(kaleWith({})).compatibility,
    );

void main() {
  test('inserts one active planting, then recomputes once', () async {
    final db = openGardenDb();
    await seedSpace(db);
    var recomputes = 0;
    final controller = AddPlantingController(
      GardenRepository(db, now: () => gardenNow),
      () => recomputes++,
    );

    final id = await controller.addPlanting(kaleWith({}), _setup());

    final rows = await db.select(db.plantingsTable).get();
    expect(rows, hasLength(1));
    final r = rows.single;
    expect(r.id, id);
    expect(r.status, PlantingStatus.active);
    expect(r.plantedOn, DateTime(2026, 9, 30));
    expect(r.startMethod, 'seed');
    expect(r.setup, GrowSetup.greenhouse);
    expect(r.spaceId, 's1');
    expect(r.nickname, 'Big Kale');
    expect(recomputes, 1);
  });

  test('a failed insert does not recompute', () async {
    final db = openGardenDb();
    var recomputes = 0;
    final controller = AddPlantingController(
      _FailingRepository(db),
      () => recomputes++,
    );

    await expectLater(
      controller.addPlanting(kaleWith({}), _setup()),
      throwsStateError,
    );
    expect(recomputes, 0);
  });

  test('a setup with no start method is refused', () async {
    final db = openGardenDb();
    await seedSpace(db);
    var recomputes = 0;
    final controller = AddPlantingController(
      GardenRepository(db, now: () => gardenNow),
      () => recomputes++,
    );

    await expectLater(
      controller.addPlanting(kaleWith({}), _setup(start: null)),
      throwsStateError,
    );
    expect(await db.select(db.plantingsTable).get(), isEmpty);
    expect(recomputes, 0);
  });

  test('the provider recompute rebuilds the care schedule', () async {
    final db = openGardenDb();
    await seedSpace(db);
    var builds = 0;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        careScheduleProvider.overrideWith((ref) async {
          builds++;
          return const [];
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(careScheduleProvider, (_, _) {});
    await container.read(careScheduleProvider.future);
    expect(builds, 1);

    await container
        .read(addPlantingControllerProvider)
        .addPlanting(kaleWith({}), _setup());
    await container.read(careScheduleProvider.future);

    expect(builds, 2);
  });
}
