import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guide_repository_provider.dart';
import '../domain/guide.dart';
import '../domain/guide_feed_query.dart';

/// Pages loaded so far for one [GuideFeedQuery].
class GuideFeedState {
  const GuideFeedState({
    required this.guides,
    required this.fetched,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Guide> guides;

  /// Rows requested from the server so far: the offset of the next page.
  /// Can exceed `guides.length` when a row shifted between pages.
  final int fetched;

  /// False once a page came back short.
  final bool hasMore;
  final bool loadingMore;

  /// The last next-page failure; the loaded guides stay on screen.
  final Object? loadMoreError;

  GuideFeedState copyWith({
    List<Guide>? guides,
    int? fetched,
    bool? hasMore,
    bool? loadingMore,
    Object? loadMoreError,
  }) => GuideFeedState(
    guides: guides ?? this.guides,
    fetched: fetched ?? this.fetched,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError,
  );
}

/// The feed for one sort + filters (plan/09 § State management), loaded a
/// page at a time. Each [GuideFeedQuery] has its own state; one nobody
/// watches is disposed, so coming back to it starts again at page 1.
final communityFeedProvider = AsyncNotifierProvider.autoDispose
    .family<CommunityFeedNotifier, GuideFeedState, GuideFeedQuery>(
      CommunityFeedNotifier.new,
      // Riverpod retries a failed build by default; plan/09 § Errors says
      // no automatic retries, so the error state waits for the Retry button.
      retry: (_, _) => null,
    );

class CommunityFeedNotifier extends AsyncNotifier<GuideFeedState> {
  CommunityFeedNotifier(this.query);

  final GuideFeedQuery query;

  @override
  Future<GuideFeedState> build() async {
    final page = await ref
        .read(guideRepositoryProvider)
        .fetchFeed(query, offset: 0);
    return GuideFeedState(
      guides: page,
      fetched: page.length,
      hasMore: page.length == guideFeedPageSize,
    );
  }

  /// Fetches the next page and appends it, skipping guides already shown.
  /// Does nothing while loading, on the last page, or before the first page
  /// arrives. A failure keeps the list and sets
  /// [GuideFeedState.loadMoreError]; calling again retries.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    // A refresh rebuilds this notifier with a new ref, so a page requested
    // before it must not land on the new first page; neither may one that
    // lands after the feed was dropped.
    final requestRef = ref;
    try {
      final page = await ref
          .read(guideRepositoryProvider)
          .fetchFeed(query, offset: current.fetched);
      if (!requestRef.mounted) return;
      final seen = {for (final g in current.guides) g.id};
      state = AsyncData(
        GuideFeedState(
          guides: [
            ...current.guides,
            for (final g in page)
              if (seen.add(g.id)) g,
          ],
          fetched: current.fetched + page.length,
          hasMore: page.length == guideFeedPageSize,
        ),
      );
    } on Object catch (e) {
      if (!requestRef.mounted) return;
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: e));
    }
  }
}

/// The query behind Home's "Top guide this week": the Trending tab with no
/// filters (plan/07 § Feed and ranking).
const topGuideThisWeekQuery = GuideFeedQuery(sort: GuideSort.trending);

/// Home's "Top guide this week": the first row of the Trending query, or
/// null when there are no guides. Loading and error pass through.
final topGuideThisWeekProvider = Provider.autoDispose<AsyncValue<Guide?>>(
  (ref) => ref
      .watch(communityFeedProvider(topGuideThisWeekQuery))
      .whenData((feed) => feed.guides.firstOrNull),
);
