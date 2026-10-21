import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';
import 'package:geaux_farm/features/care/presentation/widgets/task_row.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/community/application/community_feed_provider.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/presentation/widgets/guide_card.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/garden/application/garden_provider.dart';
import 'package:geaux_farm/features/garden/data/plantings_provider.dart';
import 'package:geaux_farm/features/garden/domain/growth.dart';
import 'package:geaux_farm/features/garden/presentation/grow_this_sheet.dart';
import 'package:geaux_farm/features/garden/presentation/widgets/planting_card.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/home/application/first_plant_prompt_provider.dart';
import 'package:geaux_farm/features/home/domain/home_copy.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/data/profile_writer.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/recommendations/application/recommendations_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/sort_recommendations.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_card.dart';
import 'package:geaux_farm/features/weather/application/garden_alerts_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/domain/garden_alerts.dart';
import 'package:geaux_farm/features/weather/presentation/alert_banner.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:geaux_farm/features/weather/data/weather_repository.dart';
import 'package:geaux_farm/features/weather/presentation/weather_mini.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../helpers/community_fixtures.dart';
import '../helpers/fixed_climate.dart';
import '../helpers/in_memory_database.dart';
import '../garden/garden_harness.dart' show seedPlanting, seedSpace;
import '../helpers/persisted_app_harness.dart' show settleDrift;
import '../recommendations/fixtures/scored.dart';

/// [n] distinct recommendations, best first.
List<ScoredPlant> _recs(int n) => [
  for (var i = 0; i < n; i++)
    scored(
      kaleWith({
        'id': 'plant-$i',
        'commonName': 'Plant ${i.toString().padLeft(2, '0')}',
      }),
      score: 100 - i,
      inSeason: i.isEven,
    ),
];

/// One resolved garden view for the first plant in [recs], so HM-02 can be
/// exercised without waiting on the bundled catalog.
PlantingView _plantedView(List<ScoredPlant> recs) {
  final plant = recs.first.plant;
  final planting = Planting(
    id: 'p1',
    plantId: plant.id,
    spaceId: defaultSpace.id,
    nickname: plant.commonName,
    setup: GrowSetup.outdoor,
    inContainer: true,
    startMethod: 'transplant',
    plantedOn: DateTime(2026, 10, 1),
    status: PlantingStatus.active,
    createdAt: DateTime(2026, 10, 1),
  );
  return PlantingView(
    planting: planting,
    plant: plant,
    space: defaultSpace,
    growth: growthOf(planting, plant, _wednesdayMorning),
  );
}

class _PendingClimate extends ClimateNotifier {
  @override
  Future<ClimateProfile> build() => Completer<ClimateProfile>().future;
}

class _FailedClimate extends ClimateNotifier {
  @override
  Future<ClimateProfile> build() async => throw StateError('build failed');
}

/// Fails its first build; [rebuild] then succeeds with the fixture instead
/// of calling the archive.
class _RetryableClimate extends ClimateNotifier {
  int rebuilds = 0;

  @override
  Future<ClimateProfile> build() async => throw StateError('build failed');

  @override
  Future<void> rebuild() async {
    rebuilds++;
    state = AsyncData(await FixedClimate().build());
  }
}

final _wednesdayMorning = DateTime(2026, 10, 7, 9, 41);

final _forecastJson = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
    .readAsStringSync();

/// Fake Open-Meteo: serves the Baton Rouge fixture (or a 503 when [fail] is
/// set) and records every request, so no test touches the network.
class _FakeForecast {
  final requests = <Uri>[];
  bool fail = false;

  OpenMeteoForecastClient get client => OpenMeteoForecastClient(
    MockClient((request) async {
      requests.add(request.url);
      return fail
          ? http.Response('down', 503)
          : http.Response(_forecastJson, 200);
    }),
  );
}

UserProfile _profileAt(double lat, double lon) => UserProfile(
  city: defaultUserProfile.city,
  admin1: defaultUserProfile.admin1,
  countryCode: defaultUserProfile.countryCode,
  lat: lat,
  lon: lon,
  timezone: defaultUserProfile.timezone,
  goals: defaultUserProfile.goals,
  experience: defaultUserProfile.experience,
  availability: defaultUserProfile.availability,
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<ScoredPlant>? recs,
  AsyncValue<List<ScoredPlant>>? recsValue,
  ClimateNotifier Function()? climate,
  DateTime? now,
  Size size = const Size(390, 844),
  _FakeForecast? forecast,
  Stream<UserProfile>? profile,
  List<Planting>? plantings,
  List<PlantingView>? garden,
  bool localGarden = false,
  Future<void> Function(ProviderContainer)? prepare,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final at = now ?? _wednesdayMorning;
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => at),
      if (recs != null)
        recommendationsProvider.overrideWithValue(AsyncData(recs)),
      if (recsValue != null)
        recommendationsProvider.overrideWithValue(recsValue),
      // The real provider builds from the archive; use the fixture.
      climateProvider.overrideWith(climate ?? FixedClimate.new),
      forecastClientProvider.overrideWithValue(
        (forecast ?? _FakeForecast()).client,
      ),
      weatherClockProvider.overrideWithValue(() => DateTime(2026, 10, 13, 17)),
      // The profile streams read Drift; feed them the defaults instead.
      userProfileProvider.overrideWith(
        (ref) => profile ?? Stream.value(defaultUserProfile),
      ),
      primarySpaceProvider.overrideWith((ref) => Stream.value(defaultSpace)),
      if (plantings != null)
        plantingsProvider.overrideWith((ref) => Stream.value(plantings)),
      // gardenProvider also awaits the bundled catalog, which needs more than
      // the two pumps below; override the resolved views instead.
      if (!localGarden)
        gardenProvider.overrideWith((ref) async => garden ?? const []),
      inMemoryDatabaseOverride(),
      ...extra,
    ],
  );
  if (prepare != null) await tester.runAsync(() => prepare(container));
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeFirstRunScreen()),
      GoRoute(
        path: '/home/recommendations',
        builder: (_, _) => const Text('RC-01 stub'),
      ),
      GoRoute(
        path: '/plants/:plantId',
        builder: (_, state) =>
            Text('PD-01 stub: ${state.pathParameters['plantId']}'),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const Text('ST-01 stub')),
      GoRoute(path: '/care', builder: (_, _) => const Text('CR-01 stub')),
      GoRoute(path: '/garden', builder: (_, _) => const Text('GD-01 stub')),
      GoRoute(path: '/weather', builder: (_, _) => const Text('WX-01 stub')),
      GoRoute(path: '/community', builder: (_, _) => const Text('CM-01 stub')),
      GoRoute(
        path: '/community/guide/:id',
        builder: (_, state) =>
            Text('CM-02 stub: ${state.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  // One frame for the providers, one for the fake forecast to land.
  await tester.pump();
  await tester.pump();
  return container;
}

/// Unmounts the screen so the midnight timer and container go away before
/// the binding checks for pending timers. The last pump runs the zero-length
/// timer Drift schedules when a watched query (plantings) is cancelled.
Future<void> _unmount(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
  await tester.pump(Duration.zero);
}

Future<void> _pickLater(WidgetTester tester) async {
  final button = find.text("I'LL PICK LATER");
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
}

ScheduledCareTask _careTask(String name, DateTime slot) => ScheduledCareTask(
  plantingId: name,
  nickname: name,
  kind: CareTaskKind.water,
  due: DateTime(slot.year, slot.month, slot.day),
  slot: CareSlot(start: slot, outsideFreeTimes: false),
  overdue: false,
);

/// HM-02 overrides: a care schedule of [tasks], [alerts], and a Trending
/// first row of [topGuide] (null: Trending is empty).
List<Override> _hm02({
  List<ScheduledCareTask> tasks = const [],
  List<GardenAlert> alerts = const [],
  String? topGuide,
}) => [
  careScheduleProvider.overrideWith((ref) async => tasks),
  gardenAlertsProvider.overrideWith((ref) async => alerts),
  topGuideThisWeekProvider.overrideWithValue(
    AsyncData(topGuide == null ? null : testGuide(topGuide)),
  ),
];

double _topOf(WidgetTester tester, Finder f) => tester.getTopLeft(f.first).dy;

void main() {
  testWidgets('25 recommendations → the first 10 as cards, in order', (
    tester,
  ) async {
    final recs = _recs(25);
    final c = await _pump(tester, recs: recs);

    final cards = tester.widgetList<PlantCard>(find.byType(PlantCard));
    expect(cards.map((card) => card.plant), recs.take(10));
    expect(find.text('Plant 00'), findsOneWidget);
    expect(find.text('Plant 10'), findsNothing);
    // Even indexes are in season; each in-season card carries the ribbon.
    expect(find.text('PLANT NOW'), findsNWidgets(5));
    await _unmount(tester, c);
  });

  testWidgets('header, season banner, and subline for the default user', (
    tester,
  ) async {
    final c = await _pump(tester, recs: _recs(3));

    expect(find.text('WEDNESDAY, OCT 7'), findsOneWidget);
    expect(find.text('Good morning!'), findsOneWidget);
    expect(find.text('Baton Rouge'), findsOneWidget);
    expect(find.text('THIS SEASON'), findsOneWidget);
    expect(
      find.text('Fall · Cool-season planting in Baton Rouge'),
      findsOneWidget,
    );
    expect(find.text('Pick your first plant'), findsOneWidget);
    expect(find.text('SEE ALL'), findsOneWidget);
    expect(
      find.text('Top matches for your balcony in Baton Rouge'),
      findsOneWidget,
    );
    await _unmount(tester, c);
  });

  testWidgets('climate pending → spinner in the carousel slot, no cards', (
    tester,
  ) async {
    final c = await _pump(tester, recs: _recs(5), climate: _PendingClimate.new);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PlantCard), findsNothing);
    expect(find.text('Good morning!'), findsOneWidget);
    expect(find.text('THIS SEASON'), findsOneWidget);
    await _unmount(tester, c);
  });

  testWidgets('a failed climate build shows the error line with Retry', (
    tester,
  ) async {
    final c = await _pump(tester, recs: _recs(5), climate: _FailedClimate.new);

    expect(find.text("Couldn't load plants."), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(PlantCard), findsNothing);
    await _unmount(tester, c);
  });

  testWidgets('Retry rebuilds the climate and shows the carousel', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      recs: _recs(5),
      climate: _RetryableClimate.new,
    );
    expect(find.text('RETRY'), findsOneWidget);

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    final notifier = c.read(climateProvider.notifier) as _RetryableClimate;
    expect(notifier.rebuilds, 1);
    expect(find.text("Couldn't load plants."), findsNothing);
    expect(find.byType(PlantCard), findsWidgets);
    await _unmount(tester, c);
  });

  testWidgets('a failed recommendation load shows the error line', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      recsValue: AsyncError(StateError('bad catalog'), StackTrace.empty),
    );

    expect(find.text("Couldn't load plants."), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(PlantCard), findsNothing);
    await _unmount(tester, c);
  });

  testWidgets('"I\'ll pick later" collapses the carousel into HM-01b', (
    tester,
  ) async {
    final c = await _pump(tester, recs: _recs(25));

    await _pickLater(tester);

    expect(c.read(firstPlantPromptDismissedProvider), isTrue);
    expect(find.byType(PlantCard), findsNothing);
    expect(find.text("I'LL PICK LATER"), findsNothing);
    expect(find.text('SEE ALL'), findsNothing);
    expect(find.text('Pick your first plant'), findsOneWidget);
    expect(
      find.text('Plant 00, Plant 01 and 23 more fit your balcony.'),
      findsOneWidget,
    );
    // Header and banner stay.
    expect(
      find.text('Fall · Cool-season planting in Baton Rouge'),
      findsOneWidget,
    );
    await _unmount(tester, c);
  });

  group('HM-02', () {
    Future<ProviderContainer> pumpActive(
      WidgetTester tester, {
      List<ScheduledCareTask> tasks = const [],
      List<GardenAlert> alerts = const [],
      String? topGuide,
      List<ScoredPlant>? recs,
    }) async {
      final r = recs ?? _recs(25);
      final c = await _pump(
        tester,
        recs: r,
        garden: [_plantedView(r)],
        size: const Size(390, 3000),
        extra: _hm02(tasks: tasks, alerts: alerts, topGuide: topGuide),
      );
      await tester.pump();
      return c;
    }

    final frost = GardenAlert(
      type: GardenAlertType.frost,
      day: DateTime(2026, 10, 8),
      message: 'Frost Thu: cover or bring in Kale',
    );

    testWidgets('sections in plan/01 order', (tester) async {
      final c = await pumpActive(
        tester,
        tasks: [_careTask('Kale', DateTime(2026, 10, 7, 18))],
        alerts: [frost],
        topGuide: 'g1',
      );
      final order = [
        _topOf(tester, find.text('Frost Thu: cover or bring in Kale')),
        _topOf(tester, find.text('Today')),
        _topOf(tester, find.text('Your garden')),
        _topOf(tester, find.text('In season now')),
        _topOf(tester, find.text('Top guide this week')),
      ];
      expect(order, orderedEquals([...order]..sort()));
      expect(order.toSet(), hasLength(order.length));
      await _unmount(tester, c);
    });

    testWidgets('Today groups by block: 08:00 before 18:00', (tester) async {
      final c = await pumpActive(
        tester,
        tasks: [
          _careTask('Basil', DateTime(2026, 10, 7, 18)),
          _careTask('Kale', DateTime(2026, 10, 7, 8)),
          _careTask('Tomorrow', DateTime(2026, 10, 8, 8)),
        ],
      );
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('6:00 PM'), findsOneWidget);
      expect(
        _topOf(tester, find.text('8:00 AM')),
        lessThan(_topOf(tester, find.text('6:00 PM'))),
      );
      expect(
        _topOf(tester, find.text('Water Kale')),
        lessThan(_topOf(tester, find.text('6:00 PM'))),
      );
      expect(
        _topOf(tester, find.text('Water Basil')),
        greaterThan(_topOf(tester, find.text('6:00 PM'))),
      );
      expect(find.text('Water Tomorrow'), findsNothing);
      await _unmount(tester, c);
    });

    testWidgets('a Today row opens CR-01', (tester) async {
      final c = await pumpActive(
        tester,
        tasks: [_careTask('Kale', DateTime(2026, 10, 7, 8))],
      );
      await tester.tap(find.text('Water Kale'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CR-01 stub'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('Care list opens CR-01 even with no tasks', (tester) async {
      final c = await pumpActive(tester);
      await tester.tap(find.text('CARE LIST'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CR-01 stub'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('Top guide See all opens the community feed', (tester) async {
      final c = await pumpActive(tester, topGuide: 'g1');
      final section = find
          .ancestor(of: find.byType(GuideCard), matching: find.byType(Column))
          .first;
      await tester.tap(
        find.descendant(of: section, matching: find.text('SEE ALL')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CM-01 stub'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('no tasks today: the empty line, other sections stay', (
      tester,
    ) async {
      final c = await pumpActive(tester);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Nothing due this day.'), findsOneWidget);
      expect(find.byType(TaskRow), findsNothing);
      expect(find.text('Your garden'), findsOneWidget);
      expect(find.text('In season now'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('no alerts → no AlertBanner; alerts → one each', (
      tester,
    ) async {
      final quiet = await pumpActive(tester);
      expect(find.byType(AlertBanner), findsNothing);
      await _unmount(tester, quiet);

      final c = await pumpActive(tester, alerts: [frost]);
      final banner = tester.widget<AlertBanner>(find.byType(AlertBanner));
      expect(banner.type, AlertBannerType.frost);
      await _unmount(tester, c);
    });

    testWidgets('In season now: the first 10 in-season plants, in order', (
      tester,
    ) async {
      // _recs(25): even indexes are in season; include planted plant-0.
      final c = await pumpActive(tester);
      final shown = tester
          .widgetList<PlantCard>(find.byType(PlantCard))
          .map((card) => card.plant.plant.id)
          .toList();
      expect(shown, [for (var i = 0; i < 20; i += 2) 'plant-$i']);
      await _unmount(tester, c);
    });

    testWidgets('no plant in season → no In season now section', (
      tester,
    ) async {
      final recs = [
        for (final s in _recs(5))
          scored(s.plant, score: s.compatibility.score, inSeason: false),
      ];
      final c = await pumpActive(tester, recs: recs);
      expect(find.text('In season now'), findsNothing);
      expect(find.byType(PlantCard), findsNothing);
      await _unmount(tester, c);
    });

    testWidgets(
      'twelve seasonal plants retain plan/04 ties and the first ten',
      (tester) async {
        final ranked = sortRecommendations([
          for (var i = 11; i >= 0; i--)
            scored(
              kaleWith({
                'id': 'seasonal-$i',
                'commonName': 'Seasonal ${i.toString().padLeft(2, '0')}',
                'difficulty': i < 6 ? 1 : 2,
              }),
              score: i < 3 ? 100 : 90,
            ),
          scored(kaleWith({'id': 'not-seasonal'}), inSeason: false),
        ]);
        final c = await pumpActive(tester, recs: ranked);
        expect(
          tester
              .widgetList<PlantCard>(find.byType(PlantCard))
              .map((card) => card.plant.plant.id),
          [for (var i = 0; i < 10; i++) 'seasonal-$i'],
        );
        await _unmount(tester, c);
      },
    );

    testWidgets('active carousel opens PD-01, not the grow sheet', (
      tester,
    ) async {
      final c = await pumpActive(tester);
      await tester.tap(find.byType(PlantCard).first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('PD-01 stub: plant-0'), findsOneWidget);
      expect(find.byType(GrowThisSheet), findsNothing);
      await _unmount(tester, c);
    });

    testWidgets('snapshot opens My Garden', (tester) async {
      final c = await pumpActive(tester);
      await tester.tap(find.byType(PlantingCard));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('GD-01 stub'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('first real Trending row is shown and opens CM-02', (
      tester,
    ) async {
      final recs = _recs(3);
      final repository = FakeGuideRepository(
        pages: (query, offset) => [
          testGuide('trending-first', title: 'First trending', stars7d: 20),
          testGuide('trending-second', title: 'Second trending', stars7d: 10),
        ],
      );
      final c = await _pump(
        tester,
        recs: recs,
        garden: [_plantedView(recs)],
        size: const Size(390, 3000),
        extra: [
          careScheduleProvider.overrideWith((ref) async => []),
          gardenAlertsProvider.overrideWith((ref) async => []),
          guideRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pump();
      expect(repository.fetches.single, (topGuideThisWeekQuery, 0));
      expect(find.text('First trending'), findsOneWidget);
      expect(find.text('Second trending'), findsNothing);
      await tester.tap(find.byType(GuideCard));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CM-02 stub: trending-first'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('weather failure keeps Today and the garden visible', (
      tester,
    ) async {
      final recs = _recs(3);
      final c = await _pump(
        tester,
        recs: recs,
        garden: [_plantedView(recs)],
        forecast: _FakeForecast()..fail = true,
        extra: _hm02(tasks: [_careTask('Kale', DateTime(2026, 10, 7, 18))]),
      );
      expect(find.text(WeatherMini.errorCopy), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Water Kale'), findsOneWidget);
      expect(find.text('Your garden'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('offline restores local tasks, snapshot and saved weather', (
      tester,
    ) async {
      final plant = kaleWith({});
      final c = await _pump(
        tester,
        recs: [scored(plant)],
        localGarden: true,
        forecast: _FakeForecast()..fail = true,
        size: const Size(360, 1400),
        prepare: (c) async {
          final db = c.read(appDatabaseProvider);
          await seedSpace(db, id: defaultSpace.id);
          await seedPlanting(
            db,
            spaceId: defaultSpace.id,
            nickname: 'Local Kale',
            plantedOn: DateTime(2026, 9, 16),
          );
          final savedAt = DateTime(2026, 10, 13, 12);
          await c
              .read(weatherRepositoryProvider)
              .saveForecast(
                OpenMeteoForecastClient.parseForecast(
                  jsonDecode(_forecastJson) as Map<String, dynamic>,
                  fetchedAt: savedAt,
                ),
                savedAt,
              );
        },
        extra: [
          catalogProvider.overrideWith((ref) async => [plant]),
          gardenAlertsProvider.overrideWith((ref) async => []),
          topGuideThisWeekProvider.overrideWithValue(const AsyncData(null)),
        ],
      );
      await settleDrift(tester);
      expect(find.text('Fertilize Local Kale'), findsOneWidget);
      expect(find.text('Local Kale'), findsOneWidget);
      expect(find.byType(PlantingCard), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);
      expect(find.text(AlertBanner.offlineCopy), findsOneWidget);
      expect(find.text('Updated 5 h ago'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('refresh fetches weather once and reloads every section', (
      tester,
    ) async {
      final forecast = _FakeForecast();
      var gardens = 0;
      var tasks = 0;
      var recommendations = 0;
      var alerts = 0;
      final recs = _recs(3);
      final repository = FakeGuideRepository(
        pages: (_, _) => [testGuide('g', title: 'Reloaded guide')],
      );
      final c = await _pump(
        tester,
        forecast: forecast,
        localGarden: true,
        extra: [
          gardenProvider.overrideWith((ref) async {
            gardens++;
            return [_plantedView(recs)];
          }),
          careScheduleProvider.overrideWith((ref) async {
            tasks++;
            return [_careTask('Kale $tasks', DateTime(2026, 10, 7, 18))];
          }),
          recommendationsProvider.overrideWith((ref) async {
            recommendations++;
            return recs;
          }),
          gardenAlertsProvider.overrideWith((ref) async {
            alerts++;
            return [];
          }),
          guideRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pump();
      expect(forecast.requests, hasLength(1));
      expect(find.text('Water Kale 1'), findsOneWidget);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(forecast.requests, hasLength(2));
      expect([gardens, tasks, recommendations, alerts], [2, 2, 2, 2]);
      expect(repository.fetches, hasLength(2));
      expect(find.text('Water Kale 2'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('Top guide: the first Trending row, hidden when empty', (
      tester,
    ) async {
      final none = await pumpActive(tester);
      expect(find.text('Top guide this week'), findsNothing);
      expect(find.byType(GuideCard), findsNothing);
      await _unmount(tester, none);

      final c = await pumpActive(tester, topGuide: 'g1');
      expect(find.text('Top guide this week'), findsOneWidget);
      expect(find.byType(GuideCard), findsOneWidget);
      await tester.tap(find.byType(GuideCard));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CM-02 stub: g1'), findsOneWidget);
      await _unmount(tester, c);
    });

    testWidgets('zero plantings: HM-01 and no HM-02 section', (tester) async {
      final c = await _pump(
        tester,
        recs: _recs(25),
        extra: _hm02(
          tasks: [_careTask('Kale', DateTime(2026, 10, 7, 8))],
          alerts: [frost],
          topGuide: 'g1',
        ),
      );
      expect(find.text('Pick your first plant'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
      expect(find.byType(AlertBanner), findsNothing);
      expect(find.text('Top guide this week'), findsNothing);
      await _unmount(tester, c);
    });
  });

  testWidgets('a planting present → HM-02 sections, not the HM-01b prompt', (
    tester,
  ) async {
    final recs = _recs(25);
    final c = await _pump(tester, recs: recs, garden: [_plantedView(recs)]);

    // HM-02 replaces the first-run prompt once the garden has a planting.
    expect(find.text('Your garden'), findsOneWidget);
    expect(find.text('In season now'), findsOneWidget);
    expect(find.text('Pick your first plant'), findsNothing);
    expect(find.byType(PlantingCard), findsOneWidget);

    // HM-02 drops the season banner, not already-growing recommendations.
    expect(find.text('THIS SEASON'), findsNothing);
    final shown = tester
        .widgetList<PlantCard>(find.byType(PlantCard))
        .map((card) => card.plant.plant.id);
    expect(shown, contains(recs.first.plant.id));

    await _unmount(tester, c);
  });

  group('weather card', () {
    testWidgets('shows the fixture forecast between header and banner', (
      tester,
    ) async {
      final forecast = _FakeForecast();
      final c = await _pump(tester, recs: _recs(3), forecast: forecast);

      // Fixture: current 90.4 °F; today max 93.4, min 66.3.
      expect(find.text('90°'), findsOneWidget);
      expect(find.text('H 93 / L 66'), findsOneWidget);
      final card = tester.getRect(find.byType(WeatherMini));
      expect(
        card.top,
        greaterThan(tester.getRect(find.text('Good morning!')).bottom),
      );
      expect(
        card.bottom,
        lessThan(tester.getRect(find.text('THIS SEASON')).top),
      );
      expect(forecast.requests, hasLength(1));
      await _unmount(tester, c);
    });

    testWidgets('requests the profile location rounded to 2 decimals', (
      tester,
    ) async {
      final forecast = _FakeForecast();
      final c = await _pump(
        tester,
        recs: _recs(3),
        forecast: forecast,
        profile: Stream.value(_profileAt(30.4512, -91.1871)),
      );

      expect(forecast.requests, hasLength(1));
      final query = forecast.requests.single.queryParameters;
      expect(query['latitude'], '30.45');
      expect(query['longitude'], '-91.19');
      expect(c.exists(weatherProvider((30.45, -91.19))), isTrue);
      await _unmount(tester, c);
    });

    testWidgets('nothing and no request while the profile loads', (
      tester,
    ) async {
      final forecast = _FakeForecast();
      final pending = StreamController<UserProfile>();
      addTearDown(pending.close);
      final c = await _pump(
        tester,
        recs: _recs(3),
        forecast: forecast,
        profile: pending.stream,
      );

      expect(find.byType(WeatherMini), findsNothing);
      expect(forecast.requests, isEmpty);
      expect(find.text('THIS SEASON'), findsOneWidget);
      await _unmount(tester, c);
    });

    for (final dismissed in [false, true]) {
      testWidgets('pull-to-refresh forces one fetch '
          '(${dismissed ? 'HM-01b' : 'HM-01'})', (tester) async {
        final forecast = _FakeForecast();
        final c = await _pump(tester, recs: _recs(3), forecast: forecast);
        if (dismissed) await _pickLater(tester);
        expect(forecast.requests, hasLength(1));

        // The snapshot is minutes old, so only a forced refresh refetches.
        await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(forecast.requests, hasLength(2));
        expect(find.text('90°'), findsOneWidget);
        await _unmount(tester, c);
      });
    }

    testWidgets('a failed fetch shows the error state on Home at 360×800', (
      tester,
    ) async {
      final forecast = _FakeForecast()..fail = true;
      final c = await _pump(
        tester,
        recs: _recs(3),
        forecast: forecast,
        size: const Size(360, 800),
      );

      expect(find.text(WeatherMini.errorCopy), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.textContaining('°'), findsNothing);
      expect(tester.takeException(), isNull);
      await _unmount(tester, c);
    });

    testWidgets('WeatherMini opens WX-01', (tester) async {
      final c = await _pump(tester, recs: _recs(3));
      await tester.tap(find.byType(WeatherMini));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('WX-01 stub'), findsOneWidget);
      await _unmount(tester, c);
    });
  });

  group('slim card line', () {
    test('three or more names', () {
      expect(
        slimCardLine(['Kale', 'English Lavender', 'X'], SpaceType.balcony),
        'Kale, English Lavender and 1 more fit your balcony.',
      );
    });
    test('two names', () {
      expect(
        slimCardLine(['Kale', 'Basil'], SpaceType.windowsill),
        'Kale and Basil fit your windowsill.',
      );
    });
    test('one name', () {
      expect(
        slimCardLine(['Kale'], SpaceType.balcony),
        'Kale fits your balcony.',
      );
    });
    test('none', () {
      expect(slimCardLine([], SpaceType.balcony), isNull);
    });
  });

  for (final (h, m, greeting) in [
    (11, 59, 'Good morning!'),
    (12, 0, 'Good afternoon!'),
    (16, 59, 'Good afternoon!'),
    (17, 0, 'Good evening!'),
  ]) {
    testWidgets('greeting at $h:${m.toString().padLeft(2, '0')}', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        recs: _recs(1),
        now: DateTime(2026, 10, 7, h, m),
      );
      expect(find.text(greeting), findsOneWidget);
      await _unmount(tester, c);
    });
  }

  for (final (h, greeting) in [(9, 'Good morning!'), (13, 'Good afternoon!')]) {
    testWidgets('at 360×800 "$greeting" stays on one line', (tester) async {
      final c = await _pump(
        tester,
        recs: _recs(1),
        size: const Size(360, 800),
        now: DateTime(2026, 10, 7, h),
      );
      final text = find.text(greeting);
      final paragraph = tester.renderObject<RenderParagraph>(text);
      final rect = tester.getRect(text);
      final pill = tester.getRect(find.text('Baton Rouge'));

      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        rect.height,
        lessThanOrEqualTo(AppText.h1.fontSize! * AppText.h1.height!),
      );
      expect(rect.right, lessThanOrEqualTo(pill.left));
      await _unmount(tester, c);
    });
  }

  for (final dismissed in [false, true]) {
    testWidgets('360×800 with long names lays out without overflow '
        '(${dismissed ? 'HM-01b' : 'HM-01'})', (tester) async {
      final recs = [
        for (final s in _recs(12))
          scored(
            kaleWith({
              'id': s.plant.id,
              'commonName': 'Extra long ${s.plant.commonName} name here',
            }),
            score: 45,
            outdoorViable: false,
          ),
      ];
      final c = await _pump(
        tester,
        recs: recs,
        size: const Size(360, 800),
        now: DateTime(2026, 10, 7, 13),
      );
      if (dismissed) {
        await _pickLater(tester);
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
      await _unmount(tester, c);
    });
  }

  testWidgets('SEE ALL opens RC-01', (tester) async {
    final c = await _pump(tester, recs: _recs(25));
    final seeAll = find.text('SEE ALL');
    await tester.scrollUntilVisible(
      seeAll,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(seeAll);
    await tester.pump();
    await tester.tap(seeAll);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('RC-01 stub'), findsOneWidget);
    await _unmount(tester, c);
  });

  testWidgets('a carousel card opens PD-01 for that plant', (tester) async {
    final c = await _pump(tester, recs: _recs(25));
    final card = find.text('Plant 00');
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 500));
    // plan/01 HM-01 and HM-02: card → PD-01. PD-02 opens from PD-01's
    // Grow this (#73 comments).
    expect(find.text('PD-01 stub: plant-0'), findsOneWidget);
    expect(find.byType(GrowThisSheet), findsNothing);
    await _unmount(tester, c);
  });

  testWidgets('the slim card opens RC-01 once the carousel is collapsed', (
    tester,
  ) async {
    final c = await _pump(tester, recs: _recs(25));
    await _pickLater(tester);
    final slim = find.text('Pick your first plant');
    await tester.ensureVisible(slim);
    await tester.pump();
    await tester.tap(slim);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('RC-01 stub'), findsOneWidget);
    await _unmount(tester, c);
  });

  testWidgets('the gear opens settings', (tester) async {
    final c = await _pump(tester, recs: _recs(25));
    await tester.tap(find.byIcon(Symbols.settings_rounded));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ST-01 stub'), findsOneWidget);
    await _unmount(tester, c);
  });

  testWidgets('"I\'ll pick later" persists the dismissal to the profile row', (
    tester,
  ) async {
    final c = await _pump(tester, recs: _recs(25));
    final db = c.read(appDatabaseProvider);
    await tester.runAsync(
      () =>
          c.read(profileWriterProvider).save(defaultUserProfile, defaultSpace),
    );
    final before = await tester.runAsync(
      () => db.select(db.userProfileTable).getSingle(),
    );
    expect(before!.firstPlantPromptDismissed, isFalse);

    await _pickLater(tester);
    expect(c.read(firstPlantPromptDismissedProvider), isTrue);

    final persisted = await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        final row = await db.select(db.userProfileTable).getSingle();
        if (row.firstPlantPromptDismissed) return true;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      return false;
    });
    expect(persisted, isTrue);
    await _unmount(tester, c);
  });
}
