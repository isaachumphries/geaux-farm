import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';

/// One of the three pills under a guide's author on CM-02: an [icon], a
/// [label], and a [count] with an optional [countSuffix] ("42 growing").
///
/// [selected] draws the gold pill of a star the user gave. Without [onTap]
/// the pill is inert.
class StatButton extends StatelessWidget {
  const StatButton({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.countSuffix = '',
    this.onTap,
    this.selected = false,
  });

  final Widget icon;
  final String label;
  final int count;
  final String countSuffix;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final countText = '$count$countSuffix';
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: LedgeCapsule(
            color: selected ? AppColors.gold100 : AppColors.white,
            borderColor: selected ? AppColors.goldLedge : AppColors.stone200,
            ledgeColor: selected ? AppColors.goldLedge : AppColors.stone200,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(color: AppColors.soil900),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    countText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.soil600,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.25,
                    ),
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
