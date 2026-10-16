import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_scaffold.dart';
import 'package:go_router/go_router.dart';

/// Dot for each dotted step, by route.
const _dots = {
  OnboardingRoutes.location: 1,
  OnboardingRoutes.space: 2,
  OnboardingRoutes.goals: 3,
  OnboardingRoutes.time: 4,
  OnboardingRoutes.source: 5,
};

/// Every onboarding route as an [OnboardingScaffold] titled with its path,
/// with a Next button that pushes the following step.
GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    for (final route in OnboardingRoutes.ordered)
      GoRoute(
        path: route,
        builder: (context, state) => OnboardingScaffold(
          route: route,
          step: _dots[route],
          bottom: route == OnboardingRoutes.summary
              ? null
              : TextButton(
                  onPressed: () => context.push(
                    OnboardingRoutes.ordered[OnboardingRoutes.ordered.indexOf(
                          route,
                        ) +
                        1],
                  ),
                  child: const Text('Next'),
                ),
          child: Text(route),
        ),
      ),
  ],
);

Future<(ProviderContainer, GoRouter)> _pump(
  WidgetTester tester,
  String initial,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = _router(initial);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return (container, router);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('shows 5 StepProgress dots labeled Location..Source', (
    tester,
  ) async {
    await _pump(tester, OnboardingRoutes.location);
    final progress = tester.widget<GeauxStepProgress>(
      find.byType(GeauxStepProgress),
    );
    expect(progress.labels, ['Location', 'Space', 'Goals', 'Time', 'Source']);
    for (final label in progress.labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('each dotted step marks its own dot active', (tester) async {
    for (final MapEntry(key: route, value: dot) in _dots.entries) {
      await _pump(tester, route);
      final progress = tester.widget<GeauxStepProgress>(
        find.byType(GeauxStepProgress),
      );
      expect(progress.current, dot - 1, reason: route);
    }
  });

  testWidgets('the climate reveal and summary have no dots', (tester) async {
    for (final route in [OnboardingRoutes.climate, OnboardingRoutes.summary]) {
      await _pump(tester, route);
      expect(find.byType(GeauxStepProgress), findsNothing, reason: route);
      expect(find.byTooltip('Back'), findsOneWidget, reason: route);
    }
  });

  testWidgets('Back pops one step and keeps the draft', (tester) async {
    final (container, router) = await _pump(tester, OnboardingRoutes.location);
    container.read(onboardingDraftProvider.notifier).state = container
        .read(onboardingDraftProvider)
        .copyWith(city: 'Baton Rouge', lat: 30.45, lon: -91.19);

    await tester.tap(find.text('Next'));
    await _settle(tester);
    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(find.text(OnboardingRoutes.space), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    expect(find.text(OnboardingRoutes.climate), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    expect(find.text(OnboardingRoutes.location), findsOneWidget);

    final draft = container.read(onboardingDraftProvider);
    expect(draft.city, 'Baton Rouge');
    expect(draft.lat, 30.45);
    expect(draft.lon, -91.19);
  });

  testWidgets('Back with nothing to pop goes to the previous step', (
    tester,
  ) async {
    await _pump(tester, OnboardingRoutes.goals);
    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    expect(find.text(OnboardingRoutes.space), findsOneWidget);
  });

  test('previous() follows the plan/02 order', () {
    expect(OnboardingRoutes.previous(OnboardingRoutes.welcome), isNull);
    expect(
      OnboardingRoutes.previous(OnboardingRoutes.location),
      OnboardingRoutes.welcome,
    );
    expect(
      OnboardingRoutes.previous(OnboardingRoutes.space),
      OnboardingRoutes.climate,
    );
    expect(
      OnboardingRoutes.previous(OnboardingRoutes.summary),
      OnboardingRoutes.source,
    );
  });
}
