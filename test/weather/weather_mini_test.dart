import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';
import 'package:geaux_farm/features/weather/presentation/weather_mini.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_symbols_icons/symbols.dart';

final fixture = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
    .readAsStringSync();

final fetchedAt = DateTime(2026, 10, 13, 17, 20);

WeatherSnapshot snapshot({bool isDay = true}) {
  final json = jsonDecode(fixture) as Map<String, dynamic>;
  (json['current'] as Map<String, dynamic>)['is_day'] = isDay ? 1 : 0;
  return OpenMeteoForecastClient.parseForecast(json, fetchedAt: fetchedAt);
}

Future<void> pumpMini(
  WidgetTester tester,
  AsyncValue<WeatherState> state, {
  DateTime? now,
  VoidCallback? onRetry,
  VoidCallback? onTap,
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: WeatherMini(
            state: state,
            now: now ?? fetchedAt,
            onRetry: onRetry ?? () {},
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('fixture renders current temp and today\'s stats', (
    tester,
  ) async {
    await pumpMini(tester, AsyncData(WeatherState(snapshot())));

    // current 90.4 → 90; today 2026-10-13: max 93.4, min 66.3, 0 %, UV 6.5.
    expect(find.text('90°'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('H 93 / L 66'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('UV 7'), findsOneWidget);
    expect(find.byIcon(Symbols.clear_day_rounded), findsOneWidget);
    expect(find.textContaining('Updated'), findsNothing);
    expect(find.byIcon(Symbols.chevron_right_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('night uses the clear_night icon with the same label', (
    tester,
  ) async {
    await pumpMini(tester, AsyncData(WeatherState(snapshot(isDay: false))));
    expect(find.text('Clear'), findsOneWidget);
    expect(find.byIcon(Symbols.clear_night_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.clear_day_rounded), findsNothing);
  });

  testWidgets('chevron and tap only when onTap is set', (tester) async {
    var taps = 0;
    await pumpMini(
      tester,
      AsyncData(WeatherState(snapshot())),
      onTap: () => taps++,
    );
    expect(find.byIcon(Symbols.chevron_right_rounded), findsOneWidget);
    await tester.tap(find.text('90°'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('loading shows a progress indicator and no stats', (
    tester,
  ) async {
    await pumpMini(tester, const AsyncLoading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('°'), findsNothing);
    expect(find.text(WeatherMini.errorCopy), findsNothing);
  });

  testWidgets('error with no data shows copy and Retry calls once', (
    tester,
  ) async {
    var retries = 0;
    await pumpMini(
      tester,
      AsyncError(const NetworkException('down'), StackTrace.empty),
      onRetry: () => retries++,
    );
    expect(
      find.text('Weather unavailable — check your connection'),
      findsOneWidget,
    );
    expect(find.textContaining('°'), findsNothing);
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('failed refresh keeps data and shows its age', (tester) async {
    final cached = AsyncData(
      WeatherState(snapshot(), refreshError: const NetworkException('down')),
    );
    await pumpMini(
      tester,
      cached,
      now: fetchedAt.add(const Duration(minutes: 75)),
    );
    expect(find.text('90°'), findsOneWidget);
    expect(find.text('Updated 1 h ago'), findsOneWidget);
    expect(find.text(WeatherMini.errorCopy), findsNothing);
  });

  test('updatedAgo switches from minutes to hours at 60 min', () {
    String at(int minutes) =>
        updatedAgo(fetchedAt, fetchedAt.add(Duration(minutes: minutes)));
    expect(at(0), 'Updated 0 min ago');
    expect(at(5), 'Updated 5 min ago');
    expect(at(59), 'Updated 59 min ago');
    expect(at(60), 'Updated 1 h ago');
    expect(at(150), 'Updated 2 h ago');
    expect(
      updatedAgo(fetchedAt, fetchedAt.subtract(const Duration(minutes: 3))),
      'Updated 0 min ago',
    );
  });

  testWidgets('fits 360 wide with chevron and stale line without overflow', (
    tester,
  ) async {
    await pumpMini(
      tester,
      AsyncData(
        WeatherState(snapshot(), refreshError: const NetworkException('down')),
      ),
      now: fetchedAt.add(const Duration(minutes: 5)),
      onTap: () {},
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Updated 5 min ago'), findsOneWidget);
    await pumpMini(
      tester,
      AsyncError(const NetworkException('down'), StackTrace.empty),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeatherMiniCard Retry forces exactly one refetch', (
    tester,
  ) async {
    var calls = 0;
    var fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherClockProvider.overrideWithValue(() => fetchedAt),
          forecastClientProvider.overrideWithValue(
            OpenMeteoForecastClient(
              MockClient((_) async {
                calls++;
                return fail
                    ? http.Response('down', 503)
                    : http.Response(fixture, 200);
              }),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WeatherMiniCard(lat: 30.45, lon: -91.19)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text(WeatherMini.errorCopy), findsOneWidget);

    fail = false;
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('90°'), findsOneWidget);
  });
}
