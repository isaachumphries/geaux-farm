import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/plant.dart';
import '../../climate/data/climate_provider.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../onboarding/domain/space.dart';
import '../../recommendations/application/clock_provider.dart';
import '../../recommendations/application/recommendations_provider.dart';
import '../../recommendations/domain/compatibility.dart';
import '../../recommendations/domain/score_plant.dart';
import '../../recommendations/domain/scored_plant.dart';
import '../domain/planting.dart';

/// Earliest planted date PD-02 accepts: 365 days before [today]
/// (plan/05 § Grow this flow).
DateTime earliestPlantedOn(DateTime today) =>
    DateTime(today.year, today.month, today.day - 365);

/// Whether [day] is inside the PD-02 range, today−365 through today.
bool plantedOnAllowed(DateTime day, DateTime today) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  return !d.isBefore(earliestPlantedOn(t)) && !d.isAfter(t);
}

/// What the user has chosen on PD-02 so far, and the plant's fit for the
/// chosen setup.
class GrowSetupState {
  const GrowSetupState({
    required this.spaceId,
    required this.setup,
    required this.inContainer,
    required this.startMethod,
    required this.plantedOn,
    required this.nickname,
    required this.compat,
  });

  /// Defaults for [plant] in [space] on [today]: Indoors on a windowsill and
  /// Outdoors elsewhere, the space's container default when the plant can
  /// be potted, the first start method, and today. [compat] starts as the
  /// list's score, which used the same default setup.
  factory GrowSetupState.initial({
    required ScoredPlant plant,
    required Space space,
    required DateTime today,
  }) {
    final p = plant.plant;
    final starts = p.starts ?? const <PlantStart>[];
    return GrowSetupState(
      spaceId: space.id,
      setup: defaultGrowSetup(space.type),
      inContainer: (p.space?.containerOk ?? true) && space.inContainerDefault,
      startMethod: starts.isEmpty ? null : starts.first.method,
      plantedOn: today,
      nickname: '',
      compat: plant.compatibility,
    );
  }

  final String spaceId;
  final GrowSetup setup;
  final bool inContainer;

  /// Null when the plant has no `starts`; it can't be added then.
  final StartMethod? startMethod;
  final DateTime plantedOn;
  final String nickname;
  final Compatibility compat;

  /// The non-blocking outdoor warning: Outdoors for a plant that is not
  /// outdoor-viable in the user's climate.
  bool get outdoorWarning =>
      setup == GrowSetup.outdoor && !compat.outdoorViable;

  GrowSetupState copyWith({
    GrowSetup? setup,
    bool? inContainer,
    StartMethod? startMethod,
    DateTime? plantedOn,
    String? nickname,
    Compatibility? compat,
  }) => GrowSetupState(
    spaceId: spaceId,
    setup: setup ?? this.setup,
    inContainer: inContainer ?? this.inContainer,
    startMethod: startMethod ?? this.startMethod,
    plantedOn: plantedOn ?? this.plantedOn,
    nickname: nickname ?? this.nickname,
    compat: compat ?? this.compat,
  );
}

/// Scores [plant] for [setup] against the user's profile, primary space, and
/// climate, as the recommendation list does for its default setup.
typedef GrowScorer = Future<Compatibility> Function(
  Plant plant,
  GrowSetup setup,
);

final growScorerProvider = Provider<GrowScorer>(
  (ref) => (plant, setup) async {
    final ctx = UserContext(
      profile: await ref.read(userProfileProvider.future),
      space: await ref.read(primarySpaceProvider.future),
      climate: await ref.read(climateProvider.future),
    );
    return scorePlant(plant, ctx, setup, ref.read(todayProvider));
  },
);

/// Holds the PD-02 choices for one plant. Null until the primary space has
/// loaded. Every setup change re-runs `scorePlant` for the new setup.
class GrowSetupController extends Notifier<GrowSetupState?> {
  GrowSetupController(this.plant);

  final ScoredPlant plant;

  @override
  GrowSetupState? build() {
    final space = ref.watch(primarySpaceProvider).value;
    if (space == null) return null;
    return GrowSetupState.initial(
      plant: plant,
      space: space,
      today: ref.watch(todayProvider),
    );
  }

  Future<void> setSetup(GrowSetup setup) async {
    final current = state;
    if (current == null || current.setup == setup) return;
    state = current.copyWith(setup: setup);
    final compat = await ref.read(growScorerProvider)(plant.plant, setup);
    // A newer choice wins over a slower score for an older one.
    final now = state;
    if (!ref.mounted || now == null || now.setup != setup) return;
    state = now.copyWith(compat: compat);
  }

  void setInContainer(bool value) =>
      _update((s) => s.copyWith(inContainer: value));

  void setStartMethod(StartMethod method) =>
      _update((s) => s.copyWith(startMethod: method));

  /// Ignores a date outside today−365 through today.
  void setPlantedOn(DateTime day) {
    if (!plantedOnAllowed(day, ref.read(todayProvider))) return;
    _update(
      (s) => s.copyWith(plantedOn: DateTime(day.year, day.month, day.day)),
    );
  }

  void setNickname(String value) => _update((s) => s.copyWith(nickname: value));

  void _update(GrowSetupState Function(GrowSetupState) change) {
    final current = state;
    if (current != null) state = change(current);
  }
}

final growSetupControllerProvider = NotifierProvider.autoDispose
    .family<GrowSetupController, GrowSetupState?, ScoredPlant>(
      GrowSetupController.new,
    );
