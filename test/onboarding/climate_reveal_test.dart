import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/climate_reveal_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_climate_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';

import '../helpers/onboarding_harness.dart';
import '../recommendations/fixtures/baton_rouge.dart' as fx;

/// Answers each build from [next]; counts builds.
class FakeOnboardingClimate extends OnboardingClimateNotifier {
  FakeOnboardingClimate(this.next);

  final Future<ClimateProfile> Function(int build) next;
  static int builds = 0;

  @override
  Future<ClimateProfile> build() => next(++builds);
}

Future<void> _pump(
  WidgetTester tester,
  Future<ClimateProfile> Function(int build) next,
) async {
  FakeOnboardingClimate.builds = 0;
  await pumpOnboardingStep(
    tester,
    route: OnboardingRoutes.climate,
    screen: const ClimateRevealScreen(),
    overrides: [
      onboardingClimateProvider.overrideWith(() => FakeOnboardingClimate(next)),
    ],
  );
}

void main() {
  testWidgets('shows the loading copy before the profile resolves', (
    tester,
  ) async {
    final pending = Completer<ClimateProfile>();
    await _pump(tester, (_) => pending.future);
    expect(find.text('Reading 5 years of local weather…'), findsOneWidget);
    expect(find.text('LOOKS RIGHT'), findsNothing);
  });

  testWidgets('renders the Baton Rouge card and Looks right opens Space', (
    tester,
  ) async {
    await _pump(tester, (_) async => fx.batonRougeClimate);
    await tester.pump();
    for (final line in [
      'Zone 8b',
      'Summer highs ~92°F',
      'Winter lows ~43°F',
      '58 in of rain a year',
      'Humid',
      'Last spring frost ~Feb 20',
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    await tester.tap(find.text('LOOKS RIGHT'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.space), findsOneWidget);
  });

  testWidgets('a failed build shows the error; Retry builds again', (
    tester,
  ) async {
    await _pump(tester, (build) async {
      if (build == 1) throw Exception('archive down');
      return fx.batonRougeClimate;
    });
    await tester.pump();
    expect(find.text("Couldn't load climate data."), findsOneWidget);
    expect(find.text('CONTINUE ANYWAY'), findsOneWidget);

    await tester.tap(find.text('RETRY'));
    await tester.pump();
    await tester.pump();
    expect(FakeOnboardingClimate.builds, 2);
    expect(find.text('Zone 8b'), findsOneWidget);
  });

  testWidgets('Continue anyway opens Space', (tester) async {
    await _pump(tester, (_) async => throw Exception('archive down'));
    await tester.pump();
    await tester.tap(find.text('CONTINUE ANYWAY'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingRoutes.space), findsOneWidget);
  });
}
