import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/weather/application/garden_alerts_provider.dart';
import 'package:geaux_farm/features/weather/domain/garden_alerts.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';
import 'package:geaux_farm/features/weather/domain/weather_format.dart';
import 'package:geaux_farm/features/weather/presentation/alert_banner.dart';
import 'package:geaux_farm/features/weather/presentation/attribution_footer.dart';
import 'package:geaux_farm/features/weather/presentation/weather_hero.dart';
import 'package:geaux_farm/features/weather/presentation/weather_screen.dart';
import 'package:geaux_farm/features/weather/presentation/week_strip.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/weather_screen_harness.dart';

Finder _inHero(String text) =>
    find.descendant(of: find.byType(WeatherHero), matching: find.text(text));

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

void main() {
  testWidgets('default: sections 1, 3, 4, 5 and 6 in order with fixture data', (
    tester,
  ) async {
    await pumpWeatherScreen(tester, height: 2000);

    // Section 1: current 90.4 °F, clear, today 93.4 / 66.3, 41 %, 0 %, UV 1.45.
    expect(find.text('TODAY · TUE, OCT 13'), findsOneWidget);
    expect(_inHero('90°'), findsOneWidget);
    expect(find.text('Clear · H 93° / L 66°'), findsOneWidget);
    expect(_inHero('41%'), findsOneWidget);
    expect(_inHero('0%'), findsOneWidget);
    expect(find.text('1 · Low'), findsOneWidget);
    expect(find.text('Updated 0 min ago'), findsOneWidget);
    expect(find.text('Baton Rouge'), findsOneWidget);

    // Section 3: seven days from today.
    for (final day in ['Today', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon']) {
      expect(find.text(day), findsOneWidget, reason: day);
    }
    expect(find.text('Tue'), findsNothing);
    expect(find.text('28%'), findsOneWidget);

    // Section 4: today's sun times.
    expect(find.text('7:05 AM'), findsOneWidget);
    expect(find.text('6:35 PM'), findsOneWidget);
    expect(find.text('11h 30m'), findsOneWidget);

    // Section 5 and 6.
    expect(find.text('Zone 8b'), findsOneWidget);
    expect(find.text(attributionText), findsOneWidget);

    // Section 2: no outdoor plantings, so no alert is drawn.
    expect(find.byType(GeauxAlertBanner), findsNothing);

    final order = [
      _top(tester, find.text('Weather')),
      _top(tester, find.text('TODAY · TUE, OCT 13')),
      _top(tester, find.text('Next 7 days')),
      _top(tester, find.text('Sunrise')),
      _top(tester, find.text('Your climate')),
      _top(tester, find.text(attributionText)),
    ];
    expect(order, orderedEquals([...order]..sort()));
    expect(order.toSet().length, order.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('section 2: garden alerts sit between today and the week', (
    tester,
  ) async {
    await pumpWeatherScreen(
      tester,
      height: 2000,
      extra: [
        gardenAlertsProvider.overrideWith(
          (ref) async => [
            GardenAlert(
              type: GardenAlertType.frost,
              day: DateTime(2026, 10, 14),
              message: 'Frost Wed: cover or bring in Kale',
            ),
            GardenAlert(
              type: GardenAlertType.heat,
              day: DateTime(2026, 10, 15),
              message: 'Heat Thu: water early and shade young plants',
            ),
          ],
        ),
      ],
    );
    await tester.pump();

    final banners = tester
        .widgetList<AlertBanner>(find.byType(AlertBanner))
        .toList();
    expect(
      [for (final b in banners) b.type],
      [AlertBannerType.frost, AlertBannerType.heat],
    );
    final frost = _top(tester, find.text('Frost Wed: cover or bring in Kale'));
    final heat = _top(
      tester,
      find.text('Heat Thu: water early and shade young plants'),
    );
    expect(_top(tester, find.text('TODAY · TUE, OCT 13')), lessThan(frost));
    expect(frost, lessThan(heat));
    expect(heat, lessThan(_top(tester, find.text('Next 7 days'))));
  });

  testWidgets('loading: spinner, no empty sections, footer still there', (
    tester,
  ) async {
    final gate = Completer<void>();
    final rig = WeatherRig()..hold = gate.future;
    await pumpWeatherScreen(tester, rig: rig, height: 2000);

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Next 7 days'), findsNothing);
    expect(find.text('Sunrise'), findsNothing);
    expect(find.byType(WeatherHero), findsNothing);
    expect(find.byType(WeekStrip), findsNothing);
    expect(find.text(attributionText), findsOneWidget);

    // Release the request so its timeout timer does not outlive the test.
    gate.complete();
    await tester.pump();
    await tester.pump();
  });

  testWidgets('error with no cache: copy and Retry refetches', (tester) async {
    final rig = WeatherRig()..fail = true;
    await pumpWeatherScreen(tester, rig: rig, height: 2000);

    expect(
      find.text('Weather unavailable — check your connection'),
      findsOneWidget,
    );
    expect(find.text('Next 7 days'), findsNothing);
    expect(find.text(attributionText), findsOneWidget);
    expect(rig.calls, 1);

    rig.fail = false;
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    await tester.pump();
    expect(rig.calls, 2, reason: 'Retry is refresh(force: true)');
    expect(
      find.text('Weather unavailable — check your connection'),
      findsNothing,
    );
    expect(find.text('Next 7 days'), findsOneWidget);
  });

  group('offline banner', () {
    Future<WeatherRig> pumpFailedRefreshAfter(
      WidgetTester tester,
      Duration age,
    ) async {
      final rig = await pumpWeatherScreen(tester, height: 2000);
      rig
        ..now = fixtureNow.add(age)
        ..fail = true;
      await rig.refresh(tester);
      await tester.pump();
      return rig;
    }

    testWidgets('data older than 3 h after a failed refresh shows it', (
      tester,
    ) async {
      await pumpFailedRefreshAfter(
        tester,
        const Duration(hours: 3, minutes: 1),
      );
      expect(find.text('Showing saved weather'), findsOneWidget);
      expect(find.byIcon(Symbols.cloud_off_rounded), findsOneWidget);
      // The cached data stays on screen with its age.
      expect(_inHero('90°'), findsOneWidget);
      expect(find.text('Updated 3 h ago'), findsOneWidget);
      // The banner sits above section 1.
      expect(
        _top(tester, find.text('Showing saved weather')),
        lessThan(_top(tester, find.text('TODAY · TUE, OCT 13'))),
      );
    });

    testWidgets('exactly 3 h old is quiet: only the age shows', (tester) async {
      await pumpFailedRefreshAfter(tester, const Duration(hours: 3));
      expect(find.text('Showing saved weather'), findsNothing);
      expect(find.text('Updated 3 h ago'), findsOneWidget);
    });

    testWidgets('old but not failed: no banner', (tester) async {
      final rig = await pumpWeatherScreen(tester, height: 2000);
      rig.now = fixtureNow.add(const Duration(hours: 5));
      await rig.refresh(tester);
      // The refetch succeeds, so the data is fresh again.
      expect(find.text('Showing saved weather'), findsNothing);
      expect(find.text('Updated 0 min ago'), findsOneWidget);
    });
  });

  testWidgets('pull-to-refresh refetches even when the data is fresh', (
    tester,
  ) async {
    final rig = await pumpWeatherScreen(tester, height: 800);
    expect(rig.calls, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(rig.calls, 2);
  });

  testWidgets('climate pending: spinner under Your climate, weather intact', (
    tester,
  ) async {
    await pumpWeatherScreen(tester, climate: pendingClimate(), height: 2000);
    expect(find.text('Your climate'), findsOneWidget);
    expect(find.text('Zone 8b'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Next 7 days'), findsOneWidget);
    expect(find.text(attributionText), findsOneWidget);
  });

  testWidgets('climate failed: message and Retry, weather intact', (
    tester,
  ) async {
    await pumpWeatherScreen(tester, climate: failingClimate(), height: 2000);
    expect(find.text(WeatherScreen.climateErrorCopy), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    expect(find.text('Next 7 days'), findsOneWidget);
  });

  test('nextSevenDays starts at today and stops at the end of the data', () {
    WeatherDay day(String date) => WeatherDay(
      date: date,
      weatherCode: 0,
      tmaxF: 1,
      tminF: 1,
      precipIn: 0,
      precipProb: 0,
      uvMax: 0,
      sunshineS: 0,
      daylightS: 0,
      et0In: 0,
      sunrise: '${date}T07:00',
      sunset: '${date}T18:00',
    );
    final days = [for (var d = 10; d <= 16; d++) day('2026-10-$d')];
    expect(nextSevenDays(days, DateTime(2026, 10, 12)).map((d) => d.date), [
      '2026-10-12',
      '2026-10-13',
      '2026-10-14',
      '2026-10-15',
      '2026-10-16',
    ]);
    expect(nextSevenDays(days, DateTime(2026, 11, 1)), isEmpty);
  });
}
