import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_provider.dart';
import '../../climate/data/climate_provider.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../onboarding/domain/space.dart';
import '../domain/compatibility.dart';
import '../domain/score_plant.dart';
import '../domain/scored_plant.dart';
import '../domain/sort_recommendations.dart';
import 'clock_provider.dart';

/// Setup a recommendation list scores for (plan/04): indoor for a
/// windowsill, outdoor for every other space.
GrowSetup defaultGrowSetup(SpaceType type) =>
    type == SpaceType.windowsill ? GrowSetup.indoor : GrowSetup.outdoor;

/// Every scorable catalog plant scored for the user's profile, primary
/// space, and climate on [todayProvider]'s date, in the plan/04 § Sorting
/// order. Recomputes when any of those change; screens filter the list
/// themselves.
final recommendationsProvider = FutureProvider<List<ScoredPlant>>((ref) async {
  final today = ref.watch(todayProvider);
  final plants = ref.watch(catalogProvider.future);
  final climate = ref.watch(climateProvider.future);
  final profile = ref.watch(userProfileProvider.future);
  final space = ref.watch(primarySpaceProvider.future);

  final ctx = UserContext(
    profile: await profile,
    space: await space,
    climate: await climate,
  );
  final setup = defaultGrowSetup(ctx.space.type);
  return sortRecommendations([
    for (final p in await plants)
      if (p.scorable) ScoredPlant(p, scorePlant(p, ctx, setup, today)),
  ]);
});
