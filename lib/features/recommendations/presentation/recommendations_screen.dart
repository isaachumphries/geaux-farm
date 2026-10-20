import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/data/profile_providers.dart';
import '../application/recommendations_provider.dart';
import '../domain/recommendation_filter.dart';
import '../domain/scored_plant.dart';
import 'widgets/plant_card.dart';
import 'widgets/plant_list_card.dart';

/// Chip labels on RC-01 (plan/04 § Filters).
String recommendationChipLabel(RecommendationChip chip) => switch (chip) {
  RecommendationChip.all => 'All',
  RecommendationChip.food => 'Food',
  RecommendationChip.herbs => 'Herbs',
  RecommendationChip.flowers => 'Flowers',
  RecommendationChip.shrubs => 'Shrubs',
  RecommendationChip.indoor => 'Indoor',
  RecommendationChip.lowMaintenance => 'Low maintenance',
};

/// RC-01 "Plants for you": every recommendation, best fit first, with
/// search and filter chips. Tapping a plant opens PD-01 (plan/01 RC-01).
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  RecommendationChip _chip = RecommendationChip.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final recs = ref.watch(recommendationsProvider);
    final space = ref.watch(primarySpaceProvider).value;
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: inset,
              child: GeauxTopBar(
                title: 'Plants for you',
                leading: GeauxCircleButton(
                  icon: Symbols.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: inset,
              child: GeauxTextField(
                hintText: 'Search plants',
                prefixIcon: Symbols.search_rounded,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSpacing.minTouchTarget,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: inset,
                itemCount: RecommendationChip.values.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final chip = RecommendationChip.values[i];
                  return _FilterChip(
                    label: recommendationChipLabel(chip),
                    selected: chip == _chip,
                    onTap: () => setState(() => _chip = chip),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: switch (recs) {
                AsyncData(:final value) when space != null => _List(
                  plants: applyRecommendationFilter(value, _chip, _query),
                  setup: defaultGrowSetup(space.type),
                ),
                AsyncError() => Center(
                  child: Text(
                    "Couldn't load plants.",
                    style: AppText.bodySm.copyWith(color: AppColors.soil600),
                  ),
                ),
                _ => const Center(
                  child: CircularProgressIndicator(color: AppColors.leaf500),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.plants, required this.setup});

  final List<ScoredPlant> plants;
  final GrowSetup setup;

  @override
  Widget build(BuildContext context) {
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);
    final count = plants.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: inset,
          child: Text(
            '$count ${count == 1 ? 'plant' : 'plants'} · sorted by best fit',
            style: AppText.bodySm.copyWith(color: AppColors.soil600),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (plants.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'No plants match. Try another search or filter.',
              textAlign: TextAlign.center,
              style: AppText.bodySm.copyWith(color: AppColors.soil600),
            ),
          ),
        for (final s in plants)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: PlantListCard(
              key: ValueKey(s.plant.id),
              plant: s,
              state: PlantCardState.of(s.compatibility, setup),
              onTap: () => context.push('/plants/${s.plant.id}'),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: GeauxCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm - 2,
        ),
        color: selected ? AppColors.leaf700 : AppColors.white,
        borderColor: selected ? null : AppColors.stone200,
        ledgeColor: selected ? AppColors.leafLedge : AppColors.stone200,
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: AppText.bodySm.copyWith(
              color: selected ? AppColors.white : AppColors.soil900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
