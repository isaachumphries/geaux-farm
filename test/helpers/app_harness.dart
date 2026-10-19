import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_plugin.dart';
import 'package:geaux_farm/core/notifications/notification_providers.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixed_climate.dart';
import 'in_memory_database.dart';
import 'inert_notification_plugin.dart';

/// [defaultUserProfile] with onboarding finished.
final onboardedProfile = UserProfile(
  city: defaultUserProfile.city,
  admin1: defaultUserProfile.admin1,
  countryCode: defaultUserProfile.countryCode,
  lat: defaultUserProfile.lat,
  lon: defaultUserProfile.lon,
  timezone: defaultUserProfile.timezone,
  goals: defaultUserProfile.goals,
  experience: defaultUserProfile.experience,
  availability: defaultUserProfile.availability,
  onboardingCompletedAt: DateTime(2026, 10, 7, 9),
);

/// Overrides for pumping the whole app: [profile] instead of the Drift
/// row, the default space, the plan/04 climate instead of an archive
/// build, the recorded Baton Rouge forecast instead of Open-Meteo, and
/// [notificationPlugin] (inert by default) instead of the OS plugin.
List<Override> appOverrides({
  required UserProfile profile,
  NotificationPlugin? notificationPlugin,
}) {
  final forecast = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
      .readAsStringSync();
  return [
    inMemoryDatabaseOverride(),
    notificationServiceProvider.overrideWith(
      (ref) => NotificationService(
        notificationPlugin ?? InertNotificationPlugin(),
        ref.watch(appDatabaseProvider),
        () async => 'UTC',
      ),
    ),
    userProfileProvider.overrideWith((ref) => Stream.value(profile)),
    primarySpaceProvider.overrideWith((ref) => Stream.value(defaultSpace)),
    climateProvider.overrideWith(FixedClimate.new),
    forecastClientProvider.overrideWithValue(
      OpenMeteoForecastClient(
        MockClient((_) async => http.Response(forecast, 200)),
      ),
    ),
  ];
}
