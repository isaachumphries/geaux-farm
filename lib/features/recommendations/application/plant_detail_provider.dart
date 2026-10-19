import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_provider.dart';
import '../../catalog/domain/plant.dart';
import '../../climate/data/climate_provider.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/data/profile_providers.dart';
import '../domain/compatibility.dart';
import '../domain/score_plant.dart';
import '../domain/score_reasons.dart';
import 'clock_provider.dart';
import 'recommendations_provider.dart';

/// Everything PD-01 shows for one plant, scored for the user's setup.
typedef PlantDetailView = ({
  Plant plant,
  Compatibility compat,
  GrowSetup setup,
  List<ScoreRow> rows,
});

/// The scorable plant with [plantId], scored the same way as the
/// recommendation list. Null when no scorable plant has that id.
final plantDetailProvider = FutureProvider.family<PlantDetailView?, String>((
  ref,
  plantId,
) async {
  final today = ref.watch(todayProvider);
  final plants = await ref.watch(catalogProvider.future);
  final climate = await ref.watch(climateProvider.future);
  final profile = await ref.watch(userProfileProvider.future);
  final space = await ref.watch(primarySpaceProvider.future);

  final matches = plants.where((p) => p.id == plantId && p.scorable).toList();
  if (matches.isEmpty) return null;
  final plant = matches.first;

  final ctx = UserContext(profile: profile, space: space, climate: climate);
  final setup = defaultGrowSetup(ctx.space.type);
  final compat = scorePlant(plant, ctx, setup, today);
  return (
    plant: plant,
    compat: compat,
    setup: setup,
    rows: scoreRows(plant: plant, ctx: ctx, setup: setup, compat: compat),
  );
});
