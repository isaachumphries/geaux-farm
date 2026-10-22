import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:geaux_farm/features/community/presentation/my_profile_screen.dart';
import 'package:go_router/go_router.dart';

import '../../community/fake_auth_repository.dart';
import '../../community/guide_detail_harness.dart' show settle, signedInUser;
import '../../helpers/community_fixtures.dart';

/// Pumps CM-05 at 360x800 on its route, over a feed page it returns to,
/// next to stub routes for the editor and guide detail.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeGuideRepository repo, {
  FakeAuthRepository? auth,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/community',
    routes: [
      GoRoute(
        path: '/community',
        builder: (_, _) => const Text('feed'),
        routes: [
          GoRoute(path: 'me', builder: (_, _) => const MyProfileScreen()),
          GoRoute(
            path: 'editor/:id',
            builder: (_, state) => Text('editor ${state.pathParameters['id']}'),
          ),
          GoRoute(
            path: 'guide/:id',
            builder: (_, state) => Text('guide ${state.pathParameters['id']}'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        guideRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(user: signedInUser),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  router.push('/community/me');
  await settle(tester);
  return router;
}

FakeGuideRepository _repo({
  List<OwnGuide> mine = const [],
  Set<String> starred = const {},
}) => FakeGuideRepository(
  mine: mine,
  starred: starred,
  guides: {
    's1': testGuide('s1', title: 'Starred tomato tower'),
    's2': testGuide('s2', title: 'Starred herb spiral'),
  },
);

OwnGuide _own(String id, GuideStatus status, {String? title}) =>
    (guide: testGuide(id, title: title ?? 'Guide $id'), status: status);

Future<void> _showStarred(WidgetTester tester) async {
  await tester.tap(find.text('Starred'));
  await settle(tester);
}

void main() {
  group('My guides', () {
    testWidgets('lists drafts, hidden and published guides in order', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          mine: [
            _own('d1', GuideStatus.draft, title: 'Draft raised bed'),
            _own('h1', GuideStatus.hidden, title: 'Hidden pallet planter'),
            _own('p1', GuideStatus.published, title: 'Published salsa pots'),
          ],
        ),
      );

      final draft = tester.getTopLeft(find.text('Draft raised bed')).dy;
      final hidden = tester.getTopLeft(find.text('Hidden pallet planter')).dy;
      expect(draft, lessThan(hidden));
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Hidden pending review'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Published salsa pots'), 200);
      expect(
        tester.getTopLeft(find.text('Published salsa pots')).dy,
        greaterThan(tester.getTopLeft(find.text('Hidden pallet planter')).dy),
      );
    });

    testWidgets('a draft opens the editor', (tester) async {
      final router = await _pump(
        tester,
        _repo(mine: [_own('d1', GuideStatus.draft)]),
      );

      await tester.tap(find.text('Guide d1'));
      await settle(tester);

      expect(router.state.uri.path, '/community/editor/d1');
      expect(find.text('editor d1'), findsOneWidget);
    });

    testWidgets('a published guide opens guide detail', (tester) async {
      final router = await _pump(
        tester,
        _repo(mine: [_own('p1', GuideStatus.published)]),
      );

      await tester.tap(find.text('Guide p1'));
      await settle(tester);

      expect(router.state.uri.path, '/community/guide/p1');
    });

    testWidgets('a hidden guide opens guide detail, not the editor', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _repo(mine: [_own('h1', GuideStatus.hidden)]),
      );

      await tester.tap(find.text('Guide h1'));
      await settle(tester);

      expect(router.state.uri.path, '/community/guide/h1');
    });

    testWidgets('coming back from the editor reloads the list', (tester) async {
      final repo = _repo(mine: [_own('d1', GuideStatus.draft)]);
      final router = await _pump(tester, repo);
      expect(repo.myGuidesFetches, 1);

      await tester.tap(find.text('Guide d1'));
      await settle(tester);
      router.pop();
      await settle(tester);

      expect(repo.myGuidesFetches, 2);
    });

    testWidgets('empty: EmptyState with the agreed copy', (tester) async {
      await _pump(tester, _repo());

      expect(find.byType(GeauxEmptyState), findsOneWidget);
      expect(
        find.text(
          'No guides yet. Guides you write show up here, drafts included.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failed load shows Retry, which loads again', (tester) async {
      final repo = _repo(mine: [_own('p1', GuideStatus.published)])
        ..failFetch = true;
      await _pump(tester, repo);
      expect(find.text("Couldn't load guides."), findsOneWidget);

      repo.failFetch = false;
      await tester.tap(find.text('RETRY'));
      await settle(tester);

      expect(find.text('Guide p1'), findsOneWidget);
    });
  });

  group('Starred', () {
    testWidgets('lists the starred guides, newest star first', (tester) async {
      await _pump(tester, _repo(starred: {'s2', 's1'}));
      await _showStarred(tester);

      expect(
        tester.getTopLeft(find.text('Starred herb spiral')).dy,
        lessThan(tester.getTopLeft(find.text('Starred tomato tower')).dy),
      );
    });

    testWidgets('a starred guide opens guide detail', (tester) async {
      final router = await _pump(tester, _repo(starred: {'s1'}));
      await _showStarred(tester);

      await tester.tap(find.text('Starred tomato tower'));
      await settle(tester);

      expect(router.state.uri.path, '/community/guide/s1');
    });

    testWidgets('empty: EmptyState with the agreed copy', (tester) async {
      await _pump(tester, _repo());
      await _showStarred(tester);

      expect(find.byType(GeauxEmptyState), findsOneWidget);
      expect(
        find.text('No starred guides yet. Star a guide to keep it here.'),
        findsOneWidget,
      );
    });

    testWidgets('opening CM-05 does not fetch the starred set again', (
      tester,
    ) async {
      final repo = _repo(starred: {'s1'});
      await _pump(tester, repo);
      await _showStarred(tester);
      await tester.tap(find.text('My guides'));
      await settle(tester);
      await _showStarred(tester);

      expect(repo.starredFetches, 1);
    });
  });

  group('signed out', () {
    testWidgets('asks to sign in before showing either list', (tester) async {
      final repo = _repo(mine: [_own('d1', GuideStatus.draft)]);
      await _pump(tester, repo, auth: FakeAuthRepository());

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Guide d1'), findsNothing);
      expect(repo.myGuidesFetches, 0);
      expect(repo.starredFetches, 0);
    });

    testWidgets('closing the sign-in sheet goes back to the feed', (
      tester,
    ) async {
      final router = await _pump(tester, _repo(), auth: FakeAuthRepository());

      await tester.tapAt(const Offset(180, 40));
      await settle(tester);

      expect(router.state.uri.path, '/community');
      expect(find.text('feed'), findsOneWidget);
    });
  });
}
