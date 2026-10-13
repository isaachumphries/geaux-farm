import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  test('each location is cached separately', () async {
    await load();
    await container.read(weatherProvider((29.95, -90.07)).future);
    expect(calls, 2);
  });
}
