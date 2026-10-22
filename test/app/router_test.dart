import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/care/presentation/care_screen.dart';
import 'package:geaux_farm/features/community/presentation/community_feed_screen.dart';
import 'package:geaux_farm/features/community/presentation/guide_detail_screen.dart';
import 'package:geaux_farm/features/garden/presentation/my_garden_screen.dart';
import 'package:geaux_farm/features/garden/presentation/planting_detail_screen.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/availability_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/climate_reveal_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/goals_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/heard_about_us_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/location_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/profile_summary_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/space_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/welcome_screen.dart';
import 'package:geaux_farm/features/recommendations/presentation/plant_detail_screen.dart';
import 'package:geaux_farm/features/recommendations/presentation/recommendations_screen.dart';
import 'package:geaux_farm/features/weather/presentation/weather_mini.dart';
import 'package:geaux_farm/features/weather/presentation/weather_screen.dart';
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

/// The app bar title of the top screen: a [TitledScaffold] or an
/// onboarding step stand-in.
String _title(WidgetTester tester) {
  final appBar = tester.widget<AppBar>(find.byType(AppBar).last);
  return (appBar.title! as Text).data!;
}

/// A label inside the bottom bar, since screens can repeat it (CR-01 is
/// titled "Care").
Finder _navTab(String label) => find.descendant(
  of: find.byType(GeauxBottomNav),
  matching: find.text(label),
);

/// Unmounts the app. Drift cancels its table streams on a zero-delay timer,
/// so one more pump lets it fire before the test ends.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

/// GD-02 is the real [PlantingDetailScreen], not a placeholder; check it
/// is on screen for [id].
void _expectPlantingDetail(WidgetTester tester, String id) {
  final screen = find.byType(PlantingDetailScreen);
  expect(screen, findsOneWidget);
  expect(tester.widget<PlantingDetailScreen>(screen).plantingId, id);
}

void main() {
  group('redirect', () {
    testWidgets('not onboarded: /home goes to /onboarding/welcome', (
      tester,
    ) async {
      expect(defaultUserProfile.onboardingCompletedAt, isNull);
      final router = await _pumpApp(tester, defaultUserProfile);

      // The initial location is /home; the redirect sends it to OB-01.
      expect(_location(router).path, onboardingStart);
      expect(find.byType(WelcomeScreen), findsOneWidget);

      await _go(tester, router, '/garden');
      expect(_location(router).path, onboardingStart);

      // Onboarding steps themselves are reachable.
      await _go(tester, router, '/onboarding/space');
      expect(_location(router).path, '/onboarding/space');
      await _teardown(tester);
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
      await _teardown(tester);
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
      '/settings': 'Settings',
      '/settings/edit/space': 'OB-07 Edit step',
      '/community/editor/new': 'CM-03 Editor',
      '/community/me': 'CM-05 My profile',
    };
    for (final MapEntry(key: path, value: title) in placeholders.entries) {
      await _go(tester, router, path);
      expect(_location(router).path, path);
      expect(_title(tester), title, reason: path);
    }

    const realScreens = {
      '/home/recommendations': RecommendationsScreen,
      '/garden': MyGardenScreen,
    };
    for (final MapEntry(key: path, value: type) in realScreens.entries) {
      await _go(tester, router, path);
      expect(_location(router).path, path);
      expect(find.byType(type), findsOneWidget, reason: path);
    }

    await _go(tester, router, '/garden/planting/p1');
    expect(_location(router).path, '/garden/planting/p1');
    _expectPlantingDetail(tester, 'p1');

    const screens = {
      onboardingStart: WelcomeScreen,
      '/onboarding/location': LocationScreen,
      '/onboarding/climate': ClimateRevealScreen,
      '/onboarding/space': SpaceStepScreen,
      '/onboarding/goals': GoalsStepScreen,
      '/onboarding/time': AvailabilityStepScreen,
      '/onboarding/source': HeardAboutUsScreen,
      '/onboarding/summary': ProfileSummaryScreen,
      '/plants/kale': PlantDetailScreen,
      '/weather': WeatherScreen,
      '/care': CareScreen,
      '/community': CommunityFeedScreen,
      '/community/guide/g1': GuideDetailScreen,
    };
    for (final MapEntry(key: path, value: type) in screens.entries) {
      await _go(tester, router, path);
      expect(find.byType(type), findsOneWidget, reason: path);
    }
    await _go(tester, router, '/home');
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('PD-01 "Grow this" is wired to the PD-02 sheet (#23)', (
    tester,
  ) async {
    final router = await _pumpApp(tester, onboardedProfile);
    await _go(tester, router, '/plants/kale');

    final screen = tester.widget<PlantDetailScreen>(
      find.byType(PlantDetailScreen),
    );
    expect(screen.onGrow, isNotNull);
    await _teardown(tester);
  });

  testWidgets('/care?date=2026-10-07 exposes the date', (tester) async {
    final router = await _pumpApp(tester, onboardedProfile);
    await _go(tester, router, '/care?date=2026-10-07');

    final uri = _location(router);
    expect(uri.path, '/care');
    expect(uri.queryParameters['date'], '2026-10-07');
    expect(careDateFrom(uri), DateTime(2026, 10, 7));
    expect(
      tester.widget<CareScreen>(find.byType(CareScreen)).date,
      DateTime(2026, 10, 7),
    );
    await _teardown(tester);
  });

  test('careDateFrom rejects a missing or malformed date', () {
    expect(careDateFrom(Uri.parse('/care')), isNull);
    expect(careDateFrom(Uri.parse('/care?date=tomorrow')), isNull);
    expect(careDateFrom(Uri.parse('/care?date=2026-10-07T10:00')), isNull);
  });

  testWidgets('each tab keeps its own location', (tester) async {
    final router = await _pumpApp(tester, onboardedProfile);

    await tester.tap(_navTab('Garden'));
    await tester.pump();
    await _go(tester, router, '/garden/planting/p1');
    _expectPlantingDetail(tester, 'p1');

    await tester.tap(_navTab('Care'));
    await tester.pump();
    expect(_location(router).path, '/care');

    await tester.tap(_navTab('Garden'));
    await tester.pump();
    expect(_location(router).path, '/garden/planting/p1');

    // Tapping the active tab again returns it to its root.
    await tester.tap(_navTab('Garden'));
    await tester.pump();
    expect(_location(router).path, '/garden');

    await tester.tap(_navTab('Home'));
    await tester.pump();
    expect(_location(router).path, '/home');
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('the Home gear opens Settings', (tester) async {
    final router = await _pumpApp(tester, onboardedProfile);
    await tester.tap(find.byIcon(Symbols.settings_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Settings is pushed over Home, so Back returns there.
    expect(find.text('Settings'), findsOneWidget);
    expect(router.canPop(), isTrue);
    await _teardown(tester);
  });

  testWidgets('the Home weather card opens WX-01 and Back returns Home', (
    tester,
  ) async {
    final router = await _pumpApp(tester, onboardedProfile);
    // The forecast resolves on the next frames; the card is tappable then.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(WeatherMini), findsOneWidget);
    expect(find.byIcon(Symbols.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.byType(WeatherMini));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Pushed over Home, so Back pops it.
    expect(find.byType(WeatherScreen), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.tap(find.byIcon(Symbols.chevron_left_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WeatherScreen), findsNothing);
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    expect(router.canPop(), isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
