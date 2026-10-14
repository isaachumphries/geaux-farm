import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/home/application/first_plant_prompt_provider.dart';
import 'package:geaux_farm/features/home/domain/home_copy.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/recommendations/application/recommendations_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_card.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:geaux_farm/features/weather/presentation/weather_mini.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

class _PendingClimate extends ClimateNotifier {
  @override
  Future<ClimateProfile> build() => Completer<ClimateProfile>().future;
}

class _FailedClimate extends ClimateNotifier {
  @override
  Future<ClimateProfile> build() async => throw StateError('build failed');
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
      if (climate != null) climateProvider.overrideWith(climate),
      forecastClientProvider.overrideWithValue(
        (forecast ?? _FakeForecast()).client,
      ),
      weatherClockProvider.overrideWithValue(() => DateTime(2026, 10, 13, 17)),
      if (profile != null) userProfileProvider.overrideWith((ref) => profile),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const HomeFirstRunScreen(),
      ),
    ),
  );
  // One frame for the providers, one for the fake forecast to land.
  await tester.pump();
  await tester.pump();
  return container;
}

/// Unmounts the screen so the midnight timer and container go away before
/// the binding checks for pending timers.
Future<void> _unmount(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
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

  testWidgets('a failed climate build keeps loading instead of erroring', (
    tester,
  ) async {
    final c = await _pump(tester, recs: _recs(5), climate: _FailedClimate.new);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PlantCard), findsNothing);
    expect(find.text("Couldn't load plants."), findsNothing);
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
}
