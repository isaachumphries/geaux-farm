import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../climate/data/climate_provider.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/data/profile_providers.dart';
import '../application/recommendation_list_provider.dart';
import '../application/recommendations_provider.dart';
import '../domain/scored_plant.dart';
import 'widgets/plant_card.dart';
import 'widgets/recommendation_chips.dart';

/// Shown when the chip and search text match nothing.
const recommendationsEmptyCopy = 'No plants match.';

/// Shown when the catalog or the climate profile could not be read.
const recommendationsErrorCopy = "Couldn't load plants.";

/// RC-01: the full sorted plant list behind Home's "See all". Filter chips
/// and search narrow it; the order always comes from
/// [recommendationsProvider] (plan/04 § Filters).
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(recommendationListFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(recommendationListFilterProvider);
    final notifier = ref.read(recommendationListFilterProvider.notifier);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: GeauxTextField(
                controller: _search,
                hintText: 'Search plants',
                prefixIcon: Symbols.search_rounded,
                textInputAction: TextInputAction.search,
                onChanged: notifier.search,
              ),
            ),
            RecommendationChipRow(
              selected: filter.chip,
              onSelected: notifier.selectChip,
            ),
            const SizedBox(height: AppSpacing.md),
            const Expanded(child: _Results()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      child: GeauxTopBar(
        title: 'Plants for you',
        leading: GeauxCircleButton(
          icon: Symbols.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
    );
  }
}

/// The list area: cards, the empty state, or a spinner while the catalog
/// and climate profile load.
class _Results extends ConsumerWidget {
  const _Results();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(primarySpaceProvider).value;
    final climate = ref.watch(climateProvider);
    if (climate is AsyncError && !climate.isLoading) {
      return GeauxEmptyState(
        message: recommendationsErrorCopy,
        icon: Symbols.error_rounded,
        action: GeauxButton(
          label: 'Retry',
          variant: GeauxButtonVariant.text,
          onPressed: () => ref.read(climateProvider.notifier).rebuild(),
        ),
      );
    }
    final matches = ref.watch(filteredRecommendationsProvider);
    if (space == null || climate is! AsyncData) return const _Loading();
    return switch (matches) {
      AsyncData(:final value) when value.isEmpty => const GeauxEmptyState(
        message: recommendationsEmptyCopy,
        icon: Symbols.eco_rounded,
      ),
      AsyncData(:final value) => _PlantList(
        plants: value,
        setup: defaultGrowSetup(space.type),
      ),
      AsyncError() => const GeauxEmptyState(
        message: recommendationsErrorCopy,
        icon: Symbols.error_rounded,
      ),
      _ => const _Loading(),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.leaf500));
}

class _PlantList extends StatelessWidget {
  const _PlantList({required this.plants, required this.setup});

  final List<ScoredPlant> plants;
  final GrowSetup setup;

  @override
  Widget build(BuildContext context) {
    // The count line is the first row; the cards follow it.
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      itemCount: plants.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        if (i == 0) return _CountLine(plants.length);
        final s = plants[i - 1];
        return PlantCard(
          key: ValueKey(s.plant.id),
          plant: s,
          size: PlantCardSize.list,
          state: PlantCardState.of(s.compatibility, setup),
          onTap: () => context.push('/plants/${s.plant.id}'),
        );
      },
    );
  }
}

/// The RC-01 frame's "10 plants · sorted by best fit": how many plants
/// match, in the order of plan/04 § Sorting.
class _CountLine extends StatelessWidget {
  const _CountLine(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count ${count == 1 ? 'plant' : 'plants'} · sorted by best fit',
      style: AppText.bodySm.copyWith(color: AppColors.soil600),
    );
  }
}
