import '../../catalog/domain/plant.dart';
import 'scored_plant.dart';

/// Filter chips on the recommendation list (plan/04 § Filters).
enum RecommendationChip {
  all,
  food,
  herbs,
  flowers,
  shrubs,
  indoor,
  lowMaintenance,
}

/// Keeps items matching [chip] AND [query]. The query is a case-insensitive
/// substring of the common or scientific name; empty matches everything.
List<ScoredPlant> applyRecommendationFilter(
  List<ScoredPlant> items,
  RecommendationChip chip,
  String query,
) {
  final q = query.trim().toLowerCase();
  return items.where((s) {
    final p = s.plant;
    return _matchesChip(p, chip) &&
        (q.isEmpty ||
            p.commonName.toLowerCase().contains(q) ||
            p.scientificName.toLowerCase().contains(q));
  }).toList();
}

bool _matchesChip(Plant p, RecommendationChip chip) => switch (chip) {
  RecommendationChip.all => true,
  RecommendationChip.food => p.purposes.contains(PlantPurpose.food),
  RecommendationChip.herbs => p.category == PlantCategory.herb,
  RecommendationChip.flowers => p.category == PlantCategory.flower,
  RecommendationChip.shrubs => p.category == PlantCategory.shrub,
  RecommendationChip.indoor => p.space?.indoorOk ?? false,
  RecommendationChip.lowMaintenance =>
    p.maintenanceLevel == MaintenanceLevel.low,
};
