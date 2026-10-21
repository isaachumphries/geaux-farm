import 'package:flutter/material.dart';

import '../theme.dart';
import 'card.dart';

/// Inline notice shown above a section's content: the shared container of
/// the plan/01 `AlertBanner` (garden alerts, the offline notice) and of
/// other notices such as the PD-02 outdoor warning.
///
/// Figma shape: a [tint]-filled card with an [accent] ledge, and the icon
/// in [accent] on a white chip. Callers pass the icon and tones from
/// [AppColors]; the banner owns layout only.
class GeauxAlertBanner extends StatelessWidget {
  const GeauxAlertBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.accent,
    required this.tint,
    this.lead,
  });

  /// The copy after [lead], or the whole copy when there is no [lead].
  final String message;

  /// Bold opening of the copy ("Frost Thu:"), joined to [message] by a space.
  final String? lead;
  final IconData icon;
  final Color accent;
  final Color tint;

  static const _chipSize = 40.0;
  static const _chipRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final lead = this.lead;
    final body = AppText.bodySm.copyWith(
      color: lead == null ? AppColors.soil900 : AppColors.soil600,
    );
    return GeauxCard(
      color: tint,
      borderColor: null,
      ledgeColor: accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(_chipRadius),
            ),
            child: SizedBox.square(
              dimension: _chipSize,
              child: Icon(icon, size: AppIconSize.lg, color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _chipSize),
              child: Align(
                alignment: Alignment.centerLeft,
                child: lead == null
                    ? Text(message, style: body)
                    : Text.rich(
                        TextSpan(
                          style: body,
                          children: [
                            TextSpan(
                              text: lead,
                              style: const TextStyle(
                                color: AppColors.soil900,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ' $message'),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
