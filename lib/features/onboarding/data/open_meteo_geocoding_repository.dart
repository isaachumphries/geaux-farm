import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/http.dart';
import '../domain/geocoding_repository.dart';

/// City search through the Open-Meteo geocoding API (plan/02 § OB-02).
class OpenMeteoGeocodingRepository implements GeocodingRepository {
  OpenMeteoGeocodingRepository(this._http);

  final AppHttpClient _http;

  static Uri searchUri(String query) => Uri.parse(
    'https://geocoding-api.open-meteo.com/v1/search'
    '?name=${Uri.encodeComponent(query)}&count=8&language=en',
  );

  @override
  Future<List<GeoPlace>> search(String query) async {
    final response = await _http.get(searchUri(query));
    if (response.statusCode != 200) {
      throw NetworkException(
        'Geocoding request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    // Open-Meteo leaves `results` out when nothing matches.
    final results = (body['results'] as List<dynamic>?) ?? const [];
    return [
      for (final r in results.cast<Map<String, dynamic>>())
        GeoPlace(
          name: r['name'] as String? ?? '',
          admin1: r['admin1'] as String? ?? '',
          countryCode: r['country_code'] as String? ?? '',
          lat: (r['latitude'] as num).toDouble(),
          lon: (r['longitude'] as num).toDouble(),
          postcode: (r['postcodes'] as List<dynamic>?)?.firstOrNull as String?,
          timezone: r['timezone'] as String?,
        ),
    ];
  }
}

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenMeteoGeocodingRepository(AppHttpClient(client));
});
