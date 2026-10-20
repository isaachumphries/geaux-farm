import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/guide_feed_query.dart';

/// `(column, ascending)` pairs per tab (plan/07 § Feed and ranking). One
/// entry per [GuideSort], so a tab can be cut without touching the others.
const guideFeedOrder = <GuideSort, List<(String, bool)>>{
  GuideSort.top: [('star_count', false), ('published_at', false)],
  GuideSort.trending: [('stars_7d', false), ('star_count', false)],
  GuideSort.newest: [('published_at', false)],
};

/// Escapes `\`, `%` and `_` so typed text matches literally inside an
/// `ilike` pattern.
String _likeLiteral(String text) =>
    text.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');

/// The `guide_feed` request for one page: filters first, then the tab's
/// order, then rows `offset` to `offset + 19`.
PostgrestTransformBuilder<PostgrestList> buildGuideFeedRequest(
  SupabaseClient client,
  GuideFeedQuery query, {
  int offset = 0,
}) {
  var filtered = client.from('guide_feed').select();
  if (query.spaceTypes.isNotEmpty) {
    filtered = filtered.contains('space_types', query.spaceTypes);
  }
  final difficulty = query.difficulty;
  if (difficulty != null) filtered = filtered.eq('difficulty', difficulty);
  if (query.tags.isNotEmpty) {
    filtered = filtered.contains('tags', query.tags);
  }
  final text = query.searchText;
  if (text.isNotEmpty) {
    filtered = filtered.ilike('title', '%${_likeLiteral(text)}%');
  }

  PostgrestTransformBuilder<PostgrestList> ordered = filtered;
  for (final (column, ascending) in guideFeedOrder[query.sort]!) {
    ordered = ordered.order(column, ascending: ascending);
  }
  return ordered.range(offset, offset + guideFeedPageSize - 1);
}
