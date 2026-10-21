import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_providers.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/data/profile_writer.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/file_asset_bundle.dart';
import '../helpers/fixed_climate.dart';
import '../helpers/in_memory_database.dart';
import '../helpers/inert_notification_plugin.dart';
import '../helpers/persisted_app_harness.dart';
import 'finished_draft.dart';

// #183: on a device the committed Drift transaction reaches
// userProfileProvider a few event-loop turns after `save` resolves. The
// in-memory database in the other OB-07 tests closes that gap, so this
// file models it: the write still goes through the real ProfileWriter, but
// the profile the router reads arrives only after [_publishDelay].
const _publishDelay = Duration(milliseconds: 200);

final _finishedAt = DateTime(2026, 10, 7, 9, 41);

/// A real writer that publishes the saved profile late, as the device's
/// Drift stream query does.
class _LateStreamWriter extends ProfileWriter {
  _LateStreamWriter(super.db, this._publish);

  final void Function(UserProfile) _publish;

  @override
  Future<void> save(UserProfile profile, Space space) async {
    await super.save(profile, space);
    Future<void>.delayed(_publishDelay, () => _publish(profile));
  }
}

/// The whole app with [finishedDraft] at OB-07 and a profile stream that
/// starts un-onboarded and only reports completion [_publishDelay] after
/// the write.
Future<ProviderContainer> _pumpSummary(WidgetTester tester) async {
  final profiles = StreamController<UserProfile>();
  addTearDown(profiles.close);
  profiles.add(defaultUserProfile);
  final forecast = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
      .readAsStringSync();
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inMemoryDatabaseOverride(),
        fileAssetBundleOverride(),
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
        profileWriterProvider.overrideWith(
          (ref) =>
              _LateStreamWriter(ref.watch(appDatabaseProvider), profiles.add),
        ),
        userProfileProvider.overrideWith((ref) => profiles.stream),
      ],
      child: const GeauxFarmApp(),
    ),
  );
  await settleDrift(tester);
  final c = ProviderScope.containerOf(
    tester.element(find.byType(GeauxFarmApp)),
  );
  c.read(onboardingDraftProvider.notifier).state = finishedDraft;
  await goAndSettle(tester, c, OnboardingRoutes.summary);
  return c;
}

/// Lets the real database work finish without advancing the fake clock,
/// so [_publishDelay] has not elapsed yet. `settleDrift` cannot do this:
/// its `pumpAndSettle` would fire the delayed publication.
Future<void> _settleWrite(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

/// Taps [button] and lets the late profile publication land. Returns the
/// router's location in the gap between the committed write and that
/// publication: OB-07 must still be showing, not Welcome.
Future<Uri> _finish(
  WidgetTester tester,
  ProviderContainer c,
  String button,
) async {
  await tester.tap(find.text(button));
  await _settleWrite(tester);
  final duringWrite = routerLocation(c);
  await tester.pump(_publishDelay * 2);
  await settleDrift(tester);
  return duringWrite;
}

/// `user_profile.first_plant_prompt_dismissed` as actually stored.
Future<bool> _dismissedInDb(WidgetTester tester, ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  final row = await tester.runAsync(
    () => (db.select(
      db.userProfileTable,
    )..where((t) => t.id.equals(1))).getSingleOrNull(),
  );
  return row?.firstPlantPromptDismissed ?? false;
}

void main() {
  testWidgets('Find my first plant lands on Home when the profile '
      'publishes late', (tester) async {
    final c = await _pumpSummary(tester);
    final duringWrite = await _finish(tester, c, 'FIND MY FIRST PLANT');

    // No Welcome flash: Finish holds OB-07 until the router can see the
    // finished profile.
    expect(duringWrite.path, OnboardingRoutes.summary);
    expect(routerLocation(c).path, '/home');
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    expect(
      c.read(userProfileProvider).requireValue.onboardingCompletedAt,
      _finishedAt,
    );
    // HM-01, the carousel: this branch does not dismiss the prompt.
    expect(await _dismissedInDb(tester, c), isFalse);
    await unmountApp(tester);
  });

  testWidgets("I'll set up later lands on HM-01b with the prompt dismissed", (
    tester,
  ) async {
    final c = await _pumpSummary(tester);
    final duringWrite = await _finish(tester, c, "I'LL SET UP LATER");

    expect(duringWrite.path, OnboardingRoutes.summary);
    expect(routerLocation(c).path, '/home');
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    expect(
      c.read(userProfileProvider).requireValue.onboardingCompletedAt,
      _finishedAt,
    );
    // The branch that distinguishes this case from the one above, read
    // back from the row rather than the notifier's optimistic state, so
    // the dismiss write has to have landed.
    expect(await _dismissedInDb(tester, c), isTrue);
    await unmountApp(tester);
  });
}
