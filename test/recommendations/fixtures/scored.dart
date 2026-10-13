// Synthetic ScoredPlants for widget tests, built from the kale record.
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/recommendations/domain/compat_level.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';

import 'baton_rouge.dart';

/// Kale with [changes] merged over the top-level JSON fields.
Plant kaleWith(Map<String, dynamic> changes) =>
    Plant.fromJson({...rawKale(), ...changes});

/// A [Plant] scored [score] with the given season and viability flags.
ScoredPlant scored(
  Plant plant, {
  int score = 100,
  bool inSeason = true,
  bool outdoorViable = true,
}) => ScoredPlant(
  plant,
  Compatibility(
    score: score,
    level: compatLevelFor(score),
    fits: const {},
    inSeason: inSeason,
    outdoorViable: outdoorViable,
    monthStrip: List.filled(12, inSeason),
  ),
);
