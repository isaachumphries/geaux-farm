/// Great-circle distance between two points, in statute miles (plan/08
/// § Markets). Pure: no clock, no network, no Flutter.
library;

import 'dart:math' as math;

/// Mean Earth radius in statute miles (6371.0088 km).
const double earthRadiusMiles = 3958.7613;

/// Haversine distance from ([lat1], [lon1]) to ([lat2], [lon2]) in miles.
/// A point to itself is exactly 0.
double distanceMiles(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _radians(lat1);
  final phi2 = _radians(lat2);
  final dPhi = _radians(lat2 - lat1);
  final dLambda = _radians(lon2 - lon1);
  final h =
      math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(dLambda / 2) *
          math.sin(dLambda / 2);
  return 2 * earthRadiusMiles * math.asin(math.sqrt(h));
}

double _radians(double degrees) => degrees * math.pi / 180;
