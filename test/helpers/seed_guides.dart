import 'dart:convert';
import 'dart:io';

import 'package:geaux_farm/features/community/domain/guide.dart';

/// A guide row of `supabase/seed.sql`, parsed the way `guide_feed` would
/// return it. Each seed value carries a `-- label` comment, so no SQL parser
/// is needed (see `seed_sql_test.dart`).
Guide seedGuide(String title) {
  final sql = File('supabase/seed.sql').readAsStringSync();
  final block =
      RegExp(
            r'insert into public\.guides \(.*?\) on conflict \(id\) do nothing;',
            dotAll: true,
          )
          .allMatches(sql)
          .map((m) => m.group(0)!)
          .firstWhere(
            (b) => b.contains("'$title', -- title"),
            orElse: () => throw StateError('No seed guide titled "$title"'),
          );

  String text(String label) {
    final m = RegExp(
      "^\\s*'((?:[^']|'')*)',\\s*-- $label\\s*\$",
      multiLine: true,
    ).firstMatch(block);
    return m!.group(1)!.replaceAll("''", "'");
  }

  int? number(String label) {
    final m = RegExp(
      '^\\s*(\\d+|null),\\s*-- $label\\s*\$',
      multiLine: true,
    ).firstMatch(block);
    return int.tryParse(m!.group(1)!);
  }

  List<String> array(String label) {
    final inner = text(label).replaceAll(RegExp(r'^\{|\}$'), '');
    return inner.isEmpty ? const [] : inner.split(',');
  }

  List<Map<String, dynamic>> json(String label) {
    final m = RegExp(
      "'((?:[^']|'')*)'::jsonb,\\s*-- $label\\s*\$",
      multiLine: true,
    ).firstMatch(block);
    final raw = m!.group(1)!.replaceAll("''", "'");
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  return Guide(
    id: text('id'),
    authorId: 'seed-author',
    authorUsername: 'geauxfarm',
    title: text('title'),
    summary: text('summary'),
    difficulty: number('difficulty')!,
    spaceTypes: array('space_types'),
    estCostUsd: number('est_cost_usd'),
    setupMinutes: number('setup_minutes'),
    materials: [
      for (final m in json('materials'))
        GuideMaterial(
          name: m['name'] as String,
          qty: m['qty'] as String,
          estCostUsd: m['estCostUsd'] as int?,
          url: m['url'] as String?,
        ),
    ],
    steps: [
      for (final s in json('steps'))
        GuideStep(title: s['title'] as String, body: s['body'] as String),
    ],
    plantIds: array('plant_ids'),
    tags: array('tags'),
    starCount: 0,
    growCount: 0,
    remixCount: 0,
    stars7d: 0,
  );
}
