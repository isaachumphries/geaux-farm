/// A farmers market near the user (plan/08 § Markets). Plain Dart: the
/// data layer never hands HTTP or Supabase types to presentation.
class Market {
  const Market({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceMi,
    this.openingHours,
    this.website,
  });

  /// The OpenStreetMap element id, unique per element type.
  final String id;
  final String name;
  final double lat;
  final double lon;

  /// Haversine miles from the profile location.
  final double distanceMi;

  /// OSM `opening_hours`, verbatim; null when the element has none.
  final String? openingHours;
  final String? website;
}
