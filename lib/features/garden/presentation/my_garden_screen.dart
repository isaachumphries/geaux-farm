import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../application/garden_provider.dart';
import '../application/planting_actions.dart';
import '../domain/planting.dart';
import 'widgets/planting_card.dart';

/// Where RC-01 lives; the garden's add button opens it.
const _findPlantsRoute = '/home/recommendations';

/// GD-01's empty state (#30).
const gardenEmptyCopy = 'Your garden is empty — pick a first plant';

/// GD-01 My Garden (#30): Active and Planned plantings, guide Projects, and
/// harvested plantings last, with a filter chip per section. A planting
/// opens GD-02, a project GD-03; a planned planting can be started here.
class MyGardenScreen extends ConsumerStatefulWidget {
  const MyGardenScreen({super.key});

  @override
  ConsumerState<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends ConsumerState<MyGardenScreen> {
  /// Null shows every section.
  _Section? _only;

  @override
  Widget build(BuildContext context) {
    final garden = ref.watch(gardenProvider);
    final projects = ref.watch(gardenProjectsProvider).value ?? const [];
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
                final views? when views.isEmpty && projects.isEmpty =>
                  const _EmptyGarden(),
                final views? => _GardenList(
                  views: views,
                  projects: projects,
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

/// GD-01's sections, in order. Harvested is not in the GD-01 spec, but
/// GD-02 has a harvested state, so harvested plantings stay reachable at
/// the end.
enum _Section {
  active('Active'),
  planned('Planned'),
  projects('Projects'),
  harvested('Harvested');

  const _Section(this.title);

  final String title;
}

class _GardenList extends ConsumerWidget {
  const _GardenList({
    required this.views,
    required this.projects,
    required this.only,
    required this.onFilter,
  });

  final List<PlantingView> views;
  final List<GardenProject> projects;
  final _Section? only;
  final ValueChanged<_Section?> onFilter;

  List<PlantingView> _withStatus(PlantingStatus s) => [
    for (final v in views)
      if (v.planting.status == s) v,
  ];

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    PlantingView v,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(plantingActionsProvider).startPlanting(v.id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save that. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);
    const rowPadding = EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      0,
      AppSpacing.screenPadding,
      AppSpacing.md,
    );
    Widget card(PlantingView v) => PlantingCard(
      key: ValueKey(v.id),
      view: v,
      onTap: () => context.go('/garden/planting/${v.id}'),
    );
    final rows = <_Section, List<Widget>>{
      _Section.active: [
        for (final v in _withStatus(PlantingStatus.active))
          Padding(padding: rowPadding, child: card(v)),
      ],
      _Section.planned: [
        for (final v in _withStatus(PlantingStatus.planned))
          Padding(
            padding: rowPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                card(v),
                const SizedBox(height: AppSpacing.sm),
                GeauxButton(
                  label: 'Start planting',
                  variant: GeauxButtonVariant.secondary,
                  onPressed: () => _start(context, ref, v),
                ),
              ],
            ),
          ),
      ],
      _Section.projects: [
        for (final p in projects)
          Padding(
            padding: rowPadding,
            child: _ProjectCard(
              key: ValueKey('project-${p.id}'),
              project: p,
              onTap: () => context.go('/garden/project/${p.id}'),
            ),
          ),
      ],
      _Section.harvested: [
        for (final v in _withStatus(PlantingStatus.harvested))
          Padding(padding: rowPadding, child: card(v)),
      ],
    };
    final present = [
      for (final s in _Section.values)
        if (rows[s]!.isNotEmpty) s,
    ];
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
                for (final s in present) ...[
                  _GroupChip(
                    label: '${s.title} · ${rows[s]!.length}',
                    selected: only == s,
                    onTap: () => onFilter(only == s ? null : s),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        for (final s in present)
          if (only == null || only == s) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: inset,
              child: _SectionTitle(title: s.title, count: rows[s]!.length),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...rows[s]!,
          ],
      ],
    );
  }
}

/// A guide project row: its title, opening GD-03.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({super.key, required this.project, required this.onTap});

  final GardenProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(
            Symbols.menu_book_rounded,
            size: AppIconSize.lg,
            color: AppColors.leaf700,
            fill: 1,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              project.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.cardTitle.copyWith(color: AppColors.soil900),
            ),
          ),
          const Icon(
            Symbols.chevron_right_rounded,
            size: AppIconSize.md,
            color: AppColors.soil600,
          ),
        ],
      ),
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
              gardenEmptyCopy,
              textAlign: TextAlign.center,
              style: AppText.h2.copyWith(color: AppColors.soil900),
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
