import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _monthLetters = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

/// Twelve month cells, January first. Good planting months are filled gold;
/// the current month is outlined (plan/04 § When to plant).
class MonthStrip extends StatelessWidget {
  const MonthStrip({
    super.key,
    required this.inSeasonMonths,
    required this.currentMonth,
  });

  /// 1-based months (1 = January) that are good to plant.
  final Set<int> inSeasonMonths;

  /// 1-based month of today.
  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: AppSpacing.xs,
          children: [
            for (var month = 1; month <= 12; month++)
              Expanded(
                child: _MonthCell(
                  name: _monthNames[month - 1],
                  letter: _monthLetters[month - 1],
                  inSeason: inSeasonMonths.contains(month),
                  isCurrent: month == currentMonth,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            const _LegendItem(
              swatch: AppColors.geauxGold,
              label: 'Good time to plant',
            ),
            const _LegendItem(
              swatch: AppColors.white,
              label: 'This month',
              outlined: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.name,
    required this.letter,
    required this.inSeason,
    required this.isCurrent,
  });

  final String name;
  final String letter;
  final bool inSeason;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final ledge = inSeason ? AppColors.goldLedge : AppColors.stone200;
    final outline = BorderSide(
      color: AppColors.soil900,
      width: AppBorders.width,
    );
    final spoken = [
      name,
      if (inSeason) 'good time to plant',
      if (isCurrent) 'this month',
    ].join(', ');
    return Semantics(
      container: true,
      label: spoken,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inSeason ? AppColors.geauxGold : AppColors.cream50,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border(
            top: isCurrent ? outline : BorderSide.none,
            left: isCurrent ? outline : BorderSide.none,
            right: isCurrent ? outline : BorderSide.none,
            bottom: BorderSide(
              color: isCurrent ? AppColors.soil900 : ledge,
              width: AppBorders.ledge,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: ExcludeSemantics(
            child: Text(
              letter,
              textAlign: TextAlign.center,
              style: AppText.label.copyWith(
                color: inSeason ? AppColors.soil900 : AppColors.soil600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.swatch,
    required this.label,
    this.outlined = false,
  });

  final Color swatch;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: swatch,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: outlined
                ? Border.all(
                    color: AppColors.soil900,
                    width: AppBorders.width,
                  )
                : null,
          ),
          child: const SizedBox.square(dimension: AppIconSize.sm),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppText.caption.copyWith(color: AppColors.soil600),
        ),
      ],
    );
  }
}
