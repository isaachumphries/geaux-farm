import '../domain/guide.dart';

/// Longest `guides.title` the table allows (0001_init.sql).
const _maxTitleLength = 80;

const _titlePrefix = 'Remix of ';

/// The `guides` columns of a remix of [original]: a draft that points back
/// at it through `forked_from` (plan/07 § Remix).
///
/// The cover and every step image stay with the original. The counters
/// (`star_count`, `grow_count`, `remix_count`, `report_count`) are left to
/// the triggers, and `author_id` is added by the repository on insert.
Map<String, dynamic> buildRemixPayload(Guide original) => {
  'forked_from': original.id,
  'status': 'draft',
  'title': _remixTitle(original.title),
  'summary': original.summary,
  'difficulty': original.difficulty,
  'space_types': original.spaceTypes,
  'est_cost_usd': original.estCostUsd,
  'setup_minutes': original.setupMinutes,
  'materials': [
    for (final m in original.materials)
      {'name': m.name, 'qty': m.qty, 'estCostUsd': m.estCostUsd, 'url': m.url},
  ],
  'steps': [
    for (final s in original.steps)
      {'title': s.title, 'body': s.body, 'imagePath': null},
  ],
  'plant_ids': original.plantIds,
  'tags': original.tags,
  'cover_path': null,
};

/// "Remix of {title}", cut to 80 characters with the prefix counted.
/// Counted in code points, as Postgres `char_length` counts them.
String _remixTitle(String title) {
  final runes = '$_titlePrefix$title'.runes;
  if (runes.length <= _maxTitleLength) return '$_titlePrefix$title';
  return String.fromCharCodes(runes.take(_maxTitleLength));
}
