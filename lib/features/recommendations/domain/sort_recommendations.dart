import 'scored_plant.dart';

/// plan/04 § Sorting: scorable plants only, ordered by inSeason (true
/// first), score (high first), difficulty (easy first), then commonName
/// (A–Z). Returns a new list.
List<ScoredPlant> sortRecommendations(List<ScoredPlant> items) =>
    items.where((s) => s.plant.scorable).toList()..sort(_compare);

int _compare(ScoredPlant a, ScoredPlant b) {
  final ca = a.compatibility, cb = b.compatibility;
  if (ca.inSeason != cb.inSeason) return ca.inSeason ? -1 : 1;
  final byScore = cb.score.compareTo(ca.score);
  if (byScore != 0) return byScore;
  final byDifficulty = a.plant.difficulty.compareTo(b.plant.difficulty);
  if (byDifficulty != 0) return byDifficulty;
  return a.plant.commonName.compareTo(b.plant.commonName);
}
