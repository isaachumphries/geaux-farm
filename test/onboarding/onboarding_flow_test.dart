import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/climate/data/climate_service.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/data/device_locator.dart';
import 'package:geaux_farm/features/onboarding/data/open_meteo_geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/domain/geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/availability_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/climate_reveal_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/goals_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/heard_about_us_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/location_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/profile_summary_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/space_step_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/welcome_screen.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fixed_climate.dart';
import '../helpers/in_memory_database.dart';
import '../recommendations/fixtures/baton_rouge.dart' as fx;

void main() {
  testWidgets('onboarding happy path saves the profile and ends on Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final previousHttp = HttpOverrides.current;
    final httpGuard = _NoNetworkOverrides();
    HttpOverrides.global = httpGuard;
    addTearDown(() => HttpOverrides.global = previousHttp);

    final climate = _RecordingClimateService();
    final geocoding = _FakeGeocoding();
    final forecastRequests = <Uri>[];
    final forecast = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
        .readAsStringSync();
    final forecastClient = OpenMeteoForecastClient(
      MockClient((request) async {
        forecastRequests.add(request.url);
        return http.Response(forecast, 200);
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inMemoryDatabaseOverride(),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 9)),
          climateServiceProvider.overrideWithValue(climate),
          climateProvider.overrideWith(FixedClimate.new),
          geocodingRepositoryProvider.overrideWithValue(geocoding),
          deviceLocatorProvider.overrideWithValue(_NoDeviceLocator()),
          forecastClientProvider.overrideWithValue(forecastClient),
        ],
        child: const GeauxFarmApp(),
      ),
    );

    final c = ProviderScope.containerOf(
      tester.element(find.byType(GeauxFarmApp)),
    );
    final screens = <Type>[];

    // 1. Welcome
    await _waitFor(tester, find.text('GET STARTED'));
    screens.add(_topScreen(tester));
    await _tap(tester, find.text('GET STARTED'));

    // 2. Location: search, pick Baton Rouge
    screens.add(_topScreen(tester));
    await tester.enterText(find.byType(TextField), 'Baton Rouge');
    await tester.pump(locationSearchDebounce);
    await tester.pump();
    await _tap(tester, find.text('Baton Rouge, Louisiana, US'));

    // 3. Climate reveal
    await _waitFor(tester, find.text('Zone 8b'));
    screens.add(_topScreen(tester));
    expect(find.text('Zone 8b'), findsOneWidget);
    await _tap(tester, find.text('LOOKS RIGHT'));

    // 4. Space: balcony, 16 -> 32 sq ft, partial sun, rain on by default
    screens.add(_topScreen(tester));
    await _tap(tester, find.text('Balcony or patio'));
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Partial'));
    expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);
    await _tap(tester, find.text('CONTINUE'));

    // 5. Goals
    screens.add(_topScreen(tester));
    await _tap(tester, find.text('Food'));
    await _tap(tester, find.text('Hobby'));
    await _tap(tester, find.text('New to this'));
    await _tap(tester, find.text('CONTINUE'));

    // 6. Availability: 4 care days, 8 hrs/week
    screens.add(_topScreen(tester));
    for (final (day, block) in const [(0, 6), (2, 6), (5, 1), (6, 1)]) {
      await _tap(tester, find.byKey(ValueKey('cell-$day-$block')));
    }
    expect(find.text('4 care days · 8 hrs/week'), findsOneWidget);
    await _tap(tester, find.text('CONTINUE'));

    // 7. Source: skip
    screens.add(_topScreen(tester));
    await _tap(tester, find.text('SKIP'));

    // 8. Summary: finish
    screens.add(_topScreen(tester));
    await _tap(tester, find.text('FIND MY FIRST PLANT'));
    await _waitFor(tester, find.byType(HomeFirstRunScreen));
    screens.add(_topScreen(tester));

    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    expect(screens, [
      WelcomeScreen,
      LocationScreen,
      ClimateRevealScreen,
      SpaceStepScreen,
      GoalsStepScreen,
      AvailabilityStepScreen,
      HeardAboutUsScreen,
      ProfileSummaryScreen,
      HomeFirstRunScreen,
    ]);
    expect(_route(c), '/home');

    final db = c.read(appDatabaseProvider);
    final profile = (await tester.runAsync(
      () => db.select(db.userProfileTable).getSingle(),
    ))!;
    expect(profile.onboardingCompletedAt, DateTime(2026, 10, 7, 9));
    expect(profile.city, 'Baton Rouge');
    expect(profile.availability.days, [64, 0, 64, 0, 0, 2, 2]);
    expect(profile.goals, [Goal.food, Goal.hobby]);

    final spaces = (await tester.runAsync(
      () => db.select(db.spacesTable).get(),
    ))!;
    final primary = spaces.where((s) => s.isPrimary).toList();
    expect(primary, hasLength(1));
    expect(primary.single.type, SpaceType.balcony);
    expect(primary.single.areaSqFt, 32);
    expect(primary.single.sun, SunLevel.partial);
    expect(primary.single.rainExposed, isTrue);

    expect(climate.calls, [(30.45, -91.19, 'US', '70801')]);
    expect(geocoding.queries, ['Baton Rouge']);
    expect(forecastRequests, isNotEmpty);
    expect(
      forecastRequests.map((u) => u.host),
      everyElement('api.open-meteo.com'),
    );
    expect(httpGuard.creations, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}

const _onboardingScreens = <Type>[
  WelcomeScreen,
  LocationScreen,
  ClimateRevealScreen,
  SpaceStepScreen,
  GoalsStepScreen,
  AvailabilityStepScreen,
  HeardAboutUsScreen,
  ProfileSummaryScreen,
  HomeFirstRunScreen,
];

// The route stack keeps earlier pages in the tree, and go_router 18 does
// not update currentConfiguration on push. Route.isCurrent is true only for
// the top-most route, so the screen on top is read from that instead.
Type _topScreen(WidgetTester tester) {
  final tops = [
    for (final screen in _onboardingScreens)
      if (find.byType(screen).evaluate().isNotEmpty &&
          (ModalRoute.of(tester.element(find.byType(screen)))?.isCurrent ??
              false))
        screen,
  ];
  expect(tops, hasLength(1), reason: 'expected exactly one top screen');
  return tops.single;
}

String _route(ProviderContainer c) =>
    c.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path;

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  expect(finder, findsWidgets, reason: 'tap target missing');
  await tester.tap(finder.last);
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

class _NoNetworkOverrides extends HttpOverrides {
  int creations = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    creations++;
    throw StateError('real HTTP client created during onboarding flow test');
  }
}

class _RecordingClimateService implements ClimateService {
  final calls = <(double, double, String, String?)>[];

  @override
  Future<ClimateProfile> build({
    required double lat,
    required double lon,
    required String countryCode,
    String? postcode,
  }) async {
    calls.add((lat, lon, countryCode, postcode));
    return fx.batonRougeClimate;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGeocoding implements GeocodingRepository {
  final queries = <String>[];

  @override
  Future<List<GeoPlace>> search(String query) async {
    queries.add(query);
    return [
      GeoPlace(
        name: 'Baton Rouge',
        admin1: 'Louisiana',
        countryCode: 'US',
        lat: 30.4515,
        lon: -91.1871,
        postcode: '70801',
        timezone: 'America/Chicago',
      ),
    ];
  }
}

class _NoDeviceLocator implements DeviceLocator {
  @override
  Future<GeoPlace> locate() async =>
      throw StateError('the flow never uses GPS');
}
