import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../catalog/presentation/plant_art.dart';
import '../../domain/scored_plant.dart';
import 'compat_badge.dart';
import 'maintenance_pill.dart';
import 'plant_card.dart';

/// Full-width plant row for the RC-01 list: category art on the left, then
/// the "Plant now" ribbon, name, compat badge, time to grow, care time,
/// and maintenance level.
class PlantListCard extends StatelessWidget {
  const PlantListCard({
    super.key,
    required this.plant,
    required this.state,
    this.onTap,
  });

  final ScoredPlant plant;
  final PlantCardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = plant.plant;
    final timeToGrow = p.timeToGrowLabel;
    return GeauxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlantTile(category: p.category, size: 88),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state == PlantCardState.inSeason) ...[
                  const PlantNowRibbon(),
                  const SizedBox(height: AppSpacing.xs + 2),
                ],
                Text(
                  p.commonName,
                  style: AppText.cardTitle.copyWith(color: AppColors.soil900),
                ),
                const SizedBox(height: AppSpacing.xs),
                CompatBadge(score: plant.compatibility.score),
                const SizedBox(height: AppSpacing.xs + 2),
                if (timeToGrow != null)
                  _Line(
                    icon: Symbols.schedule_rounded,
                    color: AppColors.leaf700,
                    filled: false,
                    text: timeToGrow,
                  ),
                _Line(
                  icon: Symbols.water_drop_rounded,
                  color: AppColors.frost,
                  text: careTimeLabel(p.care),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Wrap(
                  spacing: AppSpacing.xs + 2,
                  runSpacing: AppSpacing.xs,
                  children: [
                    MaintenancePill(level: p.maintenanceLevel),
                    if (state == PlantCardState.indoorOnly)
                      const _Chip('Indoor / greenhouse'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.color,
    required this.text,
    this.filled = true,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
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
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

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
          text,
          style: AppText.label.copyWith(color: AppColors.soil900),
        ),
      ),
    );
  }
}
