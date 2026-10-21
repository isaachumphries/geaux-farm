import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../home/application/first_plant_prompt_provider.dart';
import '../data/onboarding_repository.dart';
import '../data/profile_providers.dart';
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

/// How long Finish waits for the saved profile to reach the router before
/// it gives up and offers the user a retry, so a profile stream that never
/// publishes leaves a working screen instead of a dead button (#183).
const _routingStateTimeout = Duration(seconds: 5);

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
    // The committed row reaches the router through the profile stream, a
    // few turns after the transaction resolves. Navigating first hands the
    // redirect a profile that still looks un-onboarded, which bounces the
    // user back to OB-01 (#183).
    final published = await _awaitOnboardedProfile();
    if (!mounted) return;
    if (!published) {
      // Leaving now would hand the redirect that stale profile and strand
      // the user on OB-01, where nothing pulls them back out. Staying put
      // keeps Finish retryable instead: the write replaces its own row, so
      // tapping again is safe.
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save. Try again.")),
      );
      return;
    }
    context.go('/home');
  }

  /// Whether [userProfileProvider] reported a finished onboarding within
  /// [_routingStateTimeout].
  Future<bool> _awaitOnboardedProfile() async {
    bool onboarded(AsyncValue<UserProfile> p) =>
        p.hasValue && p.requireValue.onboardingCompletedAt != null;
    if (onboarded(ref.read(userProfileProvider))) return true;
    final published = Completer<void>();
    final subscription = ref.listenManual(userProfileProvider, (_, next) {
      if (onboarded(next) && !published.isCompleted) published.complete();
    });
    try {
      await published.future.timeout(_routingStateTimeout);
      return true;
    } on TimeoutException {
      return false;
    } finally {
      subscription.close();
    }
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
              // While Finish is saving, leaving for a step would unmount
              // this screen and drop the navigation it is waiting to make
              // (#183).
              onTap: _saving ? null : () => context.go(step),
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

  /// Null while Finish is saving: the row still shows its value, it just
  /// cannot be opened.
  final VoidCallback? onTap;

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
