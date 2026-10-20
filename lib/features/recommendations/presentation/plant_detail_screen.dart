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
    final state = PlantCardState.of(compat, view.setup);
    final inSeasonMonths = {
      for (var i = 0; i < compat.monthStrip.length; i++)
        if (compat.monthStrip[i]) i + 1,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: AppSizes.heroHeight,
                  child: _Hero(plant: plant),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.heroHeight - AppRadii.sheet,
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.cream50,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadii.sheet),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.xxl,
                        children: [
                          _Header(
                            plant: plant,
                            score: compat.score,
                            state: state,
                          ),
                          _Section(
                            title: 'Why it fits',
                            child: GeauxCard(
                              child: ScoreBreakdown(rows: view.rows),
                            ),
                          ),
                          _CareStats(plant: plant),
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
                              spacing: AppSpacing.md,
                              children: [
                                for (final tip in plant.tips)
                                  _TipCard(text: tip),
                              ],
                            ),
                          ),
                          Text(
                            'Image credit: ${plant.image.credit} · '
                            '${plant.image.license}',
                            style: AppText.label.copyWith(
                              color: AppColors.soil600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.stone200)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xxl,
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
              ),
              child: GeauxButton(
                label: 'Grow this',
                icon: Symbols.add_rounded,
                onPressed: onGrow,
              ),
            ),
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
    return ColoredBox(
      color: AppColors.leaf100,
      child: Image.asset(
        plant.image.asset,
        fit: BoxFit.cover,
        semanticLabel: plant.commonName,
        errorBuilder: (_, _, _) => Align(
          alignment: Alignment.topCenter,
          child: CategoryArt(
            category: plant.category,
            height: AppSizes.heroHeight - AppRadii.sheet,
          ),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: IconButton(
          tooltip: 'Back',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.soil900,
            minimumSize: const Size.square(AppSpacing.minTouchTarget),
            side: AppBorders.cardSide,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Symbols.arrow_back_ios_new_rounded),
        ),
      ),
    );
  }
}

String _categoryLabel(PlantCategory category) => switch (category) {
  PlantCategory.vegetable => 'Vegetable',
  PlantCategory.herb => 'Herb',
  PlantCategory.fruit => 'Fruit',
  PlantCategory.flower => 'Flower',
  PlantCategory.shrub => 'Shrub',
  PlantCategory.houseplant => 'Houseplant',
};

class _Header extends StatelessWidget {
  const _Header({
    required this.plant,
    required this.score,
    required this.state,
  });

  final Plant plant;
  final int score;
  final PlantCardState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(plant.commonName, style: AppText.display),
        Text(
          '${plant.scientificName} · ${_categoryLabel(plant.category)}',
          style: AppText.bodySm.copyWith(color: AppColors.soil600),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CompatBadge(score: score),
            if (state == PlantCardState.inSeason) const PlantNowRibbon(),
            MaintenancePill(level: plant.maintenanceLevel),
            if (state == PlantCardState.indoorOnly) const IndoorChip(),
          ],
        ),
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

/// Time to grow, daily care, and weekly care as three stat cards.
class _CareStats extends StatelessWidget {
  const _CareStats({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final care = plant.care;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Expanded(
            child: _StatCard(
              icon: Symbols.schedule_rounded,
              tile: AppColors.leaf100,
              ink: AppColors.leaf700,
              caption: 'Time to grow',
              value: plant.timeToGrowLabel ?? '—',
            ),
          ),
          Expanded(
            child: _StatCard(
              icon: Symbols.water_drop_rounded,
              tile: AppColors.tileSky,
              ink: AppColors.tileSkyLedge,
              caption: 'Daily care',
              value: care.dailyMinutes == 0 ? '—' : '~${care.dailyMinutes}m',
            ),
          ),
          Expanded(
            child: _StatCard(
              icon: Symbols.event_repeat_rounded,
              tile: AppColors.tileSoil,
              ink: AppColors.tileSoilLedge,
              caption: 'Weekly care',
              value: '~${care.weeklyMinutes}m',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tile,
    required this.ink,
    required this.caption,
    required this.value,
  });

  final IconData icon;
  final Color tile;
  final Color ink;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IconTile(icon: icon, tile: tile, ink: ink),
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption,
            style: AppText.caption.copyWith(
              color: AppColors.soil600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppText.bodySm.copyWith(
              color: AppColors.soil900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.tile, required this.ink});

  final IconData icon;
  final Color tile;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tile,
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        child: SizedBox.square(
          dimension: _tileSize,
          child: Icon(icon, size: AppIconSize.md, color: ink, fill: 1),
        ),
      ),
    );
  }
}

const double _tileSize = 36;

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          const _IconTile(
            icon: Symbols.lightbulb_rounded,
            tile: AppColors.gold100,
            ink: AppColors.goldLedge,
          ),
          Expanded(
            child: Text(
              text,
              style: AppText.body.copyWith(color: AppColors.soil900),
            ),
          ),
        ],
      ),
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
