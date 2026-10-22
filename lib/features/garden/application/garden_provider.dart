import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../care/application/care_schedule_provider.dart';
import '../../care/domain/care_event.dart';
import '../../care/domain/care_schedule.dart';
import '../../care/domain/slot.dart';
import '../../care/domain/stage.dart';
import '../../care/domain/water_due.dart';
import '../../catalog/data/catalog_provider.dart';
import '../../catalog/domain/plant.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../onboarding/domain/space.dart';
import '../../recommendations/application/clock_provider.dart';
import '../data/plantings_provider.dart';
import '../domain/planting.dart';

/// One planting with what its cards and detail screen need: the catalog
/// plant, the space it sits in, and its stage today (CARE-01 [stageOf]).
class PlantingView {
  const PlantingView({
    required this.planting,
    required this.plant,
    required this.space,
    required this.growth,
  });

  final Planting planting;
  final Plant plant;

  /// Null when the planting's space row is missing.
  final Space? space;

  /// Null when the planting has no planted date yet.
  final StageReading? growth;

  String get id => planting.id;
}

/// Every `spaces` row, so each planting shows the space it sits in.
final gardenSpacesProvider = StreamProvider<List<Space>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .select(db.spacesTable)
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            Space(
              id: r.id,
              type: r.type,
              areaSqFt: r.areaSqFt,
              sun: r.sun,
              sunUnsure: r.sunUnsure,
              rainExposed: r.rainExposed,
              inContainerDefault: r.inContainerDefault,
              isPrimary: r.isPrimary,
            ),
        ],
      );
});

/// Every logged care event.
final careLogProvider = StreamProvider<List<CareEvent>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .select(db.careEventsTable)
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            CareEvent(
              id: r.id,
              plantingId: r.plantingId,
              type: r.type,
              at: r.at,
              note: r.note,
              photoPath: r.photoPath,
            ),
        ],
      );
});

/// Every planting that is not removed, oldest first, joined with its
/// catalog plant and space. A planting whose plant is no longer in the
/// catalog is left out.
final gardenProvider = FutureProvider<List<PlantingView>>((ref) async {
  final today = ref.watch(todayProvider);
  final plantings = await ref.watch(plantingsProvider.future);
  final plants = await ref.watch(catalogProvider.future);
  final spaces = await ref.watch(gardenSpacesProvider.future);

  final plantsById = {for (final p in plants) p.id: p};
  final spacesById = {for (final s in spaces) s.id: s};
  return [
    for (final pl in plantings)
      if (pl.status != PlantingStatus.removed)
        if (plantsById[pl.plantId] case final plant?)
          PlantingView(
            planting: pl,
            plant: plant,
            space: spacesById[pl.spaceId],
            growth: pl.plantedOn == null ? null : stageOf(pl, plant, today),
          ),
  ];
});

/// The planting with [id], or null when it is missing or removed.
final plantingViewProvider = FutureProvider.family<PlantingView?, String>((
  ref,
  id,
) async {
  final garden = await ref.watch(gardenProvider.future);
  for (final v in garden) {
    if (v.id == id) return v;
  }
  return null;
});

/// Logged care for one planting, newest first.
final plantingEventsProvider = Provider.autoDispose.family(_plantingEvents);

List<CareEvent> _plantingEvents(Ref ref, String id) {
  final events = ref.watch(careLogProvider).value ?? const [];
  return [
    for (final e in events)
      if (e.plantingId == id) e,
  ]..sort((a, b) => b.at.compareTo(a.at));
}

/// This week's care for one planting, straight from the care list (CR-01),
/// so GD-02 shows the same days and free-time slots. Soonest slot first;
/// empty while the list loads.
final plantingTasksProvider = Provider.autoDispose
    .family<List<ScheduledCareTask>, String>((ref, id) {
      final tasks = ref.watch(careScheduleProvider).value ?? const [];
      return [
        for (final t in tasks)
          if (t.plantingId == id) t,
      ];
    });

/// When an active planting is next watered: the CARE-01 [waterDue] day and
/// the free-time slot it goes in, from the same inputs as the care list.
class NextWater {
  const NextWater({required this.due, required this.slot});

  final DateTime due;
  final CareSlot slot;
}

/// The next watering for one planting, not limited to this week. Null when
/// the planting is not active, has no planted date or space, or the plant
/// has no water need.
final nextWaterProvider = FutureProvider.autoDispose.family<NextWater?, String>(
  (ref, id) async {
    final view = await ref.watch(plantingViewProvider(id).future);
    if (view == null) return null;
    final pl = view.planting;
    final space = view.space;
    if (pl.status != PlantingStatus.active ||
        pl.plantedOn == null ||
        space == null ||
        view.plant.water == null) {
      return null;
    }
    final events = await ref.watch(careEventsProvider.future);
    final profile = await ref.watch(userProfileProvider.future);
    final days = await ref.watch(careForecastDaysProvider.future);
    final today = ref.watch(todayProvider);
    final due = waterDue(pl, view.plant, space, events, days, today);
    return NextWater(
      due: due,
      slot: findSlot(due, profile.availability, ref.read(clockProvider)()),
    );
  },
);

/// A guide project on GD-01 (#30): a "Grow this" copy of a community guide.
/// GD-03 itself is #49.
class GardenProject {
  const GardenProject({required this.id, required this.title});

  final String id;
  final String title;
}

/// Every `guide_projects` row, oldest first, for GD-01's Projects section.
final gardenProjectsProvider = StreamProvider<List<GardenProject>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.guideProjectsTable)
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  return query.watch().map(
    (rows) => [for (final r in rows) GardenProject(id: r.id, title: r.title)],
  );
});
