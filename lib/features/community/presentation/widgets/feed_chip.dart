import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';

/// Horizontal padding inside a chip, from the CM-01 export.
const double _chipPaddingH = 14;

/// A pill filter chip (CM-01): white with a stone outline, leaf-700 when
/// selected. [icon] sits before the label.
class FeedChip extends StatelessWidget {
  const FeedChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
            color: selected ? AppColors.leaf700 : AppColors.white,
            // The selected chip keeps an outline in its fill color so both
            // states are the same height.
            borderColor: selected ? AppColors.leaf700 : AppColors.stone200,
            ledgeColor: selected ? AppColors.leafLedge : AppColors.stone200,
            padding: const EdgeInsets.symmetric(
              horizontal: _chipPaddingH,
              vertical: AppSpacing.sm + 1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.md, color: fg),
                  const SizedBox(width: AppSpacing.xs + 2),
                ],
                Text(
                  label,
                  style: AppText.bodySm.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
