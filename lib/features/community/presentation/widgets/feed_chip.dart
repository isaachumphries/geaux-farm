import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';

/// Horizontal padding inside a chip, from the CM-01 export.
const double _chipPaddingH = 14;

/// How much a chip without an [FeedChip.onTap] is dimmed.
const double _disabledOpacity = 0.5;

/// A pill filter chip (CM-01): white with a stone outline, leaf-700 when
/// selected. [icon] sits before the label.
///
/// Without an [onTap] the chip is dimmed and inert, for a pick that cannot
/// be made right now (the CM-03a tag picker once five tags are chosen).
class FeedChip extends StatelessWidget {
  const FeedChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.minTapHeight = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// The least height of the tappable area around the pill. The pill stays
  /// its own height, centered in it; 0 taps just the pill.
  final double minTapHeight;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.soil900;
    final enabled = onTap != null;
    final pill = Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
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
    );
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: minTapHeight == 0
              ? pill
              : ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minTapHeight),
                  child: Center(widthFactor: 1, child: pill),
                ),
        ),
      ),
    );
  }
}
