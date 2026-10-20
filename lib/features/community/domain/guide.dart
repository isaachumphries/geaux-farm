/// One row of `materials` (plan/07 § Guide content shape).
class GuideMaterial {
  const GuideMaterial({
    required this.name,
    required this.qty,
    this.estCostUsd,
    this.url,
  });

  final String name;

  /// Free text such as "4" or "2 bags".
  final String qty;
  final int? estCostUsd;
  final String? url;
}

/// One row of `steps` (plan/07 § Guide content shape).
class GuideStep {
  const GuideStep({required this.title, required this.body, this.imagePath});

  final String title;
  final String body;
  final String? imagePath;
}

/// A published guide: a `guide_feed` row (plan/07 § Supabase schema).
///
/// Counters are maintained by triggers; the client never writes them.
class Guide {
  const Guide({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorDisplayName,
    required this.title,
    required this.summary,
    this.coverPath,
    required this.difficulty,
    required this.spaceTypes,
    this.estCostUsd,
    this.setupMinutes,
    this.materials = const [],
    this.steps = const [],
    this.plantIds = const [],
    this.tags = const [],
    this.forkedFrom,
    required this.starCount,
    required this.growCount,
    required this.remixCount,
    required this.stars7d,
    this.publishedAt,
  });

  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorDisplayName;
  final String title;
  final String summary;

  /// Path in the `guide-images` bucket; null when the guide has no cover.
  final String? coverPath;

  /// 1 (easy) to 3 (hard).
  final int difficulty;

  /// `SpaceType` names.
  final List<String> spaceTypes;
  final int? estCostUsd;
  final int? setupMinutes;
  final List<GuideMaterial> materials;
  final List<GuideStep> steps;

  /// Catalog ids.
  final List<String> plantIds;
  final List<String> tags;
  final String? forkedFrom;
  final int starCount;
  final int growCount;
  final int remixCount;

  /// Stars received in the last 7 days (the Trending sort key).
  final int stars7d;
  final DateTime? publishedAt;
}
