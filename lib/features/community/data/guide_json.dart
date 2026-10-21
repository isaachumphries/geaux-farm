import '../domain/guide.dart';
import '../domain/guide_validation.dart';

/// A `guide_feed` row as a [Guide]. Throws when a required column is
/// missing or mistyped.
Guide guideFromJson(Map<String, dynamic> row) {
  List<String> strings(String key) =>
      (row[key] as List<dynamic>? ?? const []).cast<String>();
  List<Map<String, dynamic>> maps(String key) =>
      (row[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  final publishedAt = row['published_at'] as String?;
  return Guide(
    id: row['id'] as String,
    authorId: row['author_id'] as String,
    authorUsername: row['author_username'] as String,
    authorDisplayName: row['author_display_name'] as String?,
    title: row['title'] as String,
    summary: row['summary'] as String,
    coverPath: row['cover_path'] as String?,
    difficulty: row['difficulty'] as int,
    spaceTypes: strings('space_types'),
    estCostUsd: row['est_cost_usd'] as int?,
    setupMinutes: row['setup_minutes'] as int?,
    materials: [
      for (final m in maps('materials'))
        GuideMaterial(
          name: m['name'] as String,
          qty: m['qty'] as String,
          estCostUsd: m['estCostUsd'] as int?,
          url: m['url'] as String?,
        ),
    ],
    steps: [
      for (final s in maps('steps'))
        GuideStep(
          title: s['title'] as String,
          body: s['body'] as String,
          imagePath: s['imagePath'] as String?,
        ),
    ],
    plantIds: strings('plant_ids'),
    tags: strings('tags'),
    forkedFrom: row['forked_from'] as String?,
    starCount: row['star_count'] as int,
    growCount: row['grow_count'] as int,
    remixCount: row['remix_count'] as int,
    stars7d: row['stars_7d'] as int,
    publishedAt: publishedAt == null ? null : DateTime.parse(publishedAt),
  );
}

/// The `guides` columns for [draft] at [status], as PostgREST takes them
/// (plan/07 § Editor).
///
/// [authorId] is set on an insert only; `guides_insert` checks it against
/// `auth.uid()`. The counters (`star_count`, `grow_count`, `remix_count`,
/// `report_count`) are maintained by triggers and never appear here.
Map<String, Object?> guideDraftPayload(
  GuideDraft draft, {
  required String status,
  String? authorId,
}) => {
  'author_id': ?authorId,
  'title': draft.title.trim(),
  // The column is `not null`; a draft with no summary stores ''.
  'summary': draft.summary.trim(),
  'cover_path': draft.coverPath,
  'difficulty': draft.difficulty,
  'space_types': draft.spaceTypes,
  'est_cost_usd': draft.estCostUsd,
  'setup_minutes': draft.setupMinutes,
  'materials': [
    for (final m in draft.materials)
      {'name': m.name, 'qty': m.qty, 'estCostUsd': m.estCostUsd, 'url': m.url},
  ],
  'steps': [
    for (final s in draft.steps)
      {'title': s.title, 'body': s.body, 'imagePath': s.imagePath},
  ],
  'plant_ids': draft.plantIds,
  'tags': draft.tags,
  'status': status,
};
