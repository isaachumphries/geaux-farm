import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ids.dart';
import '../../catalog/domain/plant.dart';
import '../../community/domain/guide.dart';
import '../../onboarding/domain/space.dart';
import '../../recommendations/application/clock_provider.dart';
import '../../recommendations/application/recommendations_provider.dart';
import '../domain/guide_project.dart';
import '../domain/planting.dart';

/// Drift side of Grow this from a guide (plan/07 § Grow this, steps 1–2)
/// and the GD-03 checklists.
class GuideProjectRepository {
  GuideProjectRepository(this._db, {required this.now, Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final DateTime Function() now;
  final Random _random;

  /// Copies [guide] into a new `guide_projects` row and adds one `planned`
  /// planting in [space] for each of its plant ids found in [catalog], all
  /// in one transaction. Returns the project id.
  ///
  /// The snapshot keeps the title, [coverUrl], every material unchecked and
  /// every step not done. Unknown plant ids are skipped. A planned
  /// planting has no planted date; its setup is Indoors on a windowsill and
  /// Outdoors elsewhere (plan/05 § Grow this flow).
  Future<String> createFromGuide({
    required Guide guide,
    required String? coverUrl,
    required List<Plant> catalog,
    required Space space,
  }) {
    final byId = {for (final p in catalog) p.id: p};
    final createdAt = now();
    final projectId = uuidV4(_random);
    return _db.transaction(() async {
      await _db
          .into(_db.guideProjectsTable)
          .insert(
            GuideProjectsTableCompanion.insert(
              id: projectId,
              guideId: guide.id,
              title: guide.title,
              coverUrl: Value(coverUrl),
              materialsJson: encodeMaterials([
                for (final m in guide.materials) ProjectMaterial.fromGuide(m),
              ]),
              stepsJson: encodeSteps([
                for (final s in guide.steps) ProjectStep.fromGuide(s),
              ]),
              createdAt: createdAt,
            ),
          );
      for (final plantId in guide.plantIds.toSet()) {
        final plant = byId[plantId];
        if (plant == null) continue;
        final starts = plant.starts ?? const <PlantStart>[];
        await _db
            .into(_db.plantingsTable)
            .insert(
              PlantingsTableCompanion.insert(
                id: uuidV4(_random),
                plantId: plant.id,
                spaceId: space.id,
                nickname: plant.commonName,
                setup: defaultGrowSetup(space.type),
                inContainer:
                    (plant.space?.containerOk ?? true) &&
                    space.inContainerDefault,
                startMethod:
                    (starts.isEmpty ? StartMethod.seed : starts.first.method)
                        .json,
                status: PlantingStatus.planned,
                projectId: Value(projectId),
                createdAt: createdAt,
              ),
            );
      }
      return projectId;
    });
  }

  /// The project [id], or null once it is gone.
  Stream<GuideProject?> watchProject(String id) {
    final query = _db.select(_db.guideProjectsTable)
      ..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _projectFromRow(row),
    );
  }

  /// Ticks or clears material [index] of project [id].
  Future<void> setMaterialChecked(String id, int index, bool checked) =>
      _db.transaction(() async {
        final row = await _row(id);
        final materials = decodeMaterials(row.materialsJson);
        materials[index] = materials[index].withChecked(checked);
        await _write(
          id,
          GuideProjectsTableCompanion(
            materialsJson: Value(encodeMaterials(materials)),
          ),
        );
      });

  /// Marks step [index] of project [id] done or not done.
  Future<void> setStepDone(String id, int index, bool done) =>
      _db.transaction(() async {
        final row = await _row(id);
        final steps = decodeSteps(row.stepsJson);
        steps[index] = steps[index].withDone(done);
        await _write(
          id,
          GuideProjectsTableCompanion(stepsJson: Value(encodeSteps(steps))),
        );
      });

  Future<GuideProjectRow> _row(String id) => (_db.select(
    _db.guideProjectsTable,
  )..where((t) => t.id.equals(id))).getSingle();

  Future<void> _write(String id, GuideProjectsTableCompanion values) =>
      (_db.update(
        _db.guideProjectsTable,
      )..where((t) => t.id.equals(id))).write(values);
}

GuideProject _projectFromRow(GuideProjectRow r) => GuideProject(
  id: r.id,
  guideId: r.guideId,
  title: r.title,
  coverUrl: r.coverUrl,
  materials: decodeMaterials(r.materialsJson),
  steps: decodeSteps(r.stepsJson),
  createdAt: r.createdAt,
);

final guideProjectRepositoryProvider = Provider<GuideProjectRepository>(
  (ref) => GuideProjectRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  ),
);
