import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/goals_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';

import '../helpers/onboarding_harness.dart';

void main() {
  testWidgets('Continue is disabled with 0 goals and enabled with 1', (
    tester,
  ) async {
    await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.goals,
      screen: const GoalsStepScreen(),
    );
    expect(find.text('Why do you want to grow?'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.time), findsNothing);

    await tester.tap(find.text('Food'));
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.time), findsOneWidget);
  });

  testWidgets('Other reveals a field capped at 60 characters', (tester) async {
    final h = await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.goals,
      screen: const GoalsStepScreen(),
    );
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Other'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'x' * 61);
    await tester.pump();
    final draft = h.container.read(onboardingDraftProvider);
    expect(draft.goals, {Goal.other});
    expect(draft.goalOtherText, 'x' * 60);
  });

  testWidgets('experience defaults to beginner and maps each label', (
    tester,
  ) async {
    final h = await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.goals,
      screen: const GoalsStepScreen(),
    );
    Experience? experience() =>
        h.container.read(onboardingDraftProvider).experience;
    expect(find.text('Have you grown plants before?'), findsOneWidget);

    await tester.tap(find.text('A little'));
    await tester.pump();
    expect(experience(), Experience.intermediate);
    await tester.tap(find.text('A lot'));
    await tester.pump();
    expect(experience(), Experience.expert);
    await tester.tap(find.text('New to this'));
    await tester.pump();
    expect(experience(), Experience.beginner);
  });

  testWidgets('Continue without touching experience stores beginner', (
    tester,
  ) async {
    final h = await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.goals,
      screen: const GoalsStepScreen(),
    );
    await tester.tap(find.text('Hobby'));
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    final draft = h.container.read(onboardingDraftProvider);
    expect(draft.experience, Experience.beginner);
    expect(draft.goals, {Goal.hobby});
  });

  testWidgets('unticking Other clears its text', (tester) async {
    final h = await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.goals,
      screen: const GoalsStepScreen(),
    );
    await tester.tap(find.text('Other'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Medicinal herbs');
    await tester.tap(find.text('Other'));
    await tester.pump();
    expect(h.container.read(onboardingDraftProvider).goalOtherText, isNull);
    await tester.tap(find.text('Other'));
    await tester.pump();
    expect(find.text('Medicinal herbs'), findsNothing);
  });
}
