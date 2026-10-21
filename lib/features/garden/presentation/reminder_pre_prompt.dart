import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';

/// PD-03 reminder pre-prompt, shown before the OS permission prompt so the
/// user knows why it is coming (plan/05 § Grow this flow).
class ReminderPrePrompt extends StatelessWidget {
  const ReminderPrePrompt({
    super.key,
    required this.onTurnOn,
    required this.onNotNow,
  });

  /// Null while an answer is being saved.
  final VoidCallback? onTurnOn;
  final VoidCallback? onNotNow;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold100,
                  borderRadius: BorderRadius.circular(AppRadii.card - 2),
                ),
                child: const Icon(
                  Symbols.notifications_active_rounded,
                  size: 28,
                  color: AppColors.goldLedge,
                  fill: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Get reminders during your free times?',
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GeauxButton(label: 'Turn on', onPressed: onTurnOn),
          const SizedBox(height: AppSpacing.sm),
          GeauxButton(
            label: 'Not now',
            variant: GeauxButtonVariant.text,
            onPressed: onNotNow,
          ),
        ],
      ),
    );
  }
}
