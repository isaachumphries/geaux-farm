import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_providers.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'file_asset_bundle.dart';
import 'fixed_climate.dart';
import 'inert_notification_plugin.dart';

/// Pumps the whole app in a fresh [ProviderScope] over [db], with the real
/// Drift-backed profile providers (unlike `appOverrides`, which fakes the
/// profile). The caller owns [db], so it outlives the scope: pumping this
/// twice over one database is an app restart. Network, climate, clock and
/// notifications are faked as in the onboarding flow test.
Future<ProviderContainer> pumpAppOverDatabase(
  WidgetTester tester,
  AppDatabase db, {
  required DateTime now,
}) async {
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final forecast = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
      .readAsStringSync();
  await tester.pumpWidget(
    ProviderScope(
      // A new key per call, so a second pump builds a new scope instead of
      // updating the old one.
      key: UniqueKey(),
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        fileAssetBundleOverride(),
        notificationServiceProvider.overrideWith(
          (ref) => NotificationService(
            InertNotificationPlugin(),
            ref.watch(appDatabaseProvider),
            () async => 'UTC',
          ),
        ),
        clockProvider.overrideWithValue(() => now),
        climateProvider.overrideWith(FixedClimate.new),
        forecastClientProvider.overrideWithValue(
          OpenMeteoForecastClient(
            MockClient((_) async => http.Response(forecast, 200)),
          ),
        ),
      ],
      child: const GeauxFarmApp(),
    ),
  );
  await settleDrift(tester);
  return ProviderScope.containerOf(tester.element(find.byType(GeauxFarmApp)));
}

/// Lets Drift's stream queries emit (they need real event-loop turns), then
/// settles the frames they trigger.
Future<void> settleDrift(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

/// The router's current location.
Uri routerLocation(ProviderContainer c) =>
    c.read(goRouterProvider).routerDelegate.currentConfiguration.uri;

/// Goes to [location] (no push) and settles.
Future<void> goAndSettle(
  WidgetTester tester,
  ProviderContainer c,
  String location,
) async {
  c.read(goRouterProvider).go(location);
  await settleDrift(tester);
}

/// Unmounts the app; Drift cancels its stream queries on a zero-length
/// timer, so one more pump lets it fire.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}
