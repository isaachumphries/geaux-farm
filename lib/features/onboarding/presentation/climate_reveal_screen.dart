import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import 'onboarding_climate_provider.dart';
import 'onboarding_draft_provider.dart';
import 'onboarding_routes.dart';
import 'onboarding_scaffold.dart';
import 'widgets/climate_reveal_card.dart';

/// OB-02b Climate reveal: the climate card for the chosen city. No step
/// dot.
class ClimateRevealScreen extends ConsumerWidget {
  const ClimateRevealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final climate = ref.watch(onboardingClimateProvider);
    final draft = ref.watch(onboardingDraftProvider);
    void toSpace() => context.push(OnboardingRoutes.space);

    final place = [
      draft.city,
      draft.admin1,
    ].whereType<String>().where((p) => p.isNotEmpty).join(', ');

    return OnboardingScaffold(
      route: OnboardingRoutes.climate,
      bottom: climate.hasValue && !climate.isLoading && !climate.hasError
          ? GeauxButton(label: 'Looks right', onPressed: toSpace)
          : null,
      child: switch (climate) {
        AsyncValue(isLoading: true) => const _Loading(),
        AsyncValue(hasError: false, :final value?) => ListView(
          children: [
            if (place.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Symbols.location_on_rounded,
                    color: AppColors.leaf700,
                    fill: 1,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      place,
                      style: AppText.h1.copyWith(color: AppColors.soil900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ClimateRevealCard(profile: value, lat: draft.lat ?? 0),
          ],
        ),
        _ => _Error(
          onRetry: () => ref.read(onboardingClimateProvider.notifier).retry(),
          onContinue: toSpace,
        ),
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.leaf500),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Reading 5 years of local weather…',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppColors.soil600),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry, required this.onContinue});

  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Symbols.cloud_off_rounded,
          size: 48,
          color: AppColors.soil600,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Couldn't load climate data.",
          textAlign: TextAlign.center,
          style: AppText.h2.copyWith(color: AppColors.soil900),
        ),
        const SizedBox(height: AppSpacing.xl),
        GeauxButton(label: 'Retry', onPressed: onRetry),
        const SizedBox(height: AppSpacing.md),
        GeauxButton(
          label: 'Continue anyway',
          variant: GeauxButtonVariant.secondary,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
