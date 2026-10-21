import 'package:flutter/foundation.dart';

/// Guides per feed page (plan/07 § Feed and ranking).
const guideFeedPageSize = 20;

/// The feed tabs. Removing Trending (cut candidate #5) means deleting its
/// entry here, its tab in `community_feed_screen.dart`, and its row in the
/// order map in `data/guide_feed_request.dart`.
enum GuideSort { top, trending, newest }

/// Sort and filters of one feed query; the key of `communityFeedProvider`.
///
/// Value equality, so equal queries share one provider instance.
@immutable
class GuideFeedQuery {
  const GuideFeedQuery({
    this.sort = GuideSort.top,
    this.spaceTypes = const [],
    this.difficulty,
    this.tags = const [],
    this.search = '',
  });

  final GuideSort sort;

  /// `SpaceType` names a guide must all list.
  final List<String> spaceTypes;

  /// 1 (easy) to 3 (hard); null for any.
  final int? difficulty;

  /// Tags a guide must all carry.
  final List<String> tags;

  /// Title text; blank means no search.
  final String search;

  /// The search text without surrounding whitespace.
  String get searchText => search.trim();

  /// True when any filter or search narrows the feed (the sort does not).
  bool get isFiltered =>
      spaceTypes.isNotEmpty ||
      difficulty != null ||
      tags.isNotEmpty ||
      searchText.isNotEmpty;

  /// Same filters and search under another sort.
  GuideFeedQuery withSort(GuideSort sort) => GuideFeedQuery(
    sort: sort,
    spaceTypes: spaceTypes,
    difficulty: difficulty,
    tags: tags,
    search: search,
  );

  GuideFeedQuery copyWith({
    List<String>? spaceTypes,
    List<String>? tags,
    String? search,
  }) => GuideFeedQuery(
    sort: sort,
    spaceTypes: spaceTypes ?? this.spaceTypes,
    difficulty: difficulty,
    tags: tags ?? this.tags,
    search: search ?? this.search,
  );

  /// Same query with [difficulty] set, or cleared when null.
  GuideFeedQuery withDifficulty(int? difficulty) => GuideFeedQuery(
    sort: sort,
    spaceTypes: spaceTypes,
    difficulty: difficulty,
    tags: tags,
    search: search,
  );

  @override
  bool operator ==(Object other) =>
      other is GuideFeedQuery &&
      other.sort == sort &&
      listEquals(other.spaceTypes, spaceTypes) &&
      other.difficulty == difficulty &&
      listEquals(other.tags, tags) &&
      other.search == search;

  @override
  int get hashCode => Object.hash(
    sort,
    Object.hashAll(spaceTypes),
    difficulty,
    Object.hashAll(tags),
    search,
  );

  @override
  String toString() =>
      'GuideFeedQuery($sort, spaceTypes: $spaceTypes, difficulty: $difficulty, '
      'tags: $tags, search: "$search")';
}
