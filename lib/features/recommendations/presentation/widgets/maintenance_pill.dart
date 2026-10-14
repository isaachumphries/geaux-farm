import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../catalog/domain/plant.dart';

/// "Low care" / "Medium care" / "High care" chip from the plant's
/// maintenance level (plan/03 § Derived values).
class MaintenancePill extends StatelessWidget {
  const MaintenancePill({super.key, required this.level});

  final MaintenanceLevel level;

  static String labelFor(MaintenanceLevel level) => switch (level) {
    MaintenanceLevel.low => 'Low care',
    MaintenanceLevel.medium => 'Medium care',
    MaintenanceLevel.high => 'High care',
  };

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color ink) = switch (level) {
      MaintenanceLevel.low => (AppColors.leaf100, AppColors.leaf700),
      MaintenanceLevel.medium => (AppColors.gold100, AppColors.soil900),
      MaintenanceLevel.high => (AppColors.tilePeach, AppColors.soil900),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
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
            Icon(
              Symbols.bolt_rounded,
              size: AppIconSize.xs,
              color: ink,
              fill: 1,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Flexible(
              child: Text(
                labelFor(level),
                style: AppText.label.copyWith(color: ink, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
