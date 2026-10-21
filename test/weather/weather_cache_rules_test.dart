import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/in_memory_database.dart';

final _fixture = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
    .readAsStringSync();

const _loc = (30.45, -91.19);
final _t0 = DateTime(2026, 10, 13, 17, 20);

/// plan/06 § Caching and refresh: app start/resume refetches only when the
/// last successful fetch is > 60 min old; a failed fetch keeps the cached
/// snapshot. The free Open-Meteo API is the reason (AGENTS.md § 7).
void main() {
  late DateTime now;
  late int calls;
  late Future<http.Response> Function() respond;
  late ProviderContainer container;

  setUp(() {
    now = _t0;
    calls = 0;
    respond = () async => http.Response(_fixture, 200);
    container = ProviderContainer(
      overrides: [
        inMemoryDatabaseOverride(),
        weatherClockProvider.overrideWithValue(() => now),
        forecastClientProvider.overrideWithValue(
          OpenMeteoForecastClient(
            MockClient((_) {
              calls++;
              return respond();
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<WeatherState> load() => container.read(weatherProvider(_loc).future);
  WeatherNotifier notifier() => container.read(weatherProvider(_loc).notifier);
  WeatherState current() => container.read(weatherProvider(_loc)).requireValue;

  test('60 min 1 s after the fetch, resume refetches', () async {
    await load();
    now = _t0.add(const Duration(minutes: 60, seconds: 1));
    await notifier().refresh();
    expect(calls, 2);
    expect(current().snapshot.fetchedAt, now);
  });

  test('the 60 min window restarts at the last successful fetch', () async {
    await load();
    now = _t0.add(const Duration(minutes: 61));
    await notifier().refresh();
    final second = now;

    now = second.add(const Duration(minutes: 60));
    await notifier().refresh();
    expect(calls, 2);

    now = second.add(const Duration(minutes: 61));
    await notifier().refresh();
    expect(calls, 3);
  });

  test('a failed refresh keeps the cached fetchedAt, so the next resume '
      'tries again', () async {
    await load();
    respond = () async => http.Response('down', 503);
    now = _t0.add(const Duration(minutes: 61));
    await notifier().refresh();
    expect(current().snapshot.fetchedAt, _t0);
    expect(
      current().refreshError,
      isA<NetworkException>().having((e) => e.statusCode, 'status', 503),
    );

    respond = () async => http.Response(_fixture, 200);
    now = _t0.add(const Duration(minutes: 62));
    await notifier().refresh();
    expect(calls, 3);
    expect(current().snapshot.fetchedAt, now);
    expect(current().refreshError, isNull);
  });

  test('a failed pull-to-refresh on fresh data keeps the snapshot', () async {
    await load();
    respond = () async => throw const SocketException('offline');
    now = _t0.add(const Duration(minutes: 5));
    await notifier().refresh(force: true);
    final state = container.read(weatherProvider(_loc));
    expect(state.hasError, isFalse);
    expect(state.requireValue.snapshot.fetchedAt, _t0);
    expect(state.requireValue.snapshot.days, hasLength(14));
    expect(state.requireValue.refreshError, isA<NetworkException>());
  });

  test('overlapping refreshes send one request', () async {
    await load();
    final gate = Completer<http.Response>();
    respond = () => gate.future;
    now = _t0.add(const Duration(minutes: 61));

    final first = notifier().refresh();
    final second = notifier().refresh(force: true);
    gate.complete(http.Response(_fixture, 200));
    await Future.wait([first, second]);
    expect(calls, 2);
  });
}
