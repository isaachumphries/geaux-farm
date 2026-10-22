import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/garden/presentation/grow_this_sheet.dart';
import 'package:geaux_farm/features/garden/presentation/my_garden_screen.dart';
import 'package:geaux_farm/features/garden/presentation/planting_detail_screen.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/file_asset_bundle.dart';
import '../helpers/fixed_climate.dart';
import '../helpers/persisted_app_harness.dart' show settleDrift;

/// Wednesday morning, the "now" of every garden widget test.
final gardenNow = DateTime(2026, 10, 7, 9);

/// A fresh in-memory database whose streams close synchronously, so
/// unmounting a screen leaves no Drift timer pending.
AppDatabase openGardenDb() {
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  return db;
}

Future<void> seedSpace(
  AppDatabase db, {
  String id = 's1',
  SpaceType type = SpaceType.balcony,
  bool inContainerDefault = true,
  bool isPrimary = true,
}) => db
    .into(db.spacesTable)
    .insert(
      SpacesTableCompanion.insert(
        id: id,
        type: type,
        areaSqFt: 18,
        sun: SunLevel.partial,
        sunUnsure: false,
        rainExposed: true,
        inContainerDefault: inContainerDefault,
        isPrimary: isPrimary,
      ),
    );

/// The `user_profile` row, in [city], with the reminder pre-prompt
/// answered or not.
Future<void> seedProfile(
  AppDatabase db, {
  String city = 'Baton Rouge',
  bool permissionAsked = false,
}) => db
    .into(db.userProfileTable)
    .insert(
      UserProfileTableCompanion.insert(
        id: const Value(1),
        city: city,
        admin1: 'Louisiana',
        countryCode: 'US',
        lat: 30.45,
        lon: -91.19,
        timezone: 'America/Chicago',
        goals: [Goal.food],
        experience: Experience.beginner,
        availability: const Availability([64, 0, 64, 0, 0, 2, 2]),
        units: 'imperial',
        notificationPermissionAsked: Value(permissionAsked),
      ),
    );

Future<void> seedPlanting(
  AppDatabase db, {
  String id = 'p1',
  String plantId = 'kale',
  String spaceId = 's1',
  String nickname = 'Kale',
  GrowSetup setup = GrowSetup.indoor,
  bool inContainer = true,
  String startMethod = 'transplant',
  DateTime? plantedOn,
  PlantingStatus status = PlantingStatus.active,
  DateTime? createdAt,
}) => db
    .into(db.plantingsTable)
    .insert(
      PlantingsTableCompanion.insert(
        id: id,
        plantId: plantId,
        spaceId: spaceId,
        nickname: nickname,
        setup: setup,
        inContainer: inContainer,
        startMethod: startMethod,
        plantedOn: Value(plantedOn),
        status: status,
        createdAt: createdAt ?? DateTime(2026, 9, 1),
      ),
    );

/// A `guide_projects` row, as "Grow this" on a guide (#49) would add it.
Future<void> seedProject(
  AppDatabase db, {
  String id = 'gp1',
  String title = 'Balcony salad box',
}) => db
    .into(db.guideProjectsTable)
    .insert(
      GuideProjectsTableCompanion.insert(
        id: id,
        guideId: 'g1',
        title: title,
        materialsJson: '[]',
        stepsJson: '[]',
        createdAt: DateTime(2026, 10, 1),
      ),
    );

Future<void> seedCare(
  AppDatabase db,
  String plantingId,
  CareEventType type,
  DateTime at, {
  String? note,
  String? id,
}) => db
    .into(db.careEventsTable)
    .insert(
      CareEventsTableCompanion.insert(
        id: id ?? '$plantingId-${type.name}-${at.toIso8601String()}',
        plantingId: plantingId,
        type: type,
        at: at,
        note: Value(note),
      ),
    );

/// Overrides that feed the garden providers from [db], the bundled
/// catalog, and the Baton Rouge climate, with the clock fixed at [now].
/// The forecast fetch always fails, so the care rules use their no-rain
/// estimate and no test reaches the network.
List<Override> gardenOverrides(AppDatabase db, {DateTime? now}) => [
  appDatabaseProvider.overrideWithValue(db),
  assetBundleProvider.overrideWithValue(FileAssetBundle()),
  climateProvider.overrideWith(FixedClimate.new),
  clockProvider.overrideWithValue(() => now ?? gardenNow),
  forecastClientProvider.overrideWithValue(
    OpenMeteoForecastClient(MockClient((_) async => http.Response('', 500))),
  ),
];

/// Pumps GD-01, GD-02, a GD-03 stub, and a launcher for the PD-02 sheet in a small
/// router, over [db]. HM-02 and RC-01 are stubs that only name their
/// routes.
///
/// [plantToGrow] adds a "Grow it" button at `/` that opens the sheet.
Future<GoRouter> pumpGarden(
  WidgetTester tester,
  AppDatabase db, {
  String location = '/garden',
  ScoredPlant? plantToGrow,
  List<Override> extra = const [],
  DateTime? now,
  bool settle = true,
  double height = 1400,
}) async {
  // Wider than a phone: widget tests draw text in the wide Ahem font, which
  // overflows the card's water chip at 360 dp.
  tester.view.physicalSize = Size(600, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: plantToGrow == null
                  ? null
                  : () => pickPlant(context, plantToGrow),
              child: const Text('Grow it'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/garden',
        builder: (context, state) => const MyGardenScreen(),
        routes: [
          GoRoute(
            path: 'planting/:id',
            builder: (context, state) =>
                PlantingDetailScreen(plantingId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'project/:id',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('GD-03 stub ${state.pathParameters['id']}'),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('HM-02 stub'))),
      ),
      GoRoute(
        path: '/home/recommendations',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('RC-01 stub'))),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...gardenOverrides(db, now: now),
        ...extra,
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  if (settle) {
    await settleDrift(tester);
  } else {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  return router;
}

Uri locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri;
