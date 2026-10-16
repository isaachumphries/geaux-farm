/// A stored profile older than this is rebuilt (plan/04 § Climate profile
/// step 6). Exactly this old is still fresh.
const climateMaxAge = Duration(days: 365);

double _round2(double v) => (v * 100).round() / 100;

/// Whether the climate profile must be rebuilt, by the plan/04 rules in
/// order: nothing stored; the stored location differs from ([lat], [lon])
/// at 2 decimals; or [computedAt] is more than [climateMaxAge] before
/// [now].
bool needsClimateRebuild({
  required ({double lat, double lon})? stored,
  required DateTime? computedAt,
  required double lat,
  required double lon,
  required DateTime now,
}) {
  if (stored == null || computedAt == null) return true;
  if (_round2(stored.lat) != _round2(lat) ||
      _round2(stored.lon) != _round2(lon)) {
    return true;
  }
  return now.difference(computedAt) > climateMaxAge;
}
