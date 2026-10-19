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
import 'package:geaux_farm/features/home/application/first_plant_prompt_provider.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/onboarding/presentation/profile_summary_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/space_step_screen.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fixed_climate.dart';
import '../helpers/in_memory_database.dart';
import '../helpers/inert_notification_plugin.dart';
import 'finished_draft.dart';

final _finishedAt = DateTime(2026, 10, 7, 9, 41);

/// The whole app on a fresh in-memory database, with [finishedDraft] in
/// the draft and the router at OB-07.
Future<ProviderContainer> _pumpSummary(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final forecast = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
      .readAsStringSync();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inMemoryDatabaseOverride(),
        // The app root now starts care reminders; keep them off the OS.
        notificationServiceProvider.overrideWith(
          (ref) => NotificationService(
            InertNotificationPlugin(),
            ref.watch(appDatabaseProvider),
            () async => 'UTC',
          ),
        ),
        clockProvider.overrideWithValue(() => _finishedAt),
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
  final c = ProviderScope.containerOf(
    tester.element(find.byType(GeauxFarmApp)),
  );
  c.read(onboardingDraftProvider.notifier).state = finishedDraft;
  c.read(goRouterProvider).go(OnboardingRoutes.summary);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _finish(WidgetTester tester, String button) async {
  await tester.tap(find.text(button));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _tearDown(WidgetTester tester) async {
  // Drift closes its stream queries on a zero-length timer.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  test('rows in plan order with the draft values', () {
    expect(summaryRows(finishedDraft).map((r) => (r.$1, r.$2)), [
      ('Location', 'Baton Rouge, Louisiana'),
      ('Space', 'Balcony or patio · 16 sq ft'),
      ('Sun', 'Partial'),
      ('Goals', 'Food, Hobby'),
      ('Experience', 'A little'),
      ('Free time', '4 care days · 8 hrs/week'),
    ]);
  });

  testWidgets('shows the six rows; tapping one opens its step', (tester) async {
    final c = await _pumpSummary(tester);
    expect(find.text('Your garden profile'), findsOneWidget);
    final labels = [
      'LOCATION',
      'SPACE',
      'SUN',
      'GOALS',
      'EXPERIENCE',
      'FREE TIME',
    ];
    final ys = [for (final l in labels) tester.getCenter(find.text(l)).dy];
    expect(ys, [...ys]..sort());

    await tester.tap(find.text('SUN'));
    await tester.pumpAndSettle();
    expect(find.byType(SpaceStepScreen), findsOneWidget);
    expect(c.read(onboardingDraftProvider).areaSqFt, 16);
    await _tearDown(tester);
  });

  testWidgets('Find my first plant saves and lands on HM-01', (tester) async {
    final c = await _pumpSummary(tester);
    await _finish(tester, 'FIND MY FIRST PLANT');

    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    expect(c.read(firstPlantPromptDismissedProvider), isFalse);
    final db = c.read(appDatabaseProvider);
    final row = await tester.runAsync(
      () => db.select(db.userProfileTable).getSingle(),
    );
    expect(row!.onboardingCompletedAt, _finishedAt);

    // Onboarded: the redirect no longer sends /home back to Welcome.
    c.read(goRouterProvider).go('/garden');
    await tester.pumpAndSettle();
    expect(
      c.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path,
      '/garden',
    );
    await _tearDown(tester);
  });

  testWidgets("I'll set up later saves and lands on HM-01b", (tester) async {
    final c = await _pumpSummary(tester);
    await _finish(tester, "I'LL SET UP LATER");

    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    expect(c.read(firstPlantPromptDismissedProvider), isTrue);
    expect(find.text('Pick your first plant'), findsOneWidget);
    await _tearDown(tester);
  });
}
