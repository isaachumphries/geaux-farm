import 'package:flutter/material.dart';

import '../theme.dart';
import 'card.dart';

enum GeauxButtonVariant { primary, secondary, text }

/// A full-width ledge button (primary, secondary) or an uppercase text
/// action (text). Disabled, and never fires, when [onPressed] is null.
class GeauxButton extends StatelessWidget {
  const GeauxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GeauxButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final GeauxButtonVariant variant;

  /// Optional glyph before the label on primary and secondary buttons.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Color fg = switch (variant) {
      _ when !enabled => AppColors.soil600,
      GeauxButtonVariant.primary => AppColors.white,
      GeauxButtonVariant.secondary ||
      GeauxButtonVariant.text => AppColors.leaf700,
    };
    final caption = Text(
      label.toUpperCase(),
      textAlign: TextAlign.center,
      style: AppText.button.copyWith(color: fg),
    );
    final glyph = icon;
    final Widget text = glyph == null
        ? caption
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              Icon(glyph, size: AppIconSize.md, color: fg),
              caption,
            ],
          );

    final Widget body;
    if (variant == GeauxButtonVariant.text) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Center(widthFactor: 1, child: text),
          ),
        ),
      );
    } else {
      final primary = variant == GeauxButtonVariant.primary;
      body = GeauxCard(
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        color: !enabled
            ? AppColors.stone200
            : primary
            ? AppColors.leaf700
            : AppColors.white,
        borderColor: primary || !enabled ? null : AppColors.stone200,
        ledgeColor: !enabled
            ? AppColors.stone200
            : primary
            ? AppColors.leafLedge
            : AppColors.stone200,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(heightFactor: 1, child: text),
        ),
      );
    }
    return MergeSemantics(
      child: Semantics(button: true, enabled: enabled, child: body),
    );
  }
}
