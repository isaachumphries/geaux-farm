import 'compatibility.dart';

/// Score band (plan/04 § Labels): ≥ 80 great, 60–79 good, 40–59 possible,
/// below 40 indoor ("Tough here").
CompatLevel compatLevelFor(int score) {
  if (score >= 80) return CompatLevel.great;
  if (score >= 60) return CompatLevel.good;
  if (score >= 40) return CompatLevel.possible;
  return CompatLevel.indoor;
}
