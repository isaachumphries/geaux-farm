import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../catalog/domain/plant.dart';
import '../application/clock_provider.dart';
import '../application/plant_detail_provider.dart';
import 'widgets/compat_badge.dart';
import 'widgets/maintenance_pill.dart';
import 'widgets/month_strip.dart';
import 'widgets/plant_card.dart';
import 'widgets/score_breakdown.dart';
import 'widgets/season_chip.dart';

/// PD-01 plant detail: one plant's fit breakdown, care, and planting window,
/// with a sticky "Grow this" action (plan/01 § Screen PD-01).
class PlantDetailScreen extends ConsumerWidget {
  const PlantDetailScreen({super.key, required this.plantId, this.onGrow});

  final String plantId;

  /// Opens the PD-02 grow flow (#23). Null disables the button.
  final VoidCallback? onGrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(plantDetailProvider(plantId));
    final today = ref.watch(todayProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const _Message(text: 'Could not load this plant.'),
            data: (view) => view == null
                ? const _Message(text: 'This plant is not in the catalog.')
                : _DetailBody(view: view, today: today, onGrow: onGrow),
          ),
          const Positioned(top: 0, left: 0, child: _BackButton()),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.view,
    required this.today,
    required this.onGrow,
  });

  final PlantDetailView view;
  final DateTime today;
  final VoidCallback? onGrow;

  @override
  Widget build(BuildContext context) {
    final plant = view.plant;
    final compat = view.compat;
    final timeToGrow = plant.timeToGrowLabel;
    final inSeasonMonths = {
      for (var i = 0; i < compat.monthStrip.length; i++)
        if (compat.monthStrip[i]) i + 1,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(plant: plant),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.xl,
                    children: [
                      _Header(
                        plant: plant,
                        score: compat.score,
                        indoorOnly:
                            PlantCardState.of(compat, view.setup) ==
                            PlantCardState.indoorOnly,
                      ),
                      _Section(
                        title: 'Why it fits',
                        child: ScoreBreakdown(rows: view.rows),
                      ),
                      if (timeToGrow != null)
                        _IconRow(icon: Symbols.timer_rounded, text: timeToGrow),
                      _IconRow(
                        icon: Symbols.schedule_rounded,
                        text: careTimeLabel(plant.care),
                        trailing: MaintenancePill(
                          level: plant.maintenanceLevel,
                        ),
                      ),
                      _Section(
                        title: 'When to plant',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpacing.md,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final tag in plant.seasonTags)
                                  SeasonChip(tag: tag),
                              ],
                            ),
                            MonthStrip(
                              inSeasonMonths: inSeasonMonths,
                              currentMonth: today.month,
                            ),
                          ],
                        ),
                      ),
                      _Section(
                        title: 'Tips',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpacing.sm,
                          children: [
                            for (final tip in plant.tips)
                              GeauxCard(
                                child: _IconRow(
                                  icon: Symbols.lightbulb_rounded,
                                  text: tip,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'Image credit: ${plant.image.credit} · '
                        '${plant.image.license}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: GeauxButton(label: 'Grow this', onPressed: onGrow),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.heroHeight,
      child: ColoredBox(
        color: AppColors.leaf100,
        child: Image.asset(
          plant.image.asset,
          fit: BoxFit.cover,
          semanticLabel: plant.commonName,
          errorBuilder: (_, _, _) =>
              Center(child: CategoryArt(category: plant.category)),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: IconButton.filled(
          tooltip: 'Back',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.soil900,
            minimumSize: const Size.square(AppSpacing.minTouchTarget),
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Symbols.arrow_back_rounded),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.plant,
    required this.score,
    required this.indoorOnly,
  });

  final Plant plant;
  final int score;
  final bool indoorOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Expanded(child: Text(plant.commonName, style: AppText.h1)),
            CompatBadge(score: score),
          ],
        ),
        if (indoorOnly) const IndoorChip(),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Text(title, style: AppText.h2),
        child,
      ],
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text, this.trailing});

  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Icon(icon, size: AppIconSize.md, color: AppColors.soil600),
        Expanded(child: Text(text, style: AppText.body)),
        ?trailing,
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(text, style: AppText.body, textAlign: TextAlign.center),
      ),
    );
  }
}
