import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../care/domain/care_event.dart';
import '../../catalog/data/catalog_provider.dart';
import '../../catalog/domain/plant.dart';
import '../../onboarding/domain/space.dart';
import '../../recommendations/application/clock_provider.dart';
import '../data/plantings_provider.dart';
import '../domain/growth.dart';
import '../domain/planting.dart';

/// One planting with what its cards and detail screen need: the catalog
/// plant, the space it sits in, and its growth today.
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
  final GrowthReading? growth;

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
            growth: growthOf(pl, plant, today),
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

/// This week's care jobs for one planting, soonest first. Empty while the
/// garden or the care log loads.
final plantingTasksProvider = Provider.autoDispose.family(_plantingTasks);

List<CareDue> _plantingTasks(Ref ref, String id) {
  final view = ref.watch(plantingViewProvider(id)).value;
  if (view == null) return const [];
  return careDueFor(
    view.planting,
    view.plant,
    ref.watch(plantingEventsProvider(id)),
    ref.watch(todayProvider),
  );
}

/// The next watering for one planting this week, if any.
final nextWaterProvider = Provider.autoDispose.family(_nextWater);

CareDue? _nextWater(Ref ref, String id) {
  for (final t in ref.watch(plantingTasksProvider(id))) {
    if (t.type == CareEventType.water) return t;
  }
  return null;
}