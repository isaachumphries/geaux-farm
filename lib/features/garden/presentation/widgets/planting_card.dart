import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../care/domain/stage.dart';
import '../../../catalog/presentation/plant_art.dart';
import '../../../recommendations/application/clock_provider.dart';
import '../../application/garden_provider.dart';
import '../../domain/planting.dart';
import '../../domain/planting_copy.dart';

/// A planting on GD-01 and HM-02 "Your garden": category tile, nickname,
/// where it grows, stage line, next-water chip, and growth ring.
class PlantingCard extends ConsumerWidget {
  const PlantingCard({super.key, required this.view, this.onTap});

  final PlantingView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final water = ref.watch(nextWaterProvider(view.id)).value;
    final pl = view.planting;
    final stage = view.growth;
    final planted = pl.plantedOn;
    return GeauxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PlantTile(category: view.plant.category),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pl.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(color: AppColors.soil900),
                ),
                if (pl.nickname != view.plant.commonName)
                  Text(
                    view.plant.commonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(color: AppColors.soil900),
                  ),
                Text(
                  whereLabel(view.space?.type, pl.setup),
                  style: AppText.bodySm.copyWith(color: AppColors.soil600),
                ),
                if (pl.status == PlantingStatus.harvested)
                  Text(
                    'Harvested',
                    style: AppText.label.copyWith(color: AppColors.soil600),
                  )
                else if (stage != null && planted != null)
                  StageText(
                    stage: stage.stage,
                    text: stageLine(stage.stage, planted, today),
                  ),
                if (water != null && pl.status == PlantingStatus.active) ...[
                  const SizedBox(height: AppSpacing.xs),
                  WaterChip(
                    // Overdue says "Water now"; otherwise the day of the
                    // free-time slot the watering goes in, as on CR-01.
                    label: waterChipLabel(
                      water.due.isBefore(today) ? water.due : water.slot.start,
                      today,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (stage != null &&
              stage.showsProgressRing &&
              pl.status == PlantingStatus.active) ...[
            const SizedBox(width: AppSpacing.sm),
            GrowthRing(progress: stage.progress),
          ],
        ],
      ),
    );
  }
}

/// Stage line in the stage's color with a trend icon.
class StageText extends StatelessWidget {
  const StageText({super.key, required this.stage, required this.text});

  final PlantingStage stage;
  final String text;

  static Color colorFor(PlantingStage s) => switch (s) {
    PlantingStage.sprouting => AppColors.good,
    PlantingStage.growing => AppColors.leaf700,
    PlantingStage.readyToHarvest => AppColors.heat,
    PlantingStage.blooming => AppColors.tileSkyLedge,
    PlantingStage.established => AppColors.leaf700,
  };

  static IconData iconFor(PlantingStage s) => switch (s) {
    PlantingStage.sprouting => Symbols.psychiatry_rounded,
    PlantingStage.growing => Symbols.trending_up_rounded,
    PlantingStage.readyToHarvest => Symbols.shopping_basket_rounded,
    PlantingStage.blooming => Symbols.local_florist_rounded,
    PlantingStage.established => Symbols.verified_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(stage);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(stage), size: AppIconSize.xs, color: color, fill: 1),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(text, style: AppText.label.copyWith(color: color)),
        ),
      ],
    );
  }
}

/// Sky chip with a drop: "Water Sat".
class WaterChip extends StatelessWidget {
  const WaterChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.tileSky,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Symbols.water_drop_rounded,
              size: AppIconSize.xs,
              color: AppColors.frost,
              fill: 1,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppText.label.copyWith(color: AppColors.soil900),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ring showing how far a planting is toward maturity, with the percent
/// in the middle.
class GrowthRing extends StatelessWidget {
  const GrowthRing({super.key, required this.progress, this.size = 56});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Semantics(
      label: '$pct% grown',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(progress.clamp(0.0, 1.0)),
          child: Center(
            child: Text(
              '$pct%',
              style: AppText.label.copyWith(color: AppColors.soil900),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  static const double _stroke = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(_stroke / 2);
    final track = Paint()
      ..color = AppColors.stone200
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final fill = Paint()
      ..color = AppColors.leaf500
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _stroke;
    canvas.drawArc(arc, 0, 2 * math.pi, false, track);
    if (progress > 0) {
      canvas.drawArc(arc, -math.pi / 2, 2 * math.pi * progress, false, fill);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
