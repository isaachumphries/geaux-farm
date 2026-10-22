import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../application/guide_project_providers.dart';
import '../data/guide_project_repository.dart';
import '../domain/planting.dart';

/// GD-03 Guide project: a community guide copied by Grow this, as a
/// materials checklist with costs, a steps checklist, and the plantings it
/// added (plan/01 § GD-03). Ticks are saved to Drift as they are made.
class GuideProjectScreen extends ConsumerWidget {
  const GuideProjectScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(guideProjectProvider(projectId)).value;
    final plantings =
        ref.watch(projectPlantingsProvider(projectId)).value ??
        const <Planting>[];
    final repository = ref.read(guideProjectRepositoryProvider);
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: inset,
              child: GeauxTopBar(
                title: project?.title ?? '',
                leading: GeauxCircleButton(
                  icon: Symbols.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/garden'),
                ),
              ),
            ),
            Expanded(
              child: project == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      children: [
                        if (project.materials.isNotEmpty) ...[
                          const _SectionLabel('Materials'),
                          GeauxCard(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Column(
                              children: [
                                for (final (i, m) in project.materials.indexed)
                                  _CheckRow(
                                    checked: m.checked,
                                    title: m.name,
                                    subtitle: m.qty,
                                    trailing: m.estCostUsd == null
                                        ? null
                                        : '\$${m.estCostUsd}',
                                    onChanged: (v) => repository
                                        .setMaterialChecked(projectId, i, v),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        if (project.steps.isNotEmpty) ...[
                          const _SectionLabel('Steps'),
                          GeauxCard(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Column(
                              children: [
                                for (final (i, s) in project.steps.indexed)
                                  _CheckRow(
                                    checked: s.done,
                                    title: '${i + 1}. ${s.title}',
                                    subtitle: s.body,
                                    onChanged: (v) =>
                                        repository.setStepDone(projectId, i, v),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        if (plantings.isNotEmpty) ...[
                          const _SectionLabel('Plants'),
                          for (final p in plantings) ...[
                            _PlantingRow(planting: p),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: AppText.overline.copyWith(color: AppColors.soil600),
        ),
      ),
    );
  }
}

/// A checklist line: the whole row toggles [checked].
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.checked,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    this.trailing,
  });

  final bool checked;
  final String title;
  final String subtitle;
  final String? trailing;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: AppColors.leaf500,
                  side: const BorderSide(
                    color: AppColors.stone200,
                    width: AppBorders.width,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.body.copyWith(
                          color: AppColors.soil900,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: AppText.bodySm.copyWith(
                            color: AppColors.soil600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailing!,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.soil900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A planting Grow this added; opens GD-02.
class _PlantingRow extends StatelessWidget {
  const _PlantingRow({required this.planting});

  final Planting planting;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      onTap: () => context.push('/garden/planting/${planting.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.potted_plant_rounded,
            color: AppColors.leaf700,
            size: AppIconSize.xl,
            fill: 1,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              planting.nickname,
              style: AppText.cardTitle.copyWith(color: AppColors.soil900),
            ),
          ),
          const Icon(
            Symbols.chevron_right_rounded,
            color: AppColors.soil600,
            size: AppIconSize.xl,
          ),
        ],
      ),
    );
  }
}
