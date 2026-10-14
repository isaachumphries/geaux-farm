/// Where a planting grows. Lists default to indoor for windowsills and
/// outdoor otherwise (plan/04).
enum GrowSetup { outdoor, indoor, greenhouse }

/// Lifecycle of a planting in My Garden.
enum PlantingStatus { planned, active, harvested, removed }

/// A plant the user is growing (Drift `plantings`).
class Planting {
  const Planting({
    required this.id,
    required this.plantId,
    required this.spaceId,
    required this.nickname,
    required this.setup,
    required this.inContainer,
    required this.startMethod,
    this.plantedOn,
    required this.status,
    this.projectId,
    required this.createdAt,
  });

  final String id;

  /// Catalog id from `plants.json`.
  final String plantId;
  final String spaceId;
  final String nickname;
  final GrowSetup setup;
  final bool inContainer;

  /// `seed`, `transplant`, or `cutting` (plan/03 `starts.method`).
  final String startMethod;
  final DateTime? plantedOn;
  final PlantingStatus status;
  final String? projectId;
  final DateTime createdAt;
}
