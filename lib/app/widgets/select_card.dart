import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme.dart';
import 'card.dart';

/// A tappable answer card for onboarding questions: an optional icon tile,
/// a title and subtitle, and a check mark. Selected cards turn leaf-100
/// with a leaf-500 border and ledge.
class GeauxSelectCard extends StatelessWidget {
  const GeauxSelectCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.multiSelect = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  /// Draws a square check box instead of a round radio mark.
  final bool multiSelect;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final icon = this.icon;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: !multiSelect,
      checked: multiSelect ? selected : null,
      child: GeauxCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        color: selected ? AppColors.leaf100 : AppColors.white,
        borderColor: selected ? AppColors.leaf500 : AppColors.stone200,
        ledgeColor: selected ? AppColors.leaf500 : AppColors.stone200,
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  color: selected ? AppColors.white : AppColors.leaf100,
                  borderRadius: BorderRadius.circular(AppRadii.chip + 4),
                ),
                child: Icon(
                  icon,
                  color: AppColors.leaf700,
                  fill: 1,
                  size: AppIconSize.lg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      color: selected ? AppColors.leaf700 : AppColors.soil900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppText.bodySm.copyWith(color: AppColors.soil600),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _Mark(selected: selected, square: multiSelect),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.selected, required this.square});

  final bool selected;
  final bool square;

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: selected ? AppColors.leaf500 : AppColors.white,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(6) : null,
        border: Border.all(
          color: selected ? AppColors.leaf500 : AppColors.stone200,
          width: AppBorders.width,
        ),
      ),
      child: selected
          ? const Icon(
              Symbols.check_rounded,
              size: AppIconSize.sm,
              color: AppColors.white,
              weight: 700,
            )
          : null,
    );
  }
}
