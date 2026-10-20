import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/presentation/care_screen.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/care_fixtures.dart';

/// CR-01 over the real schedule provider and the Drift repository: the
/// swipe writes a `care_events` row and the schedule recomputes from it.
void main() {
  testWidgets('swipe-to-done writes care_events and keeps the row done', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.spacesTable)
        .insert(
          SpacesTableCompanion.insert(
            id: 's1',
            type: SpaceType.balcony,
            areaSqFt: 10,
            sun: SunLevel.full,
            sunUnsure: false,
            rainExposed: true,
            inContainerDefault: true,
            isPrimary: true,
          ),
        );
    await db
        .into(db.plantingsTable)
        .insert(
          PlantingsTableCompanion.insert(
            id: 'p1',
            plantId: 'kale',
            spaceId: 's1',
            nickname: 'Kale',
            setup: GrowSetup.outdoor,
            inContainer: true,
            startMethod: 'transplant',
            plantedOn: Value(carePlanted),
            status: PlantingStatus.active,
            createdAt: carePlanted,
          ),
        );
    // Planted today, so the first water is due today.
    final now = DateTime(2026, 5, 1, 7);
    final profile = UserProfile(
      city: defaultUserProfile.city,
      admin1: defaultUserProfile.admin1,
      countryCode: defaultUserProfile.countryCode,
      lat: 40.0,
      lon: -90.0,
      timezone: defaultUserProfile.timezone,
      goals: defaultUserProfile.goals,
      experience: defaultUserProfile.experience,
      availability: careAllFree,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          catalogProvider.overrideWith((ref) async => [carePlant()]),
          clockProvider.overrideWithValue(() => now),
          forecastClientProvider.overrideWithValue(
            OpenMeteoForecastClient(
              MockClient((_) async => http.Response('', 500)),
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const CareScreen()),
      ),
    );
    // Let the Drift streams and the schedule load.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Water Kale'), findsOneWidget);
    await tester.drag(find.text('Water Kale'), const Offset(400, 0));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    final rows = await tester.runAsync(
      () => db.select(db.careEventsTable).get(),
    );
    expect(rows, hasLength(1));
    expect(rows!.single.plantingId, 'p1');
    expect(rows.single.type, CareEventType.water);
    expect(rows.single.at, now);
    expect(find.text('Water Kale'), findsOneWidget);
    expect(find.textContaining('Done at'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
