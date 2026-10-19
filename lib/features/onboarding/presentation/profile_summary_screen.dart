import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../home/application/first_plant_prompt_provider.dart';
import '../data/onboarding_repository.dart';
import '../domain/availability.dart';
import '../domain/onboarding_draft.dart';
import '../domain/space.dart';
import '../domain/user_profile.dart';
import 'onboarding_draft_provider.dart';
import 'onboarding_routes.dart';
import 'onboarding_scaffold.dart';

const _spaceLabels = {
  SpaceType.windowsill: 'Windowsill / indoors',
  SpaceType.balcony: 'Balcony or patio',
  SpaceType.smallYard: 'Small yard bed',
  SpaceType.largeYard: 'Large yard',
  SpaceType.communityPlot: 'Community plot',
};

const _sunLabels = {
  SunLevel.full: 'Full sun',
  SunLevel.partial: 'Partial',
  SunLevel.shade: 'Shade',
};

const _goalLabels = {
  Goal.food: 'Food',
  Goal.design: 'Design',
  Goal.hobby: 'Hobby',
  Goal.other: 'Other',
};

const _experienceLabels = {
  Experience.beginner: 'New to this',
  Experience.intermediate: 'A little',
  Experience.expert: 'A lot',
};

/// The six summary rows in plan/02 order: label, value, and the step that
/// edits it.
List<(String, String, String)> summaryRows(OnboardingDraft d) {
  final area = d.areaSqFt;
  final days = Availability(d.availability);
  final goals = [
    for (final g in Goal.values)
      if (d.goals.contains(g))
        g == Goal.other && d.goalOtherText != null
            ? 'Other: ${d.goalOtherText}'
            : _goalLabels[g]!,
  ];
  return [
    (
      'Location',
      [d.city, d.admin1].whereType<String>().join(', '),
      OnboardingRoutes.location,
    ),
    (
      'Space',
      [
        if (d.spaceType != null) _spaceLabels[d.spaceType]!,
        if (area != null) '$area sq ft',
      ].join(' · '),
      OnboardingRoutes.space,
    ),
    (
      'Sun',
      d.sunUnsure ? 'Not sure' : (_sunLabels[d.sun] ?? ''),
      OnboardingRoutes.space,
    ),
    ('Goals', goals.join(', '), OnboardingRoutes.goals),
    (
      'Experience',
      _experienceLabels[d.experience ?? Experience.beginner]!,
      OnboardingRoutes.goals,
    ),
    (
      'Free time',
      '${days.careDays} care days · ${days.hoursPerWeek} hrs/week',
      OnboardingRoutes.time,
    ),
  ];
}

/// OB-07 Profile summary: every answer on one screen, then Finish. No step
/// dot.
class ProfileSummaryScreen extends ConsumerStatefulWidget {
  const ProfileSummaryScreen({super.key});

  @override
  ConsumerState<ProfileSummaryScreen> createState() =>
      _ProfileSummaryScreenState();
}

class _ProfileSummaryScreenState extends ConsumerState<ProfileSummaryScreen> {
  bool _saving = false;

  /// Saves the draft; [later] lands on HM-01b instead of the carousel.
  Future<void> _finish({required bool later}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .completeOnboarding(ref.read(onboardingDraftProvider));
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save. Try again.")),
      );
      return;
    }
    if (!mounted) return;
    if (later) {
      await ref.read(firstPlantPromptDismissedProvider.notifier).dismiss();
      if (!mounted) return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    return OnboardingScaffold(
      route: OnboardingRoutes.summary,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GeauxButton(
            label: 'Find my first plant',
            onPressed: _saving ? null : () => _finish(later: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          GeauxButton(
            label: "I'll set up later",
            variant: GeauxButtonVariant.text,
            onPressed: _saving ? null : () => _finish(later: true),
          ),
        ],
      ),
      child: ListView(
        children: [
          Text(
            'Your garden profile',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (label, value, step) in summaryRows(draft)) ...[
            _SummaryRow(
              label: label,
              value: value,
              onTap: () => context.go(step),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppText.overline.copyWith(color: AppColors.soil600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Symbols.edit_rounded,
            size: AppIconSize.md,
            color: AppColors.chevronMuted,
          ),
        ],
      ),
    );
  }
}
