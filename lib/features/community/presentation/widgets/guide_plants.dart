import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../recommendations/domain/scored_plant.dart';
import '../../../recommendations/presentation/widgets/compat_badge.dart';
import '../../../recommendations/presentation/widgets/plant_card.dart';

const double _artSize = 48;

/// The plants of a guide, each with the user's [CompatBadge] and a way in
/// to its detail. [onOpen] gets the plant id.
class GuidePlants extends StatelessWidget {
  const GuidePlants({super.key, required this.plants, required this.onOpen});

  final List<ScoredPlant> plants;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        for (final scored in plants)
          GeauxCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: () => onOpen(scored.plant.id),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.chip + 4),
                  child: SizedBox.square(
                    dimension: _artSize,
                    child: CategoryArt(
                      category: scored.plant.category,
                      height: _artSize,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(
                        scored.plant.commonName,
                        style: AppText.body.copyWith(
                          color: AppColors.soil900,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      CompatBadge(score: scored.compatibility.score),
                    ],
                  ),
                ),
                const Icon(
                  Symbols.chevron_right_rounded,
                  color: AppColors.soil600,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
