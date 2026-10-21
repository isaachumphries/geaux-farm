import 'dart:convert';

import '../../../core/http.dart';
import '../domain/distance.dart';
import '../domain/market.dart';

/// Farmers markets from OpenStreetMap via Overpass (plan/08 § Markets).
///
/// The USDA Local Food Portal was the first choice, but it needs a
/// registered API key and its data-sharing page answered 403 during
/// planning, so this is the fallback the issue names.
class OverpassMarketsClient {
  OverpassMarketsClient(this._http);

  final AppHttpClient _http;

  static final endpoint = Uri.parse('https://overpass-api.de/api/interpreter');

  /// Radius of the search, in metres.
  static const int searchRadiusMetres = 40000;

  /// Server-side limit inside the query. This is **not** the client
  /// timeout: [AppHttpClient.timeout] is the 15 s one, and the two are
  /// deliberately different (plan/09 § Errors).
  static const int queryTimeoutSeconds = 25;

  /// Most elements Overpass should return.
  static const int maxResults = 50;

  /// The Overpass QL for markets within [searchRadiusMetres] of a point.
  static String query(double lat, double lon) =>
      '[out:json][timeout:$queryTimeoutSeconds];'
      'nwr["amenity"="marketplace"](around:$searchRadiusMetres,$lat,$lon);'
      'out center $maxResults;';

  /// Markets near ([lat], [lon]), nearest first. One request, no retry.
  Future<List<Market>> fetchMarkets(double lat, double lon) async {
    final response = await _http.post(endpoint, body: query(lat, lon));
    if (response.statusCode != 200) {
      throw NetworkException(
        'Overpass request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return parseMarkets(json, lat: lat, lon: lon);
    } on FormatException catch (e) {
      throw NetworkException('Malformed Overpass JSON: ${e.message}');
    } on TypeError catch (e) {
      throw NetworkException('Malformed Overpass JSON: $e');
    }
  }

  /// Turns a decoded Overpass response into markets sorted by distance.
  ///
  /// Ways and relations carry their coordinates under `center`; nodes have
  /// `lat`/`lon` directly. An element with no name or no coordinates is
  /// skipped, because a row needs both.
  static List<Market> parseMarkets(
    Map<String, dynamic> json, {
    required double lat,
    required double lon,
  }) {
    final elements = json['elements'] as List<dynamic>? ?? const [];
    final markets = <Market>[];
    for (final raw in elements) {
      final element = raw as Map<String, dynamic>;
      final tags = element['tags'] as Map<String, dynamic>? ?? const {};
      final name = tags['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;
      final center = element['center'] as Map<String, dynamic>?;
      final elementLat = (center?['lat'] ?? element['lat']) as num?;
      final elementLon = (center?['lon'] ?? element['lon']) as num?;
      if (elementLat == null || elementLon == null) continue;
      markets.add(
        Market(
          id: '${element['type']}/${element['id']}',
          name: name,
          lat: elementLat.toDouble(),
          lon: elementLon.toDouble(),
          distanceMi: distanceMiles(
            lat,
            lon,
            elementLat.toDouble(),
            elementLon.toDouble(),
          ),
          openingHours: tags['opening_hours'] as String?,
          website: tags['website'] as String?,
        ),
      );
    }
    markets.sort((a, b) => a.distanceMi.compareTo(b.distanceMi));
    return markets;
  }
}
