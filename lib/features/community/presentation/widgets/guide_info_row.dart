import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../domain/guide.dart';
import '../../domain/guide_labels.dart';

const double _tileSize = 36;

/// CM-02's cost, setup time and difficulty as three equal cards.
class GuideInfoRow extends StatelessWidget {
  GuideInfoRow({super.key, required Guide guide})
    : cost = guideCostLabel(guide.estCostUsd),
      setup = guideSetupLabel(guide.setupMinutes),
      difficulty = guideDifficultyLabel(guide.difficulty);

  /// The cards for a guide still being written, whose difficulty may not
  /// be picked yet ([difficulty] null reads as "—").
  GuideInfoRow.draft({
    super.key,
    required int? estCostUsd,
    required int? setupMinutes,
    required int? difficulty,
  }) : cost = guideCostLabel(estCostUsd),
       setup = guideSetupLabel(setupMinutes),
       difficulty = difficulty == null ? '—' : guideDifficultyLabel(difficulty);

  final String cost;
  final String setup;
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Expanded(
            child: _InfoCard(
              icon: Symbols.payments_rounded,
              tile: AppColors.leaf100,
              ink: AppColors.leaf700,
              caption: 'Cost',
              value: cost,
            ),
          ),
          Expanded(
            child: _InfoCard(
              icon: Symbols.schedule_rounded,
              tile: AppColors.tileSky,
              ink: AppColors.tileSkyLedge,
              caption: 'Setup',
              value: setup,
            ),
          ),
          Expanded(
            child: _InfoCard(
              icon: Symbols.signal_cellular_alt_rounded,
              tile: AppColors.gold100,
              ink: AppColors.goldLedge,
              caption: 'Difficulty',
              value: difficulty,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
          Align(
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
          ),
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
            style: AppText.body.copyWith(
              color: AppColors.soil900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
