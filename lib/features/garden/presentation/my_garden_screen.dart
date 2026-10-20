import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../application/garden_provider.dart';
import '../domain/planting.dart';
import 'widgets/planting_card.dart';

/// Where RC-01 lives; the garden's add button opens it.
const _findPlantsRoute = '/home/recommendations';

/// GD-01 My Garden: every planting, grouped Active, Planned, Harvested,
/// with a filter chip per group. Tapping a card opens GD-02.
class MyGardenScreen extends ConsumerStatefulWidget {
  const MyGardenScreen({super.key});

  @override
  ConsumerState<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends ConsumerState<MyGardenScreen> {
  /// Null shows every group.
  PlantingStatus? _only;

  @override
  Widget build(BuildContext context) {
    final garden = ref.watch(gardenProvider);
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
                title: 'My Garden',
                large: true,
                trailing: GeauxCircleButton(
                  icon: Symbols.add_rounded,
                  tooltip: 'Add a plant',
                  onPressed: () => context.push(_findPlantsRoute),
                ),
              ),
            ),
            // The last list stays up while a write reloads the garden.
            Expanded(
              child: switch (garden.value) {
                final views? when views.isEmpty => const _EmptyGarden(),
                final views? => _GardenList(
                  views: views,
                  only: _only,
                  onFilter: (s) => setState(() => _only = s),
                ),
                null when garden.hasError => Center(
                  child: Text(
                    "Couldn't load your garden.",
                    style: AppText.bodySm.copyWith(color: AppColors.soil600),
                  ),
                ),
                null => const Center(
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

String _groupTitle(PlantingStatus s) => switch (s) {
  PlantingStatus.active => 'Active',
  PlantingStatus.planned => 'Planned',
  PlantingStatus.harvested => 'Harvested',
  PlantingStatus.removed => 'Removed',
};

class _GardenList extends StatelessWidget {
  const _GardenList({
    required this.views,
    required this.only,
    required this.onFilter,
  });

  final List<PlantingView> views;
  final PlantingStatus? only;
  final ValueChanged<PlantingStatus?> onFilter;

  @override
  Widget build(BuildContext context) {
    const groups = [
      PlantingStatus.active,
      PlantingStatus.planned,
      PlantingStatus.harvested,
    ];
    final byGroup = {
      for (final g in groups)
        g: [
          for (final v in views)
            if (v.planting.status == g) v,
        ],
    };
    final present = [
      for (final g in groups)
        if (byGroup[g]!.isNotEmpty) g,
    ];
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
      children: [
        if (present.length > 1)
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: inset,
              children: [
                for (final g in present) ...[
                  _GroupChip(
                    label: '${_groupTitle(g)} · ${byGroup[g]!.length}',
                    selected: only == g,
                    onTap: () => onFilter(only == g ? null : g),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        for (final g in present)
          if (only == null || only == g) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: inset,
              child: _SectionTitle(
                title: _groupTitle(g),
                count: byGroup[g]!.length,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final v in byGroup[g]!)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: PlantingCard(
                  key: ValueKey(v.id),
                  view: v,
                  onTap: () => context.go('/garden/planting/${v.id}'),
                ),
              ),
          ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppText.h2.copyWith(color: AppColors.soil900)),
        const SizedBox(width: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.stone200,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            child: Text(
              '$count',
              style: AppText.label.copyWith(color: AppColors.soil600),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
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

class _EmptyGarden extends StatelessWidget {
  const _EmptyGarden();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.leaf100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.yard_rounded,
                size: 48,
                color: AppColors.leaf500,
                fill: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your garden is empty',
              textAlign: TextAlign.center,
              style: AppText.h2.copyWith(color: AppColors.soil900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick a plant that fits your space and it will show up here.',
              textAlign: TextAlign.center,
              style: AppText.bodySm.copyWith(color: AppColors.soil600),
            ),
            const SizedBox(height: AppSpacing.xl),
            GeauxButton(
              label: 'Find a plant',
              onPressed: () => context.push(_findPlantsRoute),
            ),
          ],
        ),
      ),
    );
  }
}