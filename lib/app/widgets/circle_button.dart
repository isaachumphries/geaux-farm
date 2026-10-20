import 'package:flutter/material.dart';

import '../theme.dart';

/// Round white ledge button for screen headers: back, add, more (RC-01,
/// GD-01, GD-02).
class GeauxCircleButton extends StatelessWidget {
  const GeauxCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.stone200,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AppBorders.ledge - AppBorders.width,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.stone200,
                      width: AppBorders.width,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: AppIconSize.xl,
                      color: AppColors.soil900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen header: optional [leading] and [trailing] buttons around a
/// centered [title], or a left-aligned large title when [large].
class GeauxTopBar extends StatelessWidget {
  const GeauxTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.large = false,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool large;

  @override
  Widget build(BuildContext context) {
    const slot = SizedBox.square(dimension: AppSpacing.minTouchTarget);
    final text = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: large ? TextAlign.start : TextAlign.center,
      style: (large ? AppText.h1 : AppText.h2).copyWith(
        color: AppColors.soil900,
      ),
    );
    return Row(
      children: [
        if (!large) leading ?? slot,
        if (!large) const SizedBox(width: AppSpacing.sm),
        Expanded(child: Semantics(header: true, child: text)),
        const SizedBox(width: AppSpacing.sm),
        trailing ?? slot,
      ],
    );
  }
}
