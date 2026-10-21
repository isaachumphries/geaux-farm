import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:geaux_farm/features/weather/data/weather_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/in_memory_database.dart';

final fixture = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
    .readAsStringSync();

const loc = (30.45, -91.19);

void main() {
  late DateTime now;
  late int calls;
  late bool fail;
  late ProviderContainer container;

  setUp(() {
    now = DateTime(2026, 10, 13, 17, 20);
    calls = 0;
    fail = false;
    container = ProviderContainer(
      overrides: [
        inMemoryDatabaseOverride(),
        weatherClockProvider.overrideWithValue(() => now),
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
    );
    addTearDown(container.dispose);
  });

  Future<WeatherState> load() => container.read(weatherProvider(loc).future);
  WeatherNotifier notifier() => container.read(weatherProvider(loc).notifier);

  test(
    'first build fetches once and stamps fetchedAt from the clock',
    () async {
      final s = await load();
      expect(calls, 1);
      expect(s.snapshot.fetchedAt, DateTime(2026, 10, 13, 17, 20));
      expect(s.snapshot.days, hasLength(14));
      expect(s.refreshError, isNull);
    },
  );

  test('refresh 59 min and 60 min later does not refetch', () async {
    await load();
    now = now.add(const Duration(minutes: 59));
    await notifier().refresh();
    now = now.add(const Duration(minutes: 1));
    await notifier().refresh();
    expect(calls, 1);
  });

  test('refresh 61 min later refetches and updates fetchedAt', () async {
    await load();
    now = now.add(const Duration(minutes: 61));
    await notifier().refresh();
    expect(calls, 2);
    expect(
      container.read(weatherProvider(loc)).value!.snapshot.fetchedAt,
      DateTime(2026, 10, 13, 18, 21),
    );
  });

  test('forced refresh fetches even when fresh', () async {
    await load();
    now = now.add(const Duration(minutes: 5));
    await notifier().refresh(force: true);
    expect(calls, 2);
  });

  test(
    'failed refresh keeps the last snapshot and exposes the error',
    () async {
      await load();
      fail = true;
      now = now.add(const Duration(minutes: 61));
      await notifier().refresh();
      expect(calls, 2);
      final state = container.read(weatherProvider(loc));
      expect(state.hasError, isFalse);
      expect(state.value!.snapshot.fetchedAt, DateTime(2026, 10, 13, 17, 20));
      expect(state.value!.refreshError, isA<NetworkException>());

      // A later success clears the error.
      fail = false;
      await notifier().refresh(force: true);
      expect(container.read(weatherProvider(loc)).value!.refreshError, isNull);
    },
  );

  test('failed first fetch is an error with no data, no auto-retry', () async {
    fail = true;
    final sub = container.listen(weatherProvider(loc), (_, _) {});
    addTearDown(sub.close);
    await expectLater(load(), throwsA(isA<NetworkException>()));
    final state = container.read(weatherProvider(loc));
    expect(state.hasError, isTrue);
    expect(state.hasValue, isFalse);
    expect(calls, 1);

    fail = false;
    await notifier().refresh();
    expect(calls, 2);
    expect(
      container.read(weatherProvider(loc)).value!.snapshot.days,
      hasLength(14),
    );
  });

  test('a second location reuses the one on-device cache', () async {
    // plan/09 § Drift schema keeps one forecast: neither weather table
    // carries lat/lon, and the app only fetches the profile's location.
    await load();
    final other = await container.read(weatherProvider((29.95, -90.07)).future);
    expect(calls, 1);
    expect(other.days, hasLength(14));
  });

  group('the Drift cache', () {
    Future<void> seedCache(DateTime fetchedAt) async {
      final repo = container.read(weatherRepositoryProvider);
      final snapshot = OpenMeteoForecastClient.parseForecast(
        jsonDecode(fixture) as Map<String, dynamic>,
        fetchedAt: fetchedAt,
      );
      await repo.saveForecast(snapshot, fetchedAt);
    }

    test('an empty cache fetches and saves 14 rows', () async {
      await load();
      final cached = await container
          .read(weatherRepositoryProvider)
          .loadCached();
      expect(calls, 1);
      expect(cached!.days, hasLength(14));
      expect(cached.fetchedAt, now);
    });

    test('a 59-minute-old cache is served without a fetch', () async {
      await seedCache(now.subtract(const Duration(minutes: 59)));
      final state = await load();
      expect(calls, 0);
      expect(state.days, hasLength(14));
      expect(state.fetchedAt, now.subtract(const Duration(minutes: 59)));
      expect(state.isOfflineStale, isFalse);
    });

    test('a 61-minute-old cache triggers exactly one fetch', () async {
      await seedCache(now.subtract(const Duration(minutes: 61)));
      final state = await load();
      expect(calls, 1);
      expect(state.fetchedAt, now);
    });

    test('a failed fetch over a 2-hour cache is not offline stale', () async {
      await seedCache(now.subtract(const Duration(hours: 2)));
      fail = true;
      final state = await load();
      expect(calls, 1);
      expect(state.fetchedAt, now.subtract(const Duration(hours: 2)));
      expect(state.isOfflineStale, isFalse);
      expect(state.refreshError, isA<NetworkException>());
    });

    test('a failed fetch over a 4-hour cache is offline stale', () async {
      await seedCache(now.subtract(const Duration(hours: 4)));
      fail = true;
      final state = await load();
      expect(state.days, hasLength(14));
      expect(state.isOfflineStale, isTrue);
    });

    test('a failed refresh over a 4-hour cache is offline stale', () async {
      await seedCache(now.subtract(const Duration(hours: 4)));
      fail = true;
      await load();
      // Retry, which the error banner offers, fails again on the same cache.
      await notifier().refresh(force: true);
      expect(calls, 2);
      expect(
        container.read(weatherProvider(loc)).value!.isOfflineStale,
        isTrue,
      );
    });
  });

  group('weatherRefreshedProvider', () {
    test('a successful refresh emits exactly one event', () async {
      final events = <DateTime>[];
      final sub = container.listen(
        weatherRefreshedProvider,
        (_, next) => next.whenData(events.add),
      );
      addTearDown(sub.close);

      await load();
      await pumpEventQueue();
      expect(events, [now]);

      now = now.add(const Duration(minutes: 61));
      await notifier().refresh();
      await pumpEventQueue();
      expect(events, [DateTime(2026, 10, 13, 17, 20), now]);
    });

    test('a failed refresh emits nothing', () async {
      final events = <DateTime>[];
      final sub = container.listen(
        weatherRefreshedProvider,
        (_, next) => next.whenData(events.add),
      );
      addTearDown(sub.close);

      await load();
      await pumpEventQueue();
      fail = true;
      now = now.add(const Duration(minutes: 61));
      await notifier().refresh();
      await pumpEventQueue();
      expect(events, hasLength(1));
    });
  });
}
