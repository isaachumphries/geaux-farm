import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../catalog/domain/plant.dart';

/// Display label for a catalog season tag. The record's tags are shown in
/// record order (plan/03 § seasonTags).
String seasonTagLabel(SeasonTag tag) => switch (tag) {
  SeasonTag.coolSeason => 'Cool-season',
  SeasonTag.warmSeason => 'Warm-season',
  SeasonTag.yearRound => 'Year-round',
  SeasonTag.evergreen => 'Evergreen',
  SeasonTag.deciduous => 'Deciduous',
  SeasonTag.perennial => 'Perennial',
  SeasonTag.winterInterest => 'Winter interest',
};

/// Outlined season tag shown on recommendation cards and PD-01.
class SeasonChip extends StatelessWidget {
  const SeasonChip({super.key, required this.tag});

  final SeasonTag tag;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.leaf500, width: AppBorders.width),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Symbols.eco_rounded,
              size: AppIconSize.xs,
              color: AppColors.leaf700,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                seasonTagLabel(tag),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(color: AppColors.soil900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
