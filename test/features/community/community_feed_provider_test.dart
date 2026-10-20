import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/application/community_feed_provider.dart';
import 'package:geaux_farm/features/community/application/starred_guides_provider.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';

import '../../helpers/community_fixtures.dart';

/// [total] guides `g0`..; a page is `pageSize` of them from the offset.
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

/// Keeps [query]'s provider alive (it is autoDispose) and waits for page 1.
Future<GuideFeedState> _open(ProviderContainer c, GuideFeedQuery query) async {
  c.listen(communityFeedProvider(query), (_, _) {});
  return c.read(communityFeedProvider(query).future);
}

void main() {
  group('paging', () {
    test('page 1 loads 20 guides and offers more', () async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      final c = _container(repo);

      final state = await _open(c, const GuideFeedQuery());

      expect(state.guides.map((g) => g.id), [
        for (var i = 0; i < 20; i++) 'g$i',
      ]);
      expect(state.hasMore, isTrue);
      expect(repo.fetches.single.$2, 0);
    });

    test('loadMore appends the next pages until one is short', () async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      final c = _container(repo);
      const query = GuideFeedQuery();
      await _open(c, query);
      final notifier = c.read(communityFeedProvider(query).notifier);

      await notifier.loadMore();
      var state = c.read(communityFeedProvider(query)).requireValue;
      expect(state.guides.length, 40);
      expect(state.hasMore, isTrue);

      await notifier.loadMore();
      state = c.read(communityFeedProvider(query)).requireValue;
      expect(state.guides.map((g) => g.id), [
        for (var i = 0; i < 45; i++) 'g$i',
      ]);
      expect(state.hasMore, isFalse);
      expect(repo.fetches.map((f) => f.$2), [0, 20, 40]);
    });

    test('after the last page loadMore fetches nothing', () async {
      final repo = FakeGuideRepository(pages: _catalog(5));
      final c = _container(repo);
      const query = GuideFeedQuery();
      final state = await _open(c, query);
      expect(state.hasMore, isFalse);

      await c.read(communityFeedProvider(query).notifier).loadMore();

      expect(repo.fetches, hasLength(1));
    });

    test(
      'exactly 20 guides: a second page is tried and comes back empty',
      () async {
        final repo = FakeGuideRepository(pages: _catalog(20));
        final c = _container(repo);
        const query = GuideFeedQuery();
        await _open(c, query);

        await c.read(communityFeedProvider(query).notifier).loadMore();

        final state = c.read(communityFeedProvider(query)).requireValue;
        expect(state.guides, hasLength(20));
        expect(state.hasMore, isFalse);
      },
    );

    test('rows that shifted between pages are not repeated', () async {
      // A guide published meanwhile pushes g19 onto page 2 as well.
      final repo = FakeGuideRepository(
        pages: (query, offset) => offset == 0
            ? [for (var i = 0; i < 20; i++) testGuide('g$i')]
            : [for (var i = 19; i < 29; i++) testGuide('g$i')],
      );
      final c = _container(repo);
      const query = GuideFeedQuery();
      await _open(c, query);

      await c.read(communityFeedProvider(query).notifier).loadMore();

      final state = c.read(communityFeedProvider(query)).requireValue;
      final ids = state.guides.map((g) => g.id).toList();
      expect(ids, [for (var i = 0; i < 29; i++) 'g$i']);
      expect(ids.toSet(), hasLength(ids.length));
      expect(state.hasMore, isFalse);
    });

    test('overlapping loadMore calls fetch the page once', () async {
      final repo = FakeGuideRepository(pages: _catalog(60));
      final c = _container(repo);
      const query = GuideFeedQuery();
      await _open(c, query);
      final notifier = c.read(communityFeedProvider(query).notifier);

      await Future.wait([notifier.loadMore(), notifier.loadMore()]);

      expect(repo.fetches.map((f) => f.$2), [0, 20]);
    });

    test('a failed next page keeps the list; calling again retries', () async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      final c = _container(repo);
      const query = GuideFeedQuery();
      await _open(c, query);
      final notifier = c.read(communityFeedProvider(query).notifier);

      repo.failFetch = true;
      await notifier.loadMore();
      var state = c.read(communityFeedProvider(query)).requireValue;
      expect(state.guides, hasLength(20));
      expect(state.loadMoreError, isNotNull);
      expect(state.loadingMore, isFalse);
      expect(state.hasMore, isTrue);

      repo.failFetch = false;
      await notifier.loadMore();
      state = c.read(communityFeedProvider(query)).requireValue;
      expect(state.guides, hasLength(40));
      expect(state.loadMoreError, isNull);
    });

    test('a failed first page is an error state', () async {
      final repo = FakeGuideRepository(failFetch: true);
      final c = _container(repo);
      const query = GuideFeedQuery();
      c.listen(communityFeedProvider(query), (_, _) {});

      await expectLater(
        c.read(communityFeedProvider(query).future),
        throwsException,
      );
      expect(c.read(communityFeedProvider(query)).hasError, isTrue);

      // Riverpod's own retry would refetch after 200 ms; plan/09 says none.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(repo.fetches, hasLength(1));
    });

    test('a page that lands after the feed was dropped is ignored', () async {
      final gate = Completer<List<Guide>>();
      final repo = _GatedRepository(gate);
      final c = _container(repo);
      const query = GuideFeedQuery();
      final sub = c.listen(communityFeedProvider(query), (_, _) {});
      await c.read(communityFeedProvider(query).future);
      final loading = c.read(communityFeedProvider(query).notifier).loadMore();

      sub.close();
      await Future<void>.delayed(Duration.zero);
      gate.complete([testGuide('late')]);

      await expectLater(loading, completes);
    });
  });

  group('keys', () {
    test('changing the sort starts again at page 1', () async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      final c = _container(repo);
      const top = GuideFeedQuery();
      await _open(c, top);
      await c.read(communityFeedProvider(top).notifier).loadMore();

      final trending = top.withSort(GuideSort.trending);
      final state = await _open(c, trending);

      expect(state.guides, hasLength(20));
      expect(repo.fetches.last, (trending, 0));
    });

    test('changing a filter starts again at page 1', () async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      final c = _container(repo);
      const all = GuideFeedQuery();
      await _open(c, all);
      await c.read(communityFeedProvider(all).notifier).loadMore();

      for (final next in [
        all.copyWith(spaceTypes: ['balcony']),
        all.withDifficulty(1),
        all.copyWith(tags: ['budget']),
        all.copyWith(search: 'kale'),
      ]) {
        final state = await _open(c, next);
        expect(state.guides, hasLength(20), reason: '$next');
        expect(repo.fetches.last, (next, 0), reason: '$next');
      }
    });

    test('a feed nobody watches is dropped: coming back restarts it', () async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      final c = _container(repo);
      const query = GuideFeedQuery();
      final sub = c.listen(communityFeedProvider(query), (_, _) {});
      await c.read(communityFeedProvider(query).future);
      await c.read(communityFeedProvider(query).notifier).loadMore();
      expect(
        c.read(communityFeedProvider(query)).requireValue.guides,
        hasLength(40),
      );

      sub.close();
      await Future<void>.delayed(Duration.zero);
      final state = await _open(c, query);

      expect(state.guides, hasLength(20));
      expect(repo.fetches.map((f) => f.$2), [0, 20, 0]);
    });
  });

  group('starred by me', () {
    test('is fetched once and cached', () async {
      final repo = FakeGuideRepository(starred: {'g1', 'g2'});
      final c = _container(repo);

      expect(await c.read(starredGuideIdsProvider.future), {'g1', 'g2'});
      expect(await c.read(starredGuideIdsProvider.future), {'g1', 'g2'});
      c.read(starredGuideIdsProvider);

      expect(repo.starredFetches, 1);
    });

    test('invalidate fetches it again', () async {
      final repo = FakeGuideRepository(starred: {'g1'});
      final c = _container(repo);
      await c.read(starredGuideIdsProvider.future);

      c.invalidate(starredGuideIdsProvider);
      await c.read(starredGuideIdsProvider.future);

      expect(repo.starredFetches, 2);
    });

    test('is not fetched by loading the feed', () async {
      final repo = FakeGuideRepository(pages: _catalog(5));
      final c = _container(repo);

      await _open(c, const GuideFeedQuery());

      expect(repo.starredFetches, 0);
    });
  });

  group('top guide this week', () {
    test('is the first row of the unfiltered Trending query', () async {
      final repo = FakeGuideRepository(
        pages: (query, offset) => [
          testGuide(query.sort == GuideSort.trending ? 'hot' : 'other'),
          testGuide('second'),
        ],
      );
      final c = _container(repo);
      c.listen(topGuideThisWeekProvider, (_, _) {});
      await c.read(communityFeedProvider(topGuideThisWeekQuery).future);

      expect(c.read(topGuideThisWeekProvider).requireValue?.id, 'hot');
      expect(repo.fetches.single, (
        const GuideFeedQuery(sort: GuideSort.trending),
        0,
      ));
    });

    test('is null when there are no guides', () async {
      final repo = FakeGuideRepository();
      final c = _container(repo);
      c.listen(topGuideThisWeekProvider, (_, _) {});
      await c.read(communityFeedProvider(topGuideThisWeekQuery).future);

      expect(c.read(topGuideThisWeekProvider).requireValue, isNull);
    });
  });
}

/// Page 1 is immediate; any other page waits on [gate].
class _GatedRepository extends FakeGuideRepository {
  _GatedRepository(this.gate);

  final Completer<List<Guide>> gate;

  @override
  Future<List<Guide>> fetchFeed(GuideFeedQuery query, {int offset = 0}) =>
      offset == 0
      ? Future.value([
          for (var i = 0; i < guideFeedPageSize; i++) testGuide('g$i'),
        ])
      : gate.future;
}
