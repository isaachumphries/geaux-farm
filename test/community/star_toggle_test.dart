import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/application/guide_star_provider.dart';
import 'package:geaux_farm/features/community/application/starred_guides_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/presentation/widgets/stat_button.dart';

import '../helpers/community_fixtures.dart';
import 'fake_auth_repository.dart';
import 'guide_detail_harness.dart';

/// The star pill's selected flag.
bool _starSelected(WidgetTester tester) =>
    tester.widget<StatButton>(find.byType(StatButton).first).selected;

Finder _starCount(String count) => find.descendant(
  of: find.byType(StatButton).first,
  matching: find.text(count),
);

void main() {
  late Guide guide;
  late FakeAuthRepository auth;

  setUp(() {
    guide = testGuide('g1', stars: 5);
    auth = FakeAuthRepository(user: signedInUser);
  });

  group('screen', () {
    testWidgets('starring changes the pill and count before the write ends', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': guide})
        ..writeGate = Completer<void>();
      await pumpGuideDetail(tester, repo, auth: auth);
      expect(find.text('Star'), findsOneWidget);
      expect(_starCount('5'), findsOneWidget);
      expect(_starSelected(tester), isFalse);

      await tester.tap(find.text('Star'));
      await tester.pump();

      // The write has started but not finished.
      expect(repo.writes, ['star:g1']);
      expect(find.text('Starred'), findsOneWidget);
      expect(_starCount('6'), findsOneWidget);
      expect(_starSelected(tester), isTrue);

      repo.writeGate!.complete();
      await settle(tester);
      expect(find.text('Starred'), findsOneWidget);
      expect(_starCount('6'), findsOneWidget);
      expect(repo.writes, ['star:g1']);
      await unmount(tester);
    });

    testWidgets('unstarring changes the pill and count before the write ends', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': guide}, starred: {'g1'})
        ..writeGate = Completer<void>();
      await pumpGuideDetail(tester, repo, auth: auth);
      expect(find.text('Starred'), findsOneWidget);
      expect(_starSelected(tester), isTrue);

      await tester.tap(find.text('Starred'));
      await tester.pump();

      expect(repo.writes, ['unstar:g1']);
      expect(find.text('Star'), findsOneWidget);
      expect(_starCount('4'), findsOneWidget);
      expect(_starSelected(tester), isFalse);

      repo.writeGate!.complete();
      await settle(tester);
      expect(_starCount('4'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a failed star rolls back and shows a snackbar', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': guide})
        ..writeError = Exception('rls');
      await pumpGuideDetail(tester, repo, auth: auth);

      await tester.tap(find.text('Star'));
      await tester.pump();
      await tester.pump();

      expect(repo.writes, ['star:g1']);
      expect(find.text('Star'), findsOneWidget);
      expect(find.text('Starred'), findsNothing);
      expect(_starCount('5'), findsOneWidget);
      expect(_starSelected(tester), isFalse);
      expect(find.text("Couldn't update your star."), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a failed unstar rolls back and shows a snackbar', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': guide}, starred: {'g1'})
        ..writeError = Exception('offline');
      await pumpGuideDetail(tester, repo, auth: auth);

      await tester.tap(find.text('Starred'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Starred'), findsOneWidget);
      expect(_starCount('5'), findsOneWidget);
      expect(find.text("Couldn't update your star."), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a tap while the write is in flight writes nothing more', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': guide})
        ..writeGate = Completer<void>();
      await pumpGuideDetail(tester, repo, auth: auth);

      await tester.tap(find.text('Star'));
      await tester.pump();
      await tester.tap(find.text('Starred'));
      await tester.pump();

      expect(repo.writes, ['star:g1']);
      expect(_starCount('6'), findsOneWidget);
      repo.writeGate!.complete();
      await settle(tester);
      await unmount(tester);
    });

    testWidgets('the count never goes below zero', (tester) async {
      final repo = FakeGuideRepository(
        guides: {'g1': testGuide('g1', stars: 0)},
        starred: {'g1'},
      );
      await pumpGuideDetail(tester, repo, auth: auth);

      await tester.tap(find.text('Starred'));
      await tester.pump();

      expect(_starCount('0'), findsOneWidget);
      await settle(tester);
      await unmount(tester);
    });

    testWidgets('reopening the guide reads the count the server has now', (
      tester,
    ) async {
      final guides = {'g1': guide};
      final repo = FakeGuideRepository(guides: guides);
      await pumpGuideDetail(tester, repo, auth: auth);
      expect(_starCount('5'), findsOneWidget);
      await unmount(tester);

      // Another account starred it meanwhile.
      guides['g1'] = guideWithStars(guide, 6);
      await pumpGuideDetail(tester, repo, auth: auth);

      expect(_starCount('6'), findsOneWidget);
      expect(repo.guideFetches, ['g1', 'g1']);
      await unmount(tester);
    });

    testWidgets(
      'leaving the guide and coming back in one session reads the count '
      'the server has now',
      (tester) async {
        final guides = {'g1': guide};
        final repo = FakeGuideRepository(guides: guides);
        // One ProviderScope for the whole test, as the app has: the guide
        // provider must not outlive the screen, or this second visit would
        // show the count of the first.
        final router = await pumpGuideDetail(tester, repo, auth: auth);
        expect(_starCount('5'), findsOneWidget);

        router.go('/');
        await settle(tester);
        expect(find.text('home'), findsOneWidget);

        // Another account starred it while the user was away.
        guides['g1'] = guideWithStars(guide, 6);
        router.push('/community/guide/g1');
        await settle(tester);

        expect(_starCount('6'), findsOneWidget);
        expect(repo.guideFetches, ['g1', 'g1']);
        await unmount(tester);
      },
    );

    testWidgets(
      'a star still lands when the user leaves before the write ends',
      (tester) async {
        final repo = FakeGuideRepository(guides: {'g1': guide})
          ..writeGate = Completer<void>();
        final router = await pumpGuideDetail(tester, repo, auth: auth);
        await tester.tap(find.text('Star'));
        await tester.pump();
        expect(repo.writes, ['star:g1']);

        // Back out while the insert is still in flight, then let it finish.
        router.go('/');
        await settle(tester);
        repo.writeGate!.complete();
        await settle(tester);
        expect(tester.takeException(), isNull);

        // Coming back shows the star the write made: the cached "Starred by
        // me" set was refreshed, and nothing was reported as failed.
        router.push('/community/guide/g1');
        await settle(tester);
        expect(find.text('Starred'), findsOneWidget);
        expect(_starCount('6'), findsOneWidget);
        expect(find.text("Couldn't update your star."), findsNothing);
        await unmount(tester);
      },
    );
  });

  group('providers', () {
    ProviderContainer container(FakeGuideRepository repo) {
      final c = ProviderContainer(
        overrides: [
          guideRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(c.dispose);
      // Start from a settled session, as after the first auth event.
      final authSub = c.listen(authStateProvider, (_, _) {});
      addTearDown(authSub.close);
      return c;
    }

    test('setStarred stars, then unstars, one row each', () async {
      final repo = FakeGuideRepository(guides: {'g1': guide});
      final c = container(repo);
      await c.read(authStateProvider.future);
      final sub = c.listen(guideStarProvider('g1'), (_, _) {});
      addTearDown(sub.close);
      await c.read(guideStarProvider('g1').future);
      final notifier = c.read(guideStarProvider('g1').notifier);

      await notifier.setStarred(true);
      expect(
        c.read(guideStarProvider('g1')).value,
        GuideStarState(starred: true, count: 6),
      );
      await notifier.setStarred(false);
      expect(
        c.read(guideStarProvider('g1')).value,
        GuideStarState(starred: false, count: 5),
      );
      expect(repo.writes, ['star:g1', 'unstar:g1']);
    });

    test('asking for the state it already has writes nothing', () async {
      final repo = FakeGuideRepository(guides: {'g1': guide}, starred: {'g1'});
      final c = container(repo);
      await c.read(authStateProvider.future);
      final sub = c.listen(guideStarProvider('g1'), (_, _) {});
      addTearDown(sub.close);
      await c.read(guideStarProvider('g1').future);

      await c.read(guideStarProvider('g1').notifier).setStarred(true);

      expect(repo.writes, isEmpty);
      expect(
        c.read(guideStarProvider('g1')).value,
        GuideStarState(starred: true, count: 5),
      );
    });

    test('a failed write rethrows and restores the state', () async {
      final repo = FakeGuideRepository(guides: {'g1': guide})
        ..writeError = StateError('denied');
      final c = container(repo);
      final sub = c.listen(guideStarProvider('g1'), (_, _) {});
      addTearDown(sub.close);
      await c.read(guideStarProvider('g1').future);

      await expectLater(
        c.read(guideStarProvider('g1').notifier).setStarred(true),
        throwsStateError,
      );

      expect(
        c.read(guideStarProvider('g1')).value,
        GuideStarState(starred: false, count: 5),
      );
    });

    test('a successful write refreshes the cached starred set', () async {
      final repo = FakeGuideRepository(guides: {'g1': guide});
      final c = container(repo);
      await c.read(authStateProvider.future);
      final sub = c.listen(guideStarProvider('g1'), (_, _) {});
      addTearDown(sub.close);
      expect(await c.read(starredGuideIdsProvider.future), isEmpty);
      await c.read(guideStarProvider('g1').future);

      await c.read(guideStarProvider('g1').notifier).setStarred(true);

      expect(await c.read(starredGuideIdsProvider.future), {'g1'});
      expect(repo.starredFetches, 2);
    });

    test('a failed write leaves the cached starred set alone', () async {
      final repo = FakeGuideRepository(guides: {'g1': guide})
        ..writeError = StateError('denied');
      final c = container(repo);
      await c.read(authStateProvider.future);
      final sub = c.listen(guideStarProvider('g1'), (_, _) {});
      addTearDown(sub.close);
      await c.read(starredGuideIdsProvider.future);
      await c.read(guideStarProvider('g1').future);

      await expectLater(
        c.read(guideStarProvider('g1').notifier).setStarred(true),
        throwsStateError,
      );

      await c.read(starredGuideIdsProvider.future);
      expect(repo.starredFetches, 1);
    });

    test('the starred set is read again when the user signs in', () async {
      auth.user = null;
      final repo = FakeGuideRepository(guides: {'g1': guide}, starred: {'g1'});
      final c = container(repo);
      await c.read(authStateProvider.future);
      final sub = c.listen(starredGuideIdsProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(starredGuideIdsProvider.future);
      expect(repo.starredFetches, 1);

      await auth.verifyEmailCode('isaac@example.com', '123456');
      await Future<void>.delayed(Duration.zero);
      await c.read(starredGuideIdsProvider.future);

      expect(repo.starredFetches, 2);
    });
  });
}
