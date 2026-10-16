/// A place from city search or the GPS fix (OB-02).
class GeoPlace {
  const GeoPlace({
    required this.name,
    required this.admin1,
    required this.countryCode,
    required this.lat,
    required this.lon,
    this.postcode,
    this.timezone,
  });

  final String name;
  final String admin1;
  final String countryCode;
  final double lat;
  final double lon;
  final String? postcode;
  final String? timezone;

  /// A result row: `{name}, {admin1}, {country_code}` (plan/02 § OB-02).
  /// Empty parts are skipped.
  String get label =>
      [name, admin1, countryCode].where((p) => p.isNotEmpty).join(', ');
}

/// Rounds a coordinate to 2 decimals (about 1 km) before it is stored, for
/// privacy (plan/02 § OB-02).
double roundCoordinate(double value) => (value * 100).round() / 100;

/// City search and reverse lookup. Faked in tests; no live calls there.
abstract interface class GeocodingRepository {
  /// Up to 8 places matching [query].
  Future<List<GeoPlace>> search(String query);
}

/// Why the GPS path could not produce a place.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'LocationUnavailableException: $message';
}

/// The GPS path: permission, a coarse fix, reverse geocoding, and the
/// device timezone. Throws [LocationUnavailableException] when permission
/// is denied or the fix fails.
abstract interface class DeviceLocator {
  Future<GeoPlace> locate();
}
