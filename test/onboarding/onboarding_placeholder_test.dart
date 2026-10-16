import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_placeholder.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/onboarding/presentation/welcome_screen.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fixed_climate.dart';
import '../helpers/in_memory_database.dart';

void main() {
  testWidgets('Continue walks the remaining stand-in steps; Finish saves the '
      'onboarded profile and opens Home', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final forecast = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
        .readAsStringSync();
    final finishedAt = DateTime(2026, 10, 7, 9, 41);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inMemoryDatabaseOverride(),
          clockProvider.overrideWithValue(() => finishedAt),
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
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Steps that have their own screen are covered by their own tests;
    // start at the first stand-in.
    ProviderScope.containerOf(tester.element(find.byType(GeauxFarmApp)))
        .read(goRouterProvider)
        .go(OnboardingRoutes.time);
    await tester.pumpAndSettle();
    for (final title in ['OB-05 Availability', 'OB-06 Heard about us']) {
      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
    }
    expect(find.widgetWithText(AppBar, 'OB-07 Profile summary'), findsOne);

    await tester.tap(find.text('FINISH'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPlaceholder), findsNothing);
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    final db = ProviderScope.containerOf(
      tester.element(find.byType(GeauxFarmApp)),
    ).read(appDatabaseProvider);
    final row = await tester.runAsync(
      () => db.select(db.userProfileTable).getSingle(),
    );
    expect(row!.onboardingCompletedAt, finishedAt);
    expect(row.city, 'Baton Rouge');
    final space = await tester.runAsync(
      () => db.select(db.spacesTable).getSingle(),
    );
    expect(space!.isPrimary, isTrue);

    // Drift closes its stream queries on a zero-length timer once the
    // scope is gone.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
