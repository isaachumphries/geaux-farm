import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../domain/score_reasons.dart';

/// Bar thickness; the PD-01 frame bars are ~10 dp tall.
const _barHeight = 10.0;

/// Six factor rows, each with its fit percent, a bar, and a plain-language
/// reason (plan/04 § Score breakdown).
class ScoreBreakdown extends StatelessWidget {
  const ScoreBreakdown({super.key, required this.rows});

  final List<ScoreRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [for (final row in rows) _ScoreRowView(row: row)],
    );
  }
}

class _ScoreRowView extends StatelessWidget {
  const _ScoreRowView({required this.row});

  final ScoreRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              _iconFor(row.factor),
              size: AppIconSize.md,
              color: AppColors.leaf700,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                row.factor.label,
                style: AppText.bodySm.copyWith(color: AppColors.soil900),
              ),
            ),
            Text(
              '${row.percent}%',
              style: AppText.label.copyWith(
                color: AppColors.leaf700,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: ColoredBox(
            color: AppColors.stone200,
            child: SizedBox(
              height: _barHeight,
              width: double.infinity,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: row.fit.clamp(0.0, 1.0).toDouble(),
                child: const ColoredBox(color: AppColors.leaf500),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          row.reason,
          style: AppText.caption.copyWith(
            color: AppColors.soil600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

IconData _iconFor(ScoreFactor factor) => switch (factor) {
  ScoreFactor.climate => Symbols.thermostat_rounded,
  ScoreFactor.light => Symbols.light_mode_rounded,
  ScoreFactor.space => Symbols.straighten_rounded,
  ScoreFactor.care => Symbols.schedule_rounded,
  ScoreFactor.goals => Symbols.restaurant_rounded,
  ScoreFactor.experience => Symbols.school_rounded,
};
