import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/http.dart';
import '../domain/weather.dart';

/// Fetches the 14-day forecast (7 past + 7 ahead) from Open-Meteo using the
/// request in plan/06 § Requests. One attempt per call, no retries.
class OpenMeteoForecastClient {
  OpenMeteoForecastClient(this._client, {this.timeout = defaultTimeout});

  static const defaultTimeout = Duration(seconds: 15);

  final http.Client _client;
  final Duration timeout;

  static Uri forecastUri(double lat, double lon) => Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=${lat.toStringAsFixed(2)}&longitude=${lon.toStringAsFixed(2)}'
    '&current=temperature_2m,relative_humidity_2m,cloud_cover,precipitation,'
    'weather_code,uv_index,is_day'
    '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
    'precipitation_sum,precipitation_probability_max,uv_index_max,'
    'sunshine_duration,daylight_duration,et0_fao_evapotranspiration,'
    'sunrise,sunset'
    '&timezone=auto&past_days=7&forecast_days=7'
    '&temperature_unit=fahrenheit&precipitation_unit=inch',
  );

  /// Returns the parsed forecast stamped with [fetchedAt].
  Future<WeatherSnapshot> fetchForecast(
    double lat,
    double lon, {
    required DateTime fetchedAt,
  }) async {
    final http.Response response;
    try {
      response = await _client.get(forecastUri(lat, lon)).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException('Forecast request timed out');
    } on SocketException catch (e) {
      throw NetworkException('Socket error: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Client error: ${e.message}');
    }
    if (response.statusCode != 200) {
      throw NetworkException(
        'Forecast request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return parseForecast(json, fetchedAt: fetchedAt);
    } on FormatException catch (e) {
      throw NetworkException('Malformed forecast JSON: ${e.message}');
    } on TypeError catch (e) {
      throw NetworkException('Malformed forecast JSON: $e');
    }
  }

  /// Parses a decoded forecast response. Throws [TypeError] or
  /// [FormatException] on unexpected shapes.
  static WeatherSnapshot parseForecast(
    Map<String, dynamic> json, {
    required DateTime fetchedAt,
  }) {
    final c = json['current'] as Map<String, dynamic>;
    final current = parseCurrent(c);

    final d = json['daily'] as Map<String, dynamic>;
    List<dynamic> col(String key) => d[key] as List<dynamic>;
    final dates = col('time');
    final codes = col('weather_code');
    final tmax = col('temperature_2m_max');
    final tmin = col('temperature_2m_min');
    final precip = col('precipitation_sum');
    final prob = col('precipitation_probability_max');
    final uv = col('uv_index_max');
    final sunshine = col('sunshine_duration');
    final daylight = col('daylight_duration');
    final et0 = col('et0_fao_evapotranspiration');
    final sunrise = col('sunrise');
    final sunset = col('sunset');

    final days = [
      for (var i = 0; i < dates.length; i++)
        WeatherDay(
          date: dates[i] as String,
          weatherCode: _i(codes[i]),
          tmaxF: _d(tmax[i]),
          tminF: _d(tmin[i]),
          precipIn: _d(precip[i]),
          precipProb: prob[i] == null ? null : _i(prob[i]),
          uvMax: uv[i] == null ? null : _d(uv[i]),
          sunshineS: _d(sunshine[i]),
          daylightS: _d(daylight[i]),
          et0In: _d(et0[i]),
          sunrise: sunrise[i] as String,
          sunset: sunset[i] as String,
        ),
    ];
    return WeatherSnapshot(
      current: current,
      currentJson: c,
      days: days,
      fetchedAt: fetchedAt,
    );
  }

  /// Parses one `current` block. The weather repository reuses this to read
  /// the raw JSON back out of `weather_current`.
  static WeatherCurrent parseCurrent(Map<String, dynamic> c) => WeatherCurrent(
    temperatureF: _d(c['temperature_2m']),
    relativeHumidity: _i(c['relative_humidity_2m']),
    cloudCover: _i(c['cloud_cover']),
    precipitationIn: _d(c['precipitation']),
    weatherCode: _i(c['weather_code']),
    uvIndex: _d(c['uv_index']),
    isDay: _i(c['is_day']) == 1,
    time: DateTime.parse(c['time'] as String),
  );

  static double _d(Object? v) => (v as num).toDouble();
  static int _i(Object? v) => (v as num).toInt();
}
