import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/domain/onboarding_draft.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/space_rules.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/onboarding/presentation/space_step_screen.dart';

import '../helpers/onboarding_harness.dart';

void main() {
  test('comparison label boundaries', () {
    const expected = {
      2: 'a windowsill',
      4: 'a windowsill',
      8: 'a few big pots',
      16: 'a few big pots',
      32: 'a 4×8 raised bed',
      64: 'a small vegetable garden',
      128: 'a small vegetable garden',
      256: 'a big garden',
      500: 'a big garden',
    };
    expected.forEach((n, label) {
      expect(areaComparisonLabel(n), label, reason: '$n sq ft');
    });
  });

  test('derived defaults per space type', () {
    for (final on in [true, false]) {
      expect(derivedSpaceDefaults(SpaceType.windowsill, on), (
        rainExposed: false,
        inContainerDefault: true,
      ));
      expect(derivedSpaceDefaults(SpaceType.balcony, on), (
        rainExposed: on,
        inContainerDefault: true,
      ));
      for (final t in [
        SpaceType.smallYard,
        SpaceType.largeYard,
        SpaceType.communityPlot,
      ]) {
        expect(derivedSpaceDefaults(t, on), (
          rainExposed: true,
          inContainerDefault: false,
        ));
      }
    }
  });

  testWidgets('space types, default areas, rain switch and sun', (
    tester,
  ) async {
    final h = await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.space,
      screen: const SpaceStepScreen(),
      // Tall enough that every option is on screen under the test font.
      size: const Size(360, 2400),
    );
    OnboardingDraft draft() => h.container.read(onboardingDraftProvider);
    expect(find.text('Where will your plants live?'), findsOneWidget);
    for (final sub in [
      'A sunny window or indoor shelf',
      'Pots and containers outside',
      'Under 50 sq ft of ground',
      '50+ sq ft of ground',
      'A shared garden bed',
    ]) {
      expect(find.text(sub), findsOneWidget);
    }
    expect(find.text('CONTINUE'), findsOneWidget);

    const defaults = {
      'Windowsill / indoors': (SpaceType.windowsill, 4),
      'Balcony or patio': (SpaceType.balcony, 16),
      'Small yard bed': (SpaceType.smallYard, 32),
      'Large yard': (SpaceType.largeYard, 128),
      'Community plot': (SpaceType.communityPlot, 64),
    };
    for (final MapEntry(key: title, value: (type, area)) in defaults.entries) {
      await tester.tap(find.text(title));
      await tester.pump();
      expect(draft().spaceType, type);
      expect(draft().areaSqFt, area);
      expect(draft().rainExposed, type != SpaceType.windowsill);
    }
    expect(
      find.text('Rain reaches my plants', skipOffstage: false),
      findsNothing,
    );

    await tester.tap(find.text('Balcony or patio'));
    await tester.pump();
    expect(find.text('Rain reaches my plants'), findsOneWidget);
    expect(draft().rainExposed, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(draft().rainExposed, isFalse);

    expect(find.text('≈ 16 sq ft · a few big pots'), findsOneWidget);
    expect(find.text('About how much room?'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(4); // stop 4 = 32 sq ft
    await tester.pump();
    expect(draft().areaSqFt, 32);
    expect(find.text('≈ 32 sq ft · a 4×8 raised bed'), findsOneWidget);

    await tester.tap(find.text('Not sure'));
    await tester.pump();
    expect(draft().sun, SunLevel.partial);
    expect(draft().sunUnsure, isTrue);

    await tester.tap(find.text('Full sun'));
    await tester.pump();
    expect(draft().sun, SunLevel.full);
    expect(draft().sunUnsure, isFalse);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.goals), findsOneWidget);
  });
}
