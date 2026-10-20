import 'package:flutter/material.dart';

import '../theme.dart';

/// A fully rounded ledge surface (the Figma pill chip, round icon button and
/// FAB): a [color] face with an optional [borderColor] outline, sitting on a
/// [ledgeColor] bottom edge so the bottom is [AppBorders.ledge] thick.
class LedgeCapsule extends StatelessWidget {
  const LedgeCapsule({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color = AppColors.white,
    this.borderColor = AppColors.stone200,
    this.ledgeColor = AppColors.stone200,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? borderColor;
  final Color ledgeColor;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadii.pill));
    final border = borderColor;
    return DecoratedBox(
      decoration: BoxDecoration(color: ledgeColor, borderRadius: radius),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: AppBorders.ledge - (border == null ? 0 : AppBorders.width),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: border == null
                ? null
                : Border.all(color: border, width: AppBorders.width),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
