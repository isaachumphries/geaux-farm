import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/user_profile.dart';
import 'onboarding_draft_provider.dart';
import 'onboarding_routes.dart';
import 'onboarding_scaffold.dart';

/// Longest free-text answer for Other (plan/02).
const otherTextMaxLength = 60;

/// Goal options in plan/02 order: goal, title, subtitle, icon.
const _goalOptions = [
  (Goal.food, 'Food', 'Herbs, veggies & fruit', Symbols.nutrition_rounded),
  (
    Goal.design,
    'Design',
    'Flowers, shrubs & curb appeal',
    Symbols.local_florist_rounded,
  ),
  (
    Goal.hobby,
    'Hobby',
    'Something calming to care for',
    Symbols.self_improvement_rounded,
  ),
  (Goal.other, 'Other', null, Symbols.more_horiz_rounded),
];

const _experienceOptions = [
  (Experience.beginner, 'New to this'),
  (Experience.intermediate, 'A little'),
  (Experience.expert, 'A lot'),
];

/// OB-04 Goals: why the user grows (at least one) and their experience.
/// Step dot 3.
class GoalsStepScreen extends ConsumerStatefulWidget {
  const GoalsStepScreen({super.key});

  @override
  ConsumerState<GoalsStepScreen> createState() => _GoalsStepScreenState();
}

class _GoalsStepScreenState extends ConsumerState<GoalsStepScreen> {
  late final TextEditingController _other;

  @override
  void initState() {
    super.initState();
    _other = TextEditingController(
      text: ref.read(onboardingDraftProvider).goalOtherText,
    );
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _continue() {
    final notifier = ref.read(onboardingDraftProvider.notifier);
    // The control shows New to this until the user picks another answer.
    if (ref.read(onboardingDraftProvider).experience == null) {
      notifier.setExperience(Experience.beginner);
    }
    context.push(OnboardingRoutes.time);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final experience = draft.experience ?? Experience.beginner;

    return OnboardingScaffold(
      route: OnboardingRoutes.goals,
      step: 3,
      bottom: GeauxButton(
        label: 'Continue',
        onPressed: draft.goals.isEmpty ? null : _continue,
      ),
      child: ListView(
        children: [
          Text(
            'Why do you want to grow?',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (goal, title, subtitle, icon) in _goalOptions) ...[
            GeauxSelectCard(
              title: title,
              subtitle: subtitle,
              icon: icon,
              multiSelect: true,
              selected: draft.goals.contains(goal),
              onTap: () => notifier.toggleGoal(goal),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (draft.goals.contains(Goal.other)) ...[
            GeauxTextField(
              key: const ValueKey('goal-other-text'),
              controller: _other,
              maxLength: otherTextMaxLength,
              onChanged: notifier.setGoalOtherText,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Have you grown plants before?',
            style: AppText.cardTitle.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.md),
          GeauxSegmentedChoice<Experience>(
            options: _experienceOptions,
            selected: experience,
            onSelected: notifier.setExperience,
          ),
        ],
      ),
    );
  }
}
