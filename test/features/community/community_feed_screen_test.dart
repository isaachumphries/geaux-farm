import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';
import 'package:geaux_farm/features/community/presentation/community_feed_screen.dart';
import 'package:geaux_farm/features/community/presentation/widgets/guide_card.dart';
import 'package:geaux_farm/features/community/presentation/widgets/guide_card_skeleton.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/community_fixtures.dart';

List<Guide> Function(GuideFeedQuery, int) _catalog(int total) =>
    (query, offset) => [
      for (var i = offset; i < total && i < offset + guideFeedPageSize; i++)
        testGuide('g$i', title: 'Guide number $i'),
    ];

/// Pumps the feed at 360x800 inside a router with stub guide routes and
/// returns the router.
Future<GoRouter> _pump(WidgetTester tester, FakeGuideRepository repo) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const CommunityFeedScreen(),
        routes: [
          GoRoute(
            path: 'community/guide/:id',
            builder: (_, state) => Text('detail ${state.pathParameters['id']}'),
          ),
          GoRoute(path: 'community/me', builder: (_, _) => const Text('me')),
          GoRoute(
            path: 'community/editor/:id',
            builder: (_, state) => Text('editor ${state.pathParameters['id']}'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [guideRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
  return router;
}

/// Taps the chip labelled [text], scrolling the chip row to it first.
Future<void> _tapChip(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pump();
}

/// [text] inside the open filter sheet (the cards behind it say "Easy" too).
Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

GuideFeedQuery _lastQuery(FakeGuideRepository repo) => repo.fetches.last.$1;

void main() {
  group('states', () {
    testWidgets('loading: a skeleton list until the first page arrives', (
      tester,
    ) async {
      final gate = Completer<List<Guide>>();
      final repo = _GatedRepository(gate);
      await _pump(tester, repo);

      expect(find.byType(GuideCardSkeletonList), findsOneWidget);
      expect(find.byType(GuideCard), findsNothing);

      gate.complete([testGuide('g1')]);
      await tester.pump();
      await tester.pump();

      expect(find.byType(GuideCardSkeletonList), findsNothing);
      expect(find.byType(GuideCard), findsOneWidget);
    });

    testWidgets('default: cards show title, author, counts, cost, level', (
      tester,
    ) async {
      final repo = FakeGuideRepository(
        pages: (_, _) => [
          testGuide(
            'g1',
            title: 'Balcony salsa garden in 4 pots',
            stars: 128,
            grows: 42,
            remixes: 9,
            cost: 35,
          ),
          testGuide('g2', title: 'Windowsill herbs', difficulty: 3, cost: null),
        ],
      );
      await _pump(tester, repo);

      expect(find.text('Balcony salsa garden in 4 pots'), findsOneWidget);
      expect(find.text('@geauxfarm'), findsNWidgets(2));
      expect(find.text('128'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text(r'$35'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      // A guide with no cost shows no price; difficulty 3 reads Hard.
      expect(find.text('Hard'), findsOneWidget);
      expect(find.textContaining(r'$'), findsOneWidget);
    });

    testWidgets('empty: "No guides yet." with no Retry', (tester) async {
      await _pump(tester, FakeGuideRepository());

      expect(find.text('No guides yet.'), findsOneWidget);
      expect(find.text('RETRY'), findsNothing);
    });

    testWidgets('empty under a filter reads "No guides match."', (
      tester,
    ) async {
      await _pump(tester, FakeGuideRepository());

      await _tapChip(tester, 'Balcony');
      await tester.pump();

      expect(find.text('No guides match.'), findsOneWidget);
      expect(find.text('No guides yet.'), findsNothing);
    });

    testWidgets('error: message with Retry that re-runs the query', (
      tester,
    ) async {
      final repo = FakeGuideRepository(
        pages: (_, _) => [testGuide('g1')],
        failFetch: true,
      );
      await _pump(tester, repo);

      expect(find.text("Couldn't load guides."), findsOneWidget);
      expect(find.byType(GuideCard), findsNothing);
      expect(repo.fetches, hasLength(1));

      repo.failFetch = false;
      await tester.tap(find.text('RETRY'));
      await tester.pump();
      await tester.pump();

      expect(repo.fetches, hasLength(2));
      expect(repo.fetches.last.$1, repo.fetches.first.$1);
      expect(repo.fetches.last.$2, 0);
      expect(find.text("Couldn't load guides."), findsNothing);
      expect(find.byType(GuideCard), findsOneWidget);
    });

    testWidgets('Retry re-runs the current filtered query, not the default', (
      tester,
    ) async {
      final repo = FakeGuideRepository(failFetch: true);
      await _pump(tester, repo);
      await tester.tap(find.text('Trending'));
      await tester.pump();
      await tester.pump();
      await _tapChip(tester, 'Balcony');
      await tester.pump();
      expect(find.text("Couldn't load guides."), findsOneWidget);

      await tester.tap(find.text('RETRY'));
      await tester.pump();
      await tester.pump();

      expect(
        _lastQuery(repo),
        const GuideFeedQuery(sort: GuideSort.trending, spaceTypes: ['balcony']),
      );
    });
  });

  group('tabs', () {
    testWidgets('Top is selected first; Trending and New re-query', (
      tester,
    ) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);
      expect(_lastQuery(repo).sort, GuideSort.top);

      await tester.tap(find.text('Trending'));
      await tester.pump();
      await tester.pump();
      expect(_lastQuery(repo).sort, GuideSort.trending);
      expect(repo.fetches.last.$2, 0);

      await tester.tap(find.text('New'));
      await tester.pump();
      await tester.pump();
      expect(_lastQuery(repo).sort, GuideSort.newest);

      await tester.tap(find.text('Top'));
      await tester.pump();
      await tester.pump();
      expect(_lastQuery(repo).sort, GuideSort.top);
    });

    testWidgets('switching tabs keeps the filters', (tester) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);
      await _tapChip(tester, 'Balcony');

      await tester.tap(find.text('New'));
      await tester.pump();
      await tester.pump();

      expect(
        _lastQuery(repo),
        const GuideFeedQuery(sort: GuideSort.newest, spaceTypes: ['balcony']),
      );
    });
  });

  group('filters', () {
    testWidgets('space type chips select one at a time; All clears', (
      tester,
    ) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);

      await _tapChip(tester, 'Balcony');
      expect(_lastQuery(repo).spaceTypes, ['balcony']);

      await _tapChip(tester, 'Windowsill');
      expect(_lastQuery(repo).spaceTypes, ['windowsill']);

      await _tapChip(tester, 'Small yard');
      expect(_lastQuery(repo).spaceTypes, ['smallYard']);

      await _tapChip(tester, 'All');
      expect(_lastQuery(repo).spaceTypes, isEmpty);
    });

    testWidgets('tapping the selected space chip clears it', (tester) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);

      await _tapChip(tester, 'Balcony');
      await _tapChip(tester, 'Balcony');

      expect(_lastQuery(repo).spaceTypes, isEmpty);
    });

    testWidgets('the sheet sets difficulty and tags; Clear resets them', (
      tester,
    ) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Easy'));
      await tester.tap(_inSheet('Kids'));
      await tester.tap(_inSheet('Budget'));
      await tester.tap(_inSheet('APPLY'));
      await tester.pumpAndSettle();

      // Tags come in the fixed-list order whatever the tap order.
      expect(_lastQuery(repo).difficulty, 1);
      expect(_lastQuery(repo).tags, ['budget', 'kids']);
      expect(find.text('Filters · 3'), findsOneWidget);

      await tester.tap(find.text('Filters · 3'));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('CLEAR'));
      await tester.tap(_inSheet('APPLY'));
      await tester.pumpAndSettle();

      expect(_lastQuery(repo).difficulty, isNull);
      expect(_lastQuery(repo).tags, isEmpty);
      expect(find.text('Filters'), findsOneWidget);
    });

    testWidgets('dismissing the sheet changes nothing', (tester) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Hard'));
      await tester.tapAt(const Offset(180, 20));
      await tester.pumpAndSettle();

      expect(repo.fetches, hasLength(1));
      expect(find.text('Filters'), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('typing searches after a pause; closing clears it', (
      tester,
    ) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.bySemanticsLabel('Search guides'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'lettuce');
      await tester.pump(searchDebounce - const Duration(milliseconds: 50));
      expect(repo.fetches, hasLength(1));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(_lastQuery(repo).search, 'lettuce');

      await tester.tap(find.bySemanticsLabel('Close search'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      expect(_lastQuery(repo).search, isEmpty);
    });

    testWidgets('keystrokes inside the pause make one query', (tester) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);
      await tester.tap(find.bySemanticsLabel('Search guides'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'let');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'lettuce');
      await tester.pump(searchDebounce);
      await tester.pump();

      expect(repo.fetches.map((f) => f.$1.search), ['', 'lettuce']);
    });

    testWidgets('search keeps the tab and filters', (tester) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);
      await tester.tap(find.text('Trending'));
      await tester.pump();
      await _tapChip(tester, 'Balcony');

      await tester.tap(find.bySemanticsLabel('Search guides'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'kale');
      await tester.pump(searchDebounce);
      await tester.pump();

      expect(
        _lastQuery(repo),
        const GuideFeedQuery(
          sort: GuideSort.trending,
          spaceTypes: ['balcony'],
          search: 'kale',
        ),
      );
    });
  });

  group('paging', () {
    testWidgets('scrolling to the bottom loads the next page of 20', (
      tester,
    ) async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      await _pump(tester, repo);
      expect(repo.fetches.map((f) => f.$2), [0]);

      Future<void> scrollToEnd() async {
        await tester.drag(
          find.byType(Scrollable).last,
          const Offset(0, -20000),
        );
        await tester.pump();
        await tester.pump();
      }

      await scrollToEnd();
      expect(repo.fetches.map((f) => f.$2), [0, 20]);
      await scrollToEnd();
      expect(repo.fetches.map((f) => f.$2), [0, 20, 40]);

      // All 45 are there once, and the last page ends the list.
      await scrollToEnd();
      expect(repo.fetches.map((f) => f.$2), [0, 20, 40]);
      expect(find.text('Guide number 44'), findsOneWidget);
      expect(find.text('Guide number 0'), findsNothing); // scrolled off
    });

    testWidgets('a failed next page shows Retry under the list', (
      tester,
    ) async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      await _pump(tester, repo);

      repo.failFetch = true;
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -20000));
      // Let the overscrolled list settle back onto its last row.
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load more guides."), findsOneWidget);
      expect(find.text('Guide number 19'), findsOneWidget);

      repo.failFetch = false;
      await tester.tap(find.text('RETRY'));
      await tester.pump();
      await tester.pump();

      expect(find.text("Couldn't load more guides."), findsNothing);
      expect(repo.fetches.map((f) => f.$2), [0, 20, 20]);
    });

    testWidgets('a new tab goes back to the top of page 1', (tester) async {
      final repo = FakeGuideRepository(pages: _catalog(45));
      await _pump(tester, repo);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -20000));
      await tester.pump();
      await tester.pump();
      expect(find.text('Guide number 0'), findsNothing);

      await tester.tap(find.text('New'));
      await tester.pump();
      await tester.pump();

      expect(repo.fetches.last, (
        const GuideFeedQuery(sort: GuideSort.newest),
        0,
      ));
      expect(find.text('Guide number 0'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('a card opens its guide', (tester) async {
      final repo = FakeGuideRepository(pages: _catalog(3));
      await _pump(tester, repo);

      await tester.tap(find.text('Guide number 1'));
      await tester.pumpAndSettle();

      expect(find.text('detail g1'), findsOneWidget);
    });

    testWidgets('the profile button opens My profile', (tester) async {
      await _pump(tester, FakeGuideRepository());

      await tester.tap(find.bySemanticsLabel('My profile'));
      await tester.pumpAndSettle();

      expect(find.text('me'), findsOneWidget);
    });

    testWidgets('the plus button opens the editor for a new guide', (
      tester,
    ) async {
      await _pump(tester, FakeGuideRepository());

      await tester.tap(find.bySemanticsLabel('New guide'));
      await tester.pumpAndSettle();

      expect(find.text('editor new'), findsOneWidget);
    });
  });

  testWidgets('a cover path becomes the public cover URL', (tester) async {
    final repo = FakeGuideRepository(
      pages: (_, _) => [testGuide('g1', coverPath: 'u1/cover.jpg')],
    );
    await _pump(tester, repo);

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'http://supabase.test/u1/cover.jpg',
    );
  });
}

/// Every fetch waits on [gate].
class _GatedRepository extends FakeGuideRepository {
  _GatedRepository(this.gate);

  final Completer<List<Guide>> gate;

  @override
  Future<List<Guide>> fetchFeed(GuideFeedQuery query, {int offset = 0}) =>
      gate.future;
}
