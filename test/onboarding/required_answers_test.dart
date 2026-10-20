import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/presentation/availability_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/onboarding/presentation/space_step_screen.dart';

import '../helpers/onboarding_harness.dart';

/// Taps Continue and reports whether it opened [next].
Future<bool> _continueOpens(WidgetTester tester, String next) async {
  await tester.tap(find.text('CONTINUE'));
  await tester.pumpAndSettle();
  return find.text(next).evaluate().isNotEmpty;
}

String _summary(int careDays, int hours) =>
    '$careDays care days · $hours hrs/week';

void main() {
  group('OB-03 Space (plan/02 § OB-03)', () {
    testWidgets('Continue needs both a space and a sun answer', (tester) async {
      await pumpOnboardingStep(
        tester,
        route: OnboardingRoutes.space,
        screen: const SpaceStepScreen(),
        size: const Size(360, 2400),
      );
      expect(await _continueOpens(tester, OnboardingRoutes.goals), isFalse);

      // Sun alone is not enough.
      await tester.tap(find.text('Full sun'));
      await tester.pump();
      expect(await _continueOpens(tester, OnboardingRoutes.goals), isFalse);
    });

    testWidgets('a space without a sun answer cannot continue', (tester) async {
      await pumpOnboardingStep(
        tester,
        route: OnboardingRoutes.space,
        screen: const SpaceStepScreen(),
        size: const Size(360, 2400),
      );
      await tester.tap(find.text('Small yard bed'));
      await tester.pump();
      expect(await _continueOpens(tester, OnboardingRoutes.goals), isFalse);

      // "Not sure" counts as an answer (stored as partial).
      await tester.tap(find.text('Not sure'));
      await tester.pump();
      expect(await _continueOpens(tester, OnboardingRoutes.goals), isTrue);
    });
  });

  group('OB-05 Availability (plan/02 § OB-05)', () {
    testWidgets('presets OR into the grid and the live summary counts care '
        'days and 2-hour blocks', (tester) async {
      await pumpOnboardingStep(
        tester,
        route: OnboardingRoutes.time,
        screen: const AvailabilityStepScreen(),
        size: const Size(360, 1400),
      );
      expect(find.text(_summary(0, 0)), findsOneWidget);

      // Sat–Sun blocks 1–2: 2 days, 4 blocks.
      await tester.tap(find.text('Weekend mornings'));
      await tester.pump();
      expect(find.text(_summary(2, 8)), findsOneWidget);

      // + Mon–Fri block 6: 7 days, 9 blocks.
      await tester.tap(find.text('Weekday evenings'));
      await tester.pump();
      expect(find.text(_summary(7, 18)), findsOneWidget);

      // + Mon–Fri block 0: 14 blocks. Re-applying a preset adds nothing.
      await tester.tap(find.text('Weekday mornings'));
      await tester.pump();
      expect(find.text(_summary(7, 28)), findsOneWidget);
      await tester.tap(find.text('Weekend mornings'));
      await tester.pump();
      expect(find.text(_summary(7, 28)), findsOneWidget);
    });

    testWidgets('Clear empties the grid and blocks Continue again; Not sure '
        'fills one block on all 7 days', (tester) async {
      await pumpOnboardingStep(
        tester,
        route: OnboardingRoutes.time,
        screen: const AvailabilityStepScreen(),
        size: const Size(360, 1400),
      );
      await tester.tap(find.text('Weekday evenings'));
      await tester.pump();
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.text(_summary(0, 0)), findsOneWidget);
      expect(await _continueOpens(tester, OnboardingRoutes.source), isFalse);

      await tester.tap(find.text('Not sure? Use 8–10 AM every day'));
      await tester.pump();
      expect(find.text(_summary(7, 14)), findsOneWidget);
      expect(await _continueOpens(tester, OnboardingRoutes.source), isTrue);
    });
  });
}
