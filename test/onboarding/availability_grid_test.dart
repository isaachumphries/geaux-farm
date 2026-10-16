import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/domain/availability_edits.dart';
import 'package:geaux_farm/features/onboarding/presentation/availability_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';

import '../helpers/onboarding_harness.dart';

Finder _cell(int day, int block) => find.byKey(ValueKey('cell-$day-$block'));

Future<List<int> Function()> _pump(WidgetTester tester) async {
  final h = await pumpOnboardingStep(
    tester,
    route: OnboardingRoutes.time,
    screen: const AvailabilityStepScreen(),
    size: const Size(360, 1400),
  );
  return () => h.container.read(onboardingDraftProvider).availability;
}

void main() {
  test('presets OR their cells in; Clear empties', () {
    final sat = setBlock(List.filled(7, 0), 5, 1, true);
    expect(applyPreset(sat, AvailabilityPreset.weekdayMornings), [
      1,
      1,
      1,
      1,
      1,
      2,
      0,
    ]);
    expect(applyPreset(List.filled(7, 0), AvailabilityPreset.weekdayEvenings), [
      64,
      64,
      64,
      64,
      64,
      0,
      0,
    ]);
    expect(applyPreset(List.filled(7, 0), AvailabilityPreset.weekendMornings), [
      0,
      0,
      0,
      0,
      0,
      6,
      6,
    ]);
    expect(
      applyPreset([1, 2, 3, 4, 5, 6, 7], AvailabilityPreset.clear),
      List.filled(7, 0),
    );
  });

  testWidgets('labels: Mon–Sun columns and 6 AM–8 PM rows', (tester) async {
    await _pump(tester);
    expect(find.text('When can you tend your plants?'), findsOneWidget);
    expect(
      find.text(
        "Drag to paint the times you're usually free. We'll only send "
        'reminders then.',
      ),
      findsOneWidget,
    );
    for (final l in [...dayLabels, ...blockLabels]) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
  });

  testWidgets('demo painting stores the plan value and summary', (
    tester,
  ) async {
    final value = await _pump(tester);
    for (final (d, b) in [(0, 6), (2, 6), (5, 1), (6, 1)]) {
      await tester.tap(_cell(d, b));
      await tester.pump();
    }
    expect(value(), [64, 0, 64, 0, 0, 2, 2]);
    expect(find.text('4 care days · 8 hrs/week'), findsOneWidget);
  });

  testWidgets('a tap toggles one cell with a light haptic', (tester) async {
    final value = await _pump(tester);
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(_cell(3, 4));
    await tester.pump();
    expect(isBlockSet(value(), 3, 4), isTrue);
    await tester.tap(_cell(3, 4));
    await tester.pump();
    expect(value(), List.filled(7, 0));
    expect(haptics, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });

  testWidgets('a drag from an empty cell paints every cell it crosses', (
    tester,
  ) async {
    final value = await _pump(tester);
    final from = tester.getCenter(_cell(0, 2));
    final to = tester.getCenter(_cell(2, 2));
    final gesture = await tester.startGesture(from);
    await gesture.moveTo(tester.getCenter(_cell(1, 2)));
    await gesture.moveTo(to);
    await gesture.up();
    await tester.pump();
    expect(value(), [4, 4, 4, 0, 0, 0, 0]);
  });

  testWidgets('a drag from a selected cell erases every cell it crosses', (
    tester,
  ) async {
    final value = await _pump(tester);
    await tester.tap(find.text('Weekday mornings'));
    await tester.pump();
    expect(value(), [1, 1, 1, 1, 1, 0, 0]);
    final gesture = await tester.startGesture(tester.getCenter(_cell(1, 0)));
    await gesture.moveTo(tester.getCenter(_cell(2, 0)));
    await gesture.moveTo(tester.getCenter(_cell(3, 0)));
    await gesture.up();
    await tester.pump();
    expect(value(), [1, 0, 0, 0, 1, 0, 0]);
  });

  testWidgets('presets, Clear and Not sure through the chips', (tester) async {
    final value = await _pump(tester);
    await tester.tap(_cell(5, 1));
    await tester.pump();
    await tester.tap(find.text('Weekday mornings'));
    await tester.pump();
    expect(value(), [1, 1, 1, 1, 1, 2, 0]);
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(value(), List.filled(7, 0));
    await tester.tap(find.text('Not sure? Use 8–10 AM every day'));
    await tester.pump();
    expect(value(), List.filled(7, 2));
  });

  testWidgets('Continue is disabled with 0 blocks and enabled with 1', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.source), findsNothing);
    await tester.tap(_cell(0, 0));
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.source), findsOneWidget);
  });
}
