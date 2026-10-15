import 'dart:convert';

import '../../../core/http.dart';

/// USDA hardiness zone lookup by ZIP via phzmapi.org (plan/04 § Climate
/// profile step 4).
class PhzmapClient {
  PhzmapClient(this._http);

  final AppHttpClient _http;

  /// The `zone` for [zip], e.g. `8b`. Throws on any failure: network,
  /// non-200, or a missing `zone` field.
  Future<String> fetchZone(String zip) async {
    final response = await _http.get(
      Uri.parse('https://phzmapi.org/$zip.json'),
    );
    if (response.statusCode != 200) {
      throw NetworkException(
        'phzmapi request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    final zone = (jsonDecode(response.body) as Map<String, dynamic>)['zone'];
    if (zone is! String || zone.isEmpty) {
      throw const FormatException('phzmapi response has no zone');
    }
    return zone;
  }
}
