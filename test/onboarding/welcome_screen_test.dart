import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/welcome_screen.dart';
import 'package:go_router/go_router.dart';

import '../helpers/app_harness.dart';

/// A fresh install: no saved profile, so the default (not onboarded) one.
Future<GoRouter> _firstLaunch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: appOverrides(profile: defaultUserProfile),
      child: const GeauxFarmApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(GeauxFarmApp)))
      .read(goRouterProvider);
}

void main() {
  testWidgets('first launch shows Welcome with the plan/02 copy', (
    tester,
  ) async {
    final router = await _firstLaunch(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/onboarding/welcome',
    );
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Grow something at home.'), findsOneWidget);
    expect(
      find.text(
        "Tell us about your space and we'll match you with plants that "
        'thrive where you live.',
      ),
      findsOneWidget,
    );
    // GeauxButton renders labels uppercase.
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(
      find.text('Takes about 2 minutes. No account needed.'),
      findsOneWidget,
    );
    // No back button and no step dots on Welcome.
    expect(find.byTooltip('Back'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Get started opens /onboarding/location', (tester) async {
    await _firstLaunch(tester);

    await tester.tap(find.text('GET STARTED'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(WelcomeScreen, skipOffstage: false), findsOneWidget);
    expect(find.text('OB-02 Location'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
