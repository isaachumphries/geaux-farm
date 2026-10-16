import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/data/attribution_repository.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/heard_about_us_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';

import '../helpers/onboarding_harness.dart';

/// Records calls; never sends anything.
class FakeAttribution implements AttributionRepository {
  final calls = <(HeardFrom, String?)>[];

  @override
  Future<void> submit(HeardFrom source, String? otherText) async =>
      calls.add((source, otherText));
}

Future<({FakeAttribution fake, ProviderContainer container})> _pump(
  WidgetTester tester,
) async {
  final fake = FakeAttribution();
  final h = await pumpOnboardingStep(
    tester,
    route: OnboardingRoutes.source,
    screen: const HeardAboutUsScreen(),
    overrides: [attributionRepositoryProvider.overrideWithValue(fake)],
    size: const Size(360, 1400),
  );
  return (fake: fake, container: h.container);
}

void main() {
  testWidgets('title, the seven options in order, Continue gated', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('How did you hear about Geaux Farm?'), findsOneWidget);
    final labels = [
      'Friend or family',
      'Instagram',
      'TikTok',
      'App Store / Google Play',
      'LSU / campus',
      'Farmers market',
      'Other',
    ];
    final ys = [for (final l in labels) tester.getCenter(find.text(l)).dy];
    expect(ys, [...ys]..sort());

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.summary), findsNothing);
    await tester.tap(find.text('Instagram'));
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.summary), findsOneWidget);
  });

  testWidgets('Other reveals a field capped at 60 characters', (tester) async {
    final h = await _pump(tester);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Other'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'y' * 61);
    await tester.pump();
    final draft = h.container.read(onboardingDraftProvider);
    expect(draft.heardFrom, HeardFrom.other);
    expect(draft.heardOtherText, 'y' * 60);

    await tester.tap(find.text('TikTok'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(h.container.read(onboardingDraftProvider).heardOtherText, isNull);
  });

  testWidgets('Skip opens the summary, leaves heardFrom null, sends nothing', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Farmers market'));
    await tester.pump();
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.summary), findsOneWidget);
    expect(h.container.read(onboardingDraftProvider).heardFrom, isNull);
    expect(h.fake.calls, isEmpty);
  });

  testWidgets('Continue stores the answer for Finish and sends nothing yet', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Farmers market'));
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    final draft = h.container.read(onboardingDraftProvider);
    expect(draft.heardFrom, HeardFrom.farmersMarket);
    expect(draft.heardOtherText, isNull);
    expect(h.fake.calls, isEmpty);
  });
}
