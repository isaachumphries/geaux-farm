import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:geaux_farm/features/weather/presentation/attribution_footer.dart';
import 'package:geaux_farm/features/weather/presentation/weather_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'app_harness.dart';
import 'fixed_climate.dart';

final forecastFixture = File(
  'test/fixtures/open_meteo/forecast_baton_rouge.json',
).readAsStringSync();

/// The fixture's `current.time` is 2026-10-13T17:15.
final fixtureNow = DateTime(2026, 10, 13, 17, 20);

/// [onboardedProfile] with the metric toggle on.
final metricProfile = UserProfile(
  city: onboardedProfile.city,
  admin1: onboardedProfile.admin1,
  countryCode: onboardedProfile.countryCode,
  lat: onboardedProfile.lat,
  lon: onboardedProfile.lon,
  timezone: onboardedProfile.timezone,
  goals: onboardedProfile.goals,
  experience: onboardedProfile.experience,
  availability: onboardedProfile.availability,
  units: 'metric',
  onboardingCompletedAt: onboardedProfile.onboardingCompletedAt,
);

/// What the forecast client and the clock do during one test.
class WeatherRig {
  DateTime now = fixtureNow;

  /// Forecast requests so far.
  int calls = 0;

  /// While true the forecast request answers 503.
  bool fail = false;

  /// When set, the forecast request waits on this future.
  Future<void>? hold;

  /// Links the footer asked to open.
  final opened = <Uri>[];

  late final ProviderContainer container;

  Future<http.Response> _handle(http.Request _) async {
    calls++;
    await hold;
    return fail
        ? http.Response('down', 503)
        : http.Response(forecastFixture, 200);
  }

  List<Override> overrides({UserProfile? profile, Override? climate}) => [
    userProfileProvider.overrideWith(
      (ref) => Stream.value(profile ?? onboardedProfile),
    ),
    climate ?? climateProvider.overrideWith(FixedClimate.new),
    weatherClockProvider.overrideWithValue(() => now),
    forecastClientProvider.overrideWithValue(
      OpenMeteoForecastClient(MockClient(_handle)),
    ),
    linkOpenerProvider.overrideWithValue((uri) async {
      opened.add(uri);
      return true;
    }),
  ];

  /// Re-fetches the forecast now, as pull-to-refresh and app resume do.
  Future<void> refresh(WidgetTester tester, {bool force = true}) async {
    final profile = onboardedProfile;
    final location = forecastLocation(profile.lat, profile.lon);
    await container
        .read(weatherProvider(location).notifier)
        .refresh(force: force);
    await tester.pump();
  }
}

/// Pumps [WeatherScreen] at 360×800 with the recorded Baton Rouge forecast.
Future<WeatherRig> pumpWeatherScreen(
  WidgetTester tester, {
  WeatherRig? rig,
  UserProfile? profile,
  Override? climate,
  double height = 800,
}) async {
  rig ??= WeatherRig();
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: rig.overrides(profile: profile, climate: climate),
      child: MaterialApp(theme: AppTheme.light(), home: const WeatherScreen()),
    ),
  );
  rig.container = ProviderScope.containerOf(
    tester.element(find.byType(WeatherScreen)),
  );
  // Profile stream, then the forecast and the climate futures.
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return rig;
}

/// A climate provider that never finishes.
Override pendingClimate() => climateProvider.overrideWith(_PendingClimate.new);

/// A climate provider whose build fails.
Override failingClimate() => climateProvider.overrideWith(_FailingClimate.new);

class _PendingClimate extends ClimateNotifier {
  @override
  Future<ClimateProfile> build() => Completer<ClimateProfile>().future;
}

class _FailingClimate extends ClimateNotifier {
  @override
  Future<ClimateProfile> build() async => throw const NetworkException('down');
}
