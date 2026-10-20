import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';

/// The row of day chips at the top of CR-01: weekday, date number, and a dot
/// under days that have tasks.
class CareDaySelector extends StatelessWidget {
  const CareDaySelector({
    super.key,
    required this.days,
    required this.selected,
    required this.hasTasks,
    required this.onSelect,
  });

  /// Local midnights, in order.
  final List<DateTime> days;
  final DateTime selected;
  final bool Function(DateTime day) hasTasks;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _DayChip(
              day: days[i],
              selected: days[i] == selected,
              dot: hasTasks(days[i]),
              onTap: () => onSelect(days[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.dot,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.soil900;
    const radius = BorderRadius.all(Radius.circular(AppRadii.card));
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat.MMMEd().format(day),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.leafLedge : AppColors.stone200,
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppBorders.ledge - 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? AppColors.leaf700 : AppColors.white,
                borderRadius: radius,
                border: selected
                    ? null
                    : Border.all(
                        color: AppColors.stone200,
                        width: AppBorders.width,
                      ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat.E().format(day),
                      maxLines: 1,
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.white : AppColors.soil600,
                      ),
                    ),
                    Text('${day.day}', style: AppText.h2.copyWith(color: fg)),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: dot
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.geauxGold
                                    : AppColors.leaf500,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
