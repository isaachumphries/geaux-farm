import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/app/titled_scaffold.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../helpers/app_harness.dart';

/// Pumps the whole app with [profile] and returns its router.
Future<GoRouter> _pumpApp(WidgetTester tester, UserProfile profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: appOverrides(profile: profile),
      child: const GeauxFarmApp(),
    ),
  );
  // One frame for the profile stream, one for the router.
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(GeauxFarmApp)))
      .read(goRouterProvider);
}

Uri _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri;

Future<void> _go(WidgetTester tester, GoRouter router, String path) async {
  router.go(path);
  await tester.pump();
  await tester.pump();
}

String _title(WidgetTester tester) =>
    tester.widget<TitledScaffold>(find.byType(TitledScaffold).last).title;

void main() {
  group('redirect', () {
    testWidgets('not onboarded: /home goes to /onboarding/welcome', (
      tester,
    ) async {
      expect(defaultUserProfile.onboardingCompletedAt, isNull);
      final router = await _pumpApp(tester, defaultUserProfile);

      // The initial location is /home; the redirect sends it to OB-01.
      expect(_location(router).path, onboardingStart);
      expect(_title(tester), 'OB-01 Welcome');

      await _go(tester, router, '/garden');
      expect(_location(router).path, onboardingStart);

      // Onboarding steps themselves are reachable.
      await _go(tester, router, '/onboarding/space');
      expect(_location(router).path, '/onboarding/space');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('onboarded: lands on /home and never redirects', (
      tester,
    ) async {
      final router = await _pumpApp(tester, onboardedProfile);
      expect(_location(router).path, '/home');
      expect(find.byType(HomeFirstRunScreen), findsOneWidget);

      await _go(tester, router, onboardingStart);
      expect(_location(router).path, onboardingStart);

      await _go(tester, router, '/home');
      expect(_location(router).path, '/home');
      expect(find.byType(HomeFirstRunScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    test('onboardingRedirect waits for the profile to load', () {
      expect(
        onboardingRedirect(const AsyncLoading(), Uri.parse('/home')),
        isNull,
      );
      expect(
        onboardingRedirect(AsyncData(defaultUserProfile), Uri.parse('/home')),
        onboardingStart,
      );
      expect(
        onboardingRedirect(
          AsyncData(defaultUserProfile),
          Uri.parse('/onboarding/time'),
        ),
        isNull,
      );
      expect(
        onboardingRedirect(AsyncData(onboardedProfile), Uri.parse('/care')),
        isNull,
      );
    });
  });

  testWidgets('every route resolves to its screen or placeholder', (
    tester,
  ) async {
    final router = await _pumpApp(tester, onboardedProfile);
    const placeholders = {
      '/onboarding/welcome': 'OB-01 Welcome',
      '/onboarding/location': 'OB-02 Location',
      '/onboarding/climate': 'OB-02b Climate reveal',
      '/onboarding/space': 'OB-03 Space',
      '/onboarding/goals': 'OB-04 Goals',
      '/onboarding/time': 'OB-05 Availability',
      '/onboarding/source': 'OB-06 Heard about us',
      '/onboarding/summary': 'OB-07 Profile summary',
      '/home/recommendations': 'RC-01 Recommendations',
      '/plants/kale': 'PD-01 Plant detail',
      '/weather': 'WX-01 Weather',
      '/settings': 'ST-01 Settings',
      '/settings/edit/space': 'OB-07 Edit step',
      '/garden': 'GD-01 My Garden',
      '/garden/planting/p1': 'GD-02 Planting detail',
      '/garden/project/g1': 'GD-03 Guide project',
      '/care': 'CR-01 Care schedule',
      '/community': 'CM-01 Feed',
      '/community/guide/g1': 'CM-02 Guide detail',
      '/community/editor/new': 'CM-03 Editor',
      '/community/me': 'CM-05 My profile',
    };
    for (final MapEntry(key: path, value: title) in placeholders.entries) {
      await _go(tester, router, path);
      expect(_location(router).path, path);
      expect(_title(tester), title, reason: path);
    }

    await _go(tester, router, '/home');
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('/care?date=2026-10-07 exposes the date', (tester) async {
    final router = await _pumpApp(tester, onboardedProfile);
    await _go(tester, router, '/care?date=2026-10-07');

    final uri = _location(router);
    expect(uri.path, '/care');
    expect(uri.queryParameters['date'], '2026-10-07');
    expect(careDateFrom(uri), DateTime(2026, 10, 7));
    expect(_title(tester), 'CR-01 Care schedule');
    await tester.pumpWidget(const SizedBox());
  });

  test('careDateFrom rejects a missing or malformed date', () {
    expect(careDateFrom(Uri.parse('/care')), isNull);
    expect(careDateFrom(Uri.parse('/care?date=tomorrow')), isNull);
    expect(careDateFrom(Uri.parse('/care?date=2026-10-07T10:00')), isNull);
  });

  testWidgets('each tab keeps its own location', (tester) async {
    final router = await _pumpApp(tester, onboardedProfile);

    await tester.tap(find.text('Garden'));
    await tester.pump();
    await _go(tester, router, '/garden/planting/p1');
    expect(_title(tester), 'GD-02 Planting detail');

    await tester.tap(find.text('Care'));
    await tester.pump();
    expect(_location(router).path, '/care');

    await tester.tap(find.text('Garden'));
    await tester.pump();
    expect(_location(router).path, '/garden/planting/p1');

    // Tapping the active tab again returns it to its root.
    await tester.tap(find.text('Garden'));
    await tester.pump();
    expect(_location(router).path, '/garden');

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(_location(router).path, '/home');
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the Home gear opens Settings', (tester) async {
    final router = await _pumpApp(tester, onboardedProfile);
    await tester.tap(find.byIcon(Symbols.settings_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Settings is pushed over Home, so Back returns there.
    expect(find.text('ST-01 Settings'), findsOneWidget);
    expect(router.canPop(), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
