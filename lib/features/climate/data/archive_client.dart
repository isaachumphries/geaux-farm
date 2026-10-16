import 'dart:convert';

import '../../../core/http.dart';
import '../domain/climate_normals.dart';

/// Fetches 5 complete years of daily history from the Open-Meteo archive
/// (plan/04 § Climate profile step 1). One request per call, no retries.
class ArchiveClient {
  ArchiveClient(this._http);

  final AppHttpClient _http;

  /// The archive request for the 5 calendar years before [currentYear].
  /// UV is not requested: the archive has none.
  static Uri archiveUri(double lat, double lon, {required int currentYear}) =>
      Uri.parse(
        'https://archive-api.open-meteo.com/v1/archive'
        '?latitude=${lat.toStringAsFixed(2)}'
        '&longitude=${lon.toStringAsFixed(2)}'
        '&start_date=${currentYear - 5}-01-01'
        '&end_date=${currentYear - 1}-12-31'
        '&daily=temperature_2m_min,temperature_2m_max,precipitation_sum,'
        'relative_humidity_2m_mean,cloud_cover_mean,sunshine_duration'
        '&timezone=auto&temperature_unit=fahrenheit&precipitation_unit=inch',
      );

  /// Daily rows for [lat], [lon]. Any failure (network, timeout, non-200,
  /// unparsable body) throws [ClimateUnavailableException].
  Future<List<DailyClimateRow>> fetchDaily(
    double lat,
    double lon, {
    required int currentYear,
  }) async {
    try {
      final response = await _http.get(
        archiveUri(lat, lon, currentYear: currentYear),
      );
      if (response.statusCode != 200) {
        throw ClimateUnavailableException(
          'Archive request failed (${response.statusCode})',
        );
      }
      return parseDaily(jsonDecode(response.body) as Map<String, dynamic>);
    } on NetworkException catch (e) {
      throw ClimateUnavailableException(e.message);
    } on FormatException catch (e) {
      throw ClimateUnavailableException('Malformed archive: ${e.message}');
    } on TypeError catch (e) {
      throw ClimateUnavailableException('Malformed archive: $e');
    }
  }

  /// Parses the `daily` block. Throws [FormatException] or [TypeError] on
  /// an unexpected shape.
  static List<DailyClimateRow> parseDaily(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final time = (daily['time'] as List).cast<String>();
    List<double?> field(String key) => [
      for (final v in daily[key] as List) (v as num?)?.toDouble(),
    ];
    final minF = field('temperature_2m_min');
    final maxF = field('temperature_2m_max');
    final precip = field('precipitation_sum');
    final rh = field('relative_humidity_2m_mean');
    final cloud = field('cloud_cover_mean');
    final sun = field('sunshine_duration');
    for (final f in [minF, maxF, precip, rh, cloud, sun]) {
      if (f.length != time.length) {
        throw const FormatException('Daily arrays differ in length');
      }
    }
    if (time.isEmpty) throw const FormatException('No daily rows');
    return [
      for (var i = 0; i < time.length; i++)
        DailyClimateRow(
          date: DateTime.parse(time[i]),
          minF: minF[i],
          maxF: maxF[i],
          precipIn: precip[i],
          rhPct: rh[i],
          cloudPct: cloud[i],
          sunshineS: sun[i],
        ),
    ];
  }
}
