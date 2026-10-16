import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import 'onboarding_routes.dart';

/// Shared frame for OB-02 through OB-07: a back button to the previous
/// step and, on dotted steps, the 5-dot StepProgress.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.route,
    required this.child,
    this.step,
    this.bottom,
  });

  /// This screen's route, from [OnboardingRoutes].
  final String route;

  /// 1–5 for Location..Source; null hides the progress dots.
  final int? step;
  final Widget child;

  /// Pinned under the scrolling content, e.g. the Continue button.
  final Widget? bottom;

  void _back(BuildContext context) {
    // The draft lives in a provider, so popping keeps every answer.
    if (context.canPop()) {
      context.pop();
      return;
    }
    final previous = OnboardingRoutes.previous(route);
    if (previous != null) context.go(previous);
  }

  @override
  Widget build(BuildContext context) {
    final step = this.step;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => _back(context),
                    icon: const Icon(
                      Symbols.arrow_back_rounded,
                      color: AppColors.soil900,
                    ),
                  ),
                  if (step != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GeauxStepProgress(
                        labels: onboardingStepLabels,
                        current: step - 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.minTouchTarget),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: child),
              if (bottom != null) ...[
                const SizedBox(height: AppSpacing.lg),
                bottom!,
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
