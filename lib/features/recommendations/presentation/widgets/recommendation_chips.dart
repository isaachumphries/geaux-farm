import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../domain/recommendation_filter.dart';

/// Horizontal padding inside a chip, matching the CM-01 chips.
const double _chipPaddingH = 14;

/// The chips, in the plan/04 § Filters order.
const recommendationChipOrder = <RecommendationChip>[
  RecommendationChip.all,
  RecommendationChip.food,
  RecommendationChip.herbs,
  RecommendationChip.flowers,
  RecommendationChip.shrubs,
  RecommendationChip.indoor,
  RecommendationChip.lowMaintenance,
];

/// Chip labels (plan/04 § Filters).
String recommendationChipLabel(RecommendationChip chip) => switch (chip) {
  RecommendationChip.all => 'All',
  RecommendationChip.food => 'Food',
  RecommendationChip.herbs => 'Herbs',
  RecommendationChip.flowers => 'Flowers',
  RecommendationChip.shrubs => 'Shrubs',
  RecommendationChip.indoor => 'Indoor',
  RecommendationChip.lowMaintenance => 'Low maintenance',
};

/// RC-01's single-select chip row. Scrolls sideways, because the seven
/// chips are wider than a 360 screen.
class RecommendationChipRow extends StatelessWidget {
  const RecommendationChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final RecommendationChip selected;
  final ValueChanged<RecommendationChip> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (final chip in recommendationChipOrder)
            _Chip(
              label: recommendationChipLabel(chip),
              selected: chip == selected,
              onTap: () => onSelected(chip),
            ),
        ],
      ),
    );
  }
}

/// A pill filter chip: white with a stone outline, leaf-700 when selected.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.soil900;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: LedgeCapsule(
            // The selected chip keeps an outline in its fill color so both
            // states are the same height.
            color: selected ? AppColors.leaf700 : AppColors.white,
            borderColor: selected ? AppColors.leaf700 : AppColors.stone200,
            ledgeColor: selected ? AppColors.leafLedge : AppColors.stone200,
            padding: const EdgeInsets.symmetric(
              horizontal: _chipPaddingH,
              vertical: AppSpacing.sm + 1,
            ),
            child: Text(
              label,
              style: AppText.bodySm.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
