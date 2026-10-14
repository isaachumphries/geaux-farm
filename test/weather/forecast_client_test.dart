import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final fixture = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
    .readAsStringSync();

void main() {
  final fetchedAt = DateTime(2026, 10, 13, 17, 20);

  test('request carries exactly the plan/06 query parameters', () {
    final uri = OpenMeteoForecastClient.forecastUri(30.45, -91.19);
    expect(uri.scheme, 'https');
    expect(uri.host, 'api.open-meteo.com');
    expect(uri.path, '/v1/forecast');
    expect(uri.queryParameters, {
      'latitude': '30.45',
      'longitude': '-91.19',
      'current':
          'temperature_2m,relative_humidity_2m,cloud_cover,precipitation,'
          'weather_code,uv_index,is_day',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,'
          'precipitation_sum,precipitation_probability_max,uv_index_max,'
          'sunshine_duration,daylight_duration,et0_fao_evapotranspiration,'
          'sunrise,sunset',
      'timezone': 'auto',
      'past_days': '7',
      'forecast_days': '7',
      'temperature_unit': 'fahrenheit',
      'precipitation_unit': 'inch',
    });
    expect(
      uri.toString(),
      'https://api.open-meteo.com/v1/forecast?latitude=30.45&longitude=-91.19'
      '&current=temperature_2m,relative_humidity_2m,cloud_cover,precipitation,'
      'weather_code,uv_index,is_day&daily=weather_code,temperature_2m_max,'
      'temperature_2m_min,precipitation_sum,precipitation_probability_max,'
      'uv_index_max,sunshine_duration,daylight_duration,'
      'et0_fao_evapotranspiration,sunrise,sunset&timezone=auto&past_days=7'
      '&forecast_days=7&temperature_unit=fahrenheit&precipitation_unit=inch',
    );
  });

  test('parses the recorded Baton Rouge response', () async {
    Uri? requested;
    final client = OpenMeteoForecastClient(
      MockClient((req) async {
        requested = req.url;
        return http.Response(fixture, 200);
      }),
    );
    final snap = await client.fetchForecast(
      30.45,
      -91.19,
      fetchedAt: fetchedAt,
    );

    expect(requested, OpenMeteoForecastClient.forecastUri(30.45, -91.19));
    expect(snap.fetchedAt, fetchedAt);
    expect(snap.days, hasLength(14));
    expect(snap.days.first.date, '2026-10-06');
    expect(snap.days.last.date, '2026-10-19');

    final today = todayRow(snap.days, DateTime(2026, 10, 13, 23, 59))!;
    expect(today.date, '2026-10-13');
    expect(today.tmaxF, 93.4);
    expect(today.tminF, 66.3);
    expect(today.weatherCode, 45);
    expect(today.precipProb, 0);
    expect(today.uvMax, 6.5);
    expect(today.sunrise, '2026-10-13T07:05');
    expect(today.sunset, '2026-10-13T18:35');

    expect(snap.current.temperatureF, 90.4);
    expect(snap.current.weatherCode, 0);
    expect(snap.current.isDay, isTrue);
    expect(snap.current.relativeHumidity, 41);
    expect(snap.current.uvIndex, 1.45);
    expect(snap.current.time, DateTime(2026, 10, 13, 17, 15));
  });

  test('todayRow is null when the date is outside the forecast', () async {
    final snap = OpenMeteoForecastClient.parseForecast(
      jsonDecode(fixture) as Map<String, dynamic>,
      fetchedAt: fetchedAt,
    );
    expect(todayRow(snap.days, DateTime(2026, 10, 20)), isNull);
    expect(todayRow(snap.days, DateTime(2026, 10, 6))!.date, '2026-10-06');
  });

  group('NetworkException', () {
    Future<void> expectNetworkError(OpenMeteoForecastClient client) =>
        expectLater(
          client.fetchForecast(30.45, -91.19, fetchedAt: fetchedAt),
          throwsA(isA<NetworkException>()),
        );

    test('on timeout', () async {
      final never = Completer<http.Response>();
      await expectNetworkError(
        OpenMeteoForecastClient(
          MockClient((_) => never.future),
          timeout: const Duration(milliseconds: 10),
        ),
      );
    });

    test('defaults to a 15 s timeout', () {
      final client = OpenMeteoForecastClient(
        MockClient((_) async => http.Response('', 200)),
      );
      expect(client.timeout, const Duration(seconds: 15));
    });

    test('on HTTP 500', () async {
      await expectLater(
        OpenMeteoForecastClient(
          MockClient((_) async => http.Response('oops', 500)),
        ).fetchForecast(30.45, -91.19, fetchedAt: fetchedAt),
        throwsA(
          isA<NetworkException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
    });

    test('on socket error', () async {
      await expectNetworkError(
        OpenMeteoForecastClient(
          MockClient((_) async => throw const SocketException('down')),
        ),
      );
    });

    test('on malformed JSON', () async {
      await expectNetworkError(
        OpenMeteoForecastClient(
          MockClient((_) async => http.Response('{"current": ', 200)),
        ),
      );
      await expectNetworkError(
        OpenMeteoForecastClient(
          MockClient((_) async => http.Response('{"current": {}}', 200)),
        ),
      );
    });
  });
}
