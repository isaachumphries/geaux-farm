import 'package:flutter/material.dart';

import '../theme.dart';

/// Inline notice shown above a section's content (WX-01 offline notice).
///
/// Callers pass the icon and tones from [AppColors]; the banner owns layout
/// only. #29 feeds garden alerts through this same widget.
class GeauxAlertBanner extends StatelessWidget {
  const GeauxAlertBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String message;
  final IconData icon;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.md, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.bodySm.copyWith(color: AppColors.soil900),
            ),
          ),
        ],
      ),
    );
  }
}
