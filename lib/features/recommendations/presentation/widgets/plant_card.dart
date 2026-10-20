import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../catalog/domain/plant.dart';
import '../../../garden/domain/planting.dart';
import '../../domain/compatibility.dart';
import '../../domain/scored_plant.dart';
import 'compat_badge.dart';
import 'maintenance_pill.dart';
import 'season_chip.dart';

/// Which flag a [PlantCard] shows: the "Plant now" ribbon, the "Indoor /
/// greenhouse" chip, or neither. `default` is a reserved word, hence
/// `defaultState`.
enum PlantCardState {
  defaultState,
  inSeason,
  indoorOnly;

  /// plan/04 § Card mapping: "Indoor / greenhouse" when the list scores
  /// outdoors and the plant is not viable outdoors, otherwise "Plant now"
  /// when it is in season. A plant that cannot live outside is never told to
  /// be planted now.
  static PlantCardState of(Compatibility c, GrowSetup setup) {
    if (setup == GrowSetup.outdoor && !c.outdoorViable) return indoorOnly;
    return c.inSeason ? inSeason : defaultState;
  }
}

/// Width of the compact carousel card (plan/01 § Components).
const double plantCardCompactWidth = 160;

/// "Daily ~{d}m · Weekly ~{w}m"; a plant with no daily care reads
/// "Daily —" (plan/04 § Card mapping).
String careTimeLabel(PlantCare care) {
  final daily = care.dailyMinutes == 0
      ? 'Daily —'
      : 'Daily ~${care.dailyMinutes}m';
  return '$daily · Weekly ~${care.weeklyMinutes}m';
}

/// Card shape: the compact Home carousel tile (HM-01) or the full-width row
/// on the recommendations list (RC-01).
enum PlantCardSize { compact, list }

/// Plant card for the Home carousel (HM-01) and the recommendations list
/// (RC-01), drawn as in the Figma: category art, optional "Plant now" ribbon,
/// name, compat badge, time to grow, care time, maintenance level, and season
/// chips.
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.state,
    this.onTap,
    this.size = PlantCardSize.compact,
  });

  final ScoredPlant plant;
  final PlantCardState state;
  final VoidCallback? onTap;
  final PlantCardSize size;

  @override
  Widget build(BuildContext context) {
    final p = plant.plant;
    final isList = size == PlantCardSize.list;
    return SizedBox(
      width: isList ? double.infinity : plantCardCompactWidth,
      child: GeauxCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppBorders.width),
        child: isList ? _listBody(p) : _compactBody(p),
      ),
    );
  }

  Widget _compactBody(Plant p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card - AppBorders.width),
          ),
          child: Stack(
            children: [
              CategoryArt(category: p.category),
              if (state == PlantCardState.inSeason)
                const Positioned(
                  left: _ribbonInset,
                  top: _ribbonInset,
                  child: PlantNowRibbon(),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _bodyInset,
            AppSpacing.sm,
            _bodyInset,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _details(p),
          ),
        ),
      ],
    );
  }

  /// Art tile on the left, 80 square; text on the right, with the "Plant now"
  /// ribbon above the name when in season.
  Widget _listBody(Plant p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(AppRadii.card - AppBorders.width),
          ),
          child: SizedBox(
            width: _listArtSize,
            child: CategoryArt(category: p.category, height: _listArtSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state == PlantCardState.inSeason) ...[
                  const PlantNowRibbon(),
                  const SizedBox(height: AppSpacing.xs),
                ],
                ..._details(p),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Name through indoor chip, shared by the compact and list layouts.
  List<Widget> _details(Plant p) {
    final timeToGrow = p.timeToGrowLabel;
    return [
      Text(
        p.commonName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppText.cardTitle.copyWith(color: AppColors.soil900),
      ),
      const SizedBox(height: AppSpacing.xs + 2),
      CompatBadge(score: plant.compatibility.score),
      const SizedBox(height: AppSpacing.xs + 2),
      if (timeToGrow != null)
        _IconLine(
          icon: Symbols.schedule_rounded,
          filled: false,
          color: AppColors.leaf700,
          text: timeToGrow,
        ),
      const SizedBox(height: AppSpacing.xs),
      _IconLine(
        icon: Symbols.water_drop_rounded,
        color: AppColors.frost,
        text: careTimeLabel(p.care),
      ),
      const SizedBox(height: AppSpacing.xs + 2),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          MaintenancePill(level: p.maintenanceLevel),
          for (final tag in p.seasonTags.take(_seasonChipLimit))
            SeasonChip(tag: tag),
        ],
      ),
      if (state == PlantCardState.indoorOnly) ...[
        const SizedBox(height: AppSpacing.xs),
        const IndoorChip(),
      ],
    ];
  }
}

const double _ribbonInset = AppSpacing.sm - AppBorders.width;

/// Side padding of the card body; with the border, text sits 12 from the
/// card edge.
const double _bodyInset = AppSpacing.md - AppBorders.width;

/// Season chips per card: two, as on RC-01.
const int _seasonChipLimit = 2;

// Category art, measured on the HM-01 export (2x, halved): the tinted band
// is 88 tall, the halo disc 80 across, and the icon glyph about 31 wide,
// which a 46 Material Symbol draws.
const double _artHeight = 88;
const double _haloSize = 80;
const double _artIconSize = 46;

// The halo's highlight disc (RC-01 tiles): 36% of the halo across, its
// corner 10% in from the halo's top left.
const double _highlightSize = _haloSize * 0.36;
const double _highlightInset = _haloSize * 0.1;

// RC-01 list art: an 80-square tile on the left of each list card.
const double _listArtSize = 80;

class CategoryArt extends StatelessWidget {
  const CategoryArt({
    super.key,
    required this.category,
    this.height = _artHeight,
  });

  final PlantCategory category;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (Color tint, IconData icon, Color ink) = switch (category) {
      PlantCategory.vegetable => (
        AppColors.leaf100,
        Symbols.eco_rounded,
        AppColors.leaf500,
      ),
      PlantCategory.herb => (
        AppColors.leaf100,
        Symbols.spa_rounded,
        AppColors.leaf700,
      ),
      PlantCategory.flower => (
        AppColors.tileSky,
        Symbols.local_florist_rounded,
        AppColors.tileSkyLedge,
      ),
      PlantCategory.fruit => (
        AppColors.tilePeach,
        Symbols.nutrition_rounded,
        AppColors.heat,
      ),
      PlantCategory.shrub => (
        AppColors.tileSoil,
        Symbols.park_rounded,
        AppColors.tileSoilLedge,
      ),
      PlantCategory.houseplant => (
        AppColors.leaf100,
        Symbols.potted_plant_rounded,
        AppColors.leaf700,
      ),
    };
    final scale = height / _artHeight;
    return Container(
      height: height,
      color: tint,
      alignment: Alignment.center,
      child: SizedBox.square(
        dimension: _haloSize * scale,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.artHalo,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Small highlight on the halo's upper left, as drawn.
            Positioned(
              left: _highlightInset * scale,
              top: _highlightInset * scale,
              child: SizedBox.square(
                dimension: _highlightSize * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.artHalo,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                size: _artIconSize * scale,
                color: ink,
                fill: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold "PLANT NOW" ribbon on a gold ledge.
class PlantNowRibbon extends StatelessWidget {
  const PlantNowRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadii.pill));
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.goldLedge,
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppBorders.width),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.geauxGold,
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              5,
              AppSpacing.md,
              4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.spa_rounded,
                  size: AppIconSize.sm,
                  color: AppColors.soil900,
                  fill: 1,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'Plant now'.toUpperCase(),
                  style: AppText.overline.copyWith(color: AppColors.soil900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({
    required this.icon,
    this.filled = true,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final bool filled;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppIconSize.xs, color: color, fill: filled ? 1 : 0),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppText.caption.copyWith(color: AppColors.soil600),
          ),
        ),
      ],
    );
  }
}

class IndoorChip extends StatelessWidget {
  const IndoorChip({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.tileSoil,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        child: Text(
          'Indoor / greenhouse',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(color: AppColors.soil900),
        ),
      ),
    );
  }
}
