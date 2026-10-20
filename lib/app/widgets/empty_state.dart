import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme.dart';

/// Centered "nothing here" block: a round icon tile over a [message].
///
/// Screens pass their own copy (plan/01 `EmptyState` has no fixed text), an
/// optional [icon], and an [action] such as a retry button for errors.
class GeauxEmptyState extends StatelessWidget {
  const GeauxEmptyState({
    super.key,
    required this.message,
    this.icon = Symbols.task_alt_rounded,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.leaf100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.leaf500),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.cardTitle.copyWith(color: AppColors.soil600),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
