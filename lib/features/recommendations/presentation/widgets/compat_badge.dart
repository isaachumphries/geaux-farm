import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../domain/compat_level.dart';
import '../../domain/compatibility.dart';

/// "{score} · {label}" pill in the band's color (plan/04 § Labels).
class CompatBadge extends StatelessWidget {
  const CompatBadge({super.key, required this.score});

  final int score;

  /// The band's label, e.g. "Great fit".
  static String labelFor(CompatLevel level) => switch (level) {
    CompatLevel.great => 'Great fit',
    CompatLevel.good => 'Good fit',
    CompatLevel.possible => 'Possible with care',
    CompatLevel.indoor => 'Tough here',
  };

  @override
  Widget build(BuildContext context) {
    final level = compatLevelFor(score);
    // Text colors keep at least 4.5:1 contrast on each fill.
    final (Color fill, Color ink, IconData icon) = switch (level) {
      CompatLevel.great => (
        AppColors.great,
        AppColors.white,
        Symbols.verified_rounded,
      ),
      CompatLevel.good => (
        AppColors.good,
        AppColors.soil900,
        Symbols.thumb_up_rounded,
      ),
      CompatLevel.possible => (
        AppColors.possible,
        AppColors.soil900,
        Symbols.volunteer_activism_rounded,
      ),
      CompatLevel.indoor => (
        AppColors.indoor,
        AppColors.white,
        Symbols.house_rounded,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          3,
          AppSpacing.sm + 2,
          3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.sm, color: ink, fill: 1),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                '$score · ${labelFor(level)}',
                style: AppText.label.copyWith(color: ink, letterSpacing: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
