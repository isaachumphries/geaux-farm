import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/application/community_feed_provider.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';

import '../helpers/community_fixtures.dart';

// plan/07 § Feed and ranking: pages of 20 via .range(), infinite scroll.
// Fills the boundaries test/features/community/community_feed_provider_test
// leaves open: an empty feed, a 19-row last page, a scroll before page 1,
// and later pages of a filtered feed.

/// [total] guides `g0`..; each call returns the 20 from the offset.
List<Guide> Function(GuideFeedQuery, int) _catalog(int total) =>
    (query, offset) => [
      for (var i = offset; i < total && i < offset + guideFeedPageSize; i++)
        testGuide('g$i'),
    ];

ProviderContainer _container(FakeGuideRepository repo) {
  final container = ProviderContainer(
    overrides: [guideRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Keeps [query]'s autoDispose feed alive and waits for page 1.
Future<GuideFeedState> _open(ProviderContainer c, GuideFeedQuery query) {
  c.listen(communityFeedProvider(query), (_, _) {});
  return c.read(communityFeedProvider(query).future);
}

void main() {
  test('an empty feed has no next page and never asks for one', () async {
    final repo = FakeGuideRepository(pages: _catalog(0));
    final c = _container(repo);
    const query = GuideFeedQuery();

    final state = await _open(c, query);
    await c.read(communityFeedProvider(query).notifier).loadMore();

    expect(state.guides, isEmpty);
    expect(state.hasMore, isFalse);
    expect(repo.fetches, [(query, 0)]);
  });

  test('a page of 19 is the last page; a page of 20 is not', () async {
    for (final (total, more) in [(19, false), (20, true), (39, false)]) {
      final repo = FakeGuideRepository(pages: _catalog(total));
      final c = _container(repo);
      const query = GuideFeedQuery();
      await _open(c, query);
      final notifier = c.read(communityFeedProvider(query).notifier);
      if (total > guideFeedPageSize) await notifier.loadMore();

      final state = c.read(communityFeedProvider(query)).requireValue;
      expect(state.guides, hasLength(total), reason: '$total guides');
      expect(state.hasMore, more, reason: '$total guides');
    }
  });

  test('scrolling before page 1 arrives fetches nothing extra', () async {
    final page1 = Completer<List<Guide>>();
    final repo = _FirstPageGate(page1, _catalog(45));
    final c = _container(repo);
    const query = GuideFeedQuery();
    c.listen(communityFeedProvider(query), (_, _) {});
    await Future<void>.delayed(Duration.zero);

    await c.read(communityFeedProvider(query).notifier).loadMore();
    page1.complete(_catalog(45)(query, 0));
    final state = await c.read(communityFeedProvider(query).future);

    expect(repo.fetches, [(query, 0)]);
    expect(state.guides, hasLength(20));
    expect(state.fetched, 20);
  });

  test('later pages of a filtered, sorted feed keep its filters', () async {
    final repo = FakeGuideRepository(pages: _catalog(45));
    final c = _container(repo);
    const query = GuideFeedQuery(
      sort: GuideSort.trending,
      spaceTypes: ['balcony'],
      difficulty: 1,
      tags: ['budget'],
      search: 'lettuce',
    );
    await _open(c, query);
    final notifier = c.read(communityFeedProvider(query).notifier);

    await notifier.loadMore();
    await notifier.loadMore();

    expect(repo.fetches, [(query, 0), (query, 20), (query, 40)]);
  });
}

/// Page 1 waits on [gate]; later pages answer at once.
class _FirstPageGate extends FakeGuideRepository {
  _FirstPageGate(this.gate, List<Guide> Function(GuideFeedQuery, int) pages)
    : super(pages: pages);

  final Completer<List<Guide>> gate;

  @override
  Future<List<Guide>> fetchFeed(GuideFeedQuery query, {int offset = 0}) {
    if (offset != 0) return super.fetchFeed(query, offset: offset);
    fetches.add((query, offset));
    return gate.future;
  }
}
