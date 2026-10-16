import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/availability.dart';
import '../domain/availability_edits.dart';
import 'onboarding_draft_provider.dart';
import 'onboarding_routes.dart';
import 'onboarding_scaffold.dart';
import 'widgets/availability_grid.dart';

/// OB-05 Availability: paint the weekly free time. Step dot 4.
class AvailabilityStepScreen extends ConsumerWidget {
  const AvailabilityStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(
      onboardingDraftProvider.select((d) => d.availability),
    );
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final availability = Availability(days);
    final any = days.any((d) => d != 0);

    return OnboardingScaffold(
      route: OnboardingRoutes.time,
      step: 4,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${availability.careDays} care days · '
            '${availability.hoursPerWeek} hrs/week',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              color: any ? AppColors.leaf700 : AppColors.soil600,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GeauxButton(
            label: 'Continue',
            onPressed: any ? () => context.push(OnboardingRoutes.source) : null,
          ),
        ],
      ),
      child: ListView(
        children: [
          Text(
            'When can you tend your plants?',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Drag to paint the times you're usually free. We'll only send "
            'reminders then.',
            style: AppText.body.copyWith(color: AppColors.soil600),
          ),
          const SizedBox(height: AppSpacing.lg),
          AvailabilityGrid(value: days, onChanged: notifier.setAvailability),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final preset in AvailabilityPreset.values)
                _PresetChip(
                  label: preset.label,
                  onTap: () =>
                      notifier.setAvailability(applyPreset(days, preset)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  notifier.setAvailability(notSureAvailability(days)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.leaf700,
                textStyle: AppText.bodySm.copyWith(fontWeight: FontWeight.w800),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                minimumSize: const Size(0, AppSpacing.minTouchTarget),
              ),
              child: const Text('Not sure? Use 8–10 AM every day'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small ledge pill that adds a preset's blocks.
class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        label,
        style: AppText.bodySm.copyWith(
          color: AppColors.soil900,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
