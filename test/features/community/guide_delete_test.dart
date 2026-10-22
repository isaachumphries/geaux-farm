import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/application/community_feed_provider.dart';
import 'package:geaux_farm/features/community/application/growing_guides_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';
import 'package:geaux_farm/features/community/presentation/delete_guide.dart';
import 'package:geaux_farm/features/community/presentation/guide_detail_screen.dart';
import 'package:go_router/go_router.dart';

import '../../community/fake_auth_repository.dart';
import '../../community/guide_detail_harness.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/community_fixtures.dart';

// CM-02 Delete for the author, through the real deleteOwnGuide wiring: ask
// first, remove the guide, go back to the feed.

/// Pumps CM-02 for the author of [guide] with Delete wired as the app does.
Future<GoRouter> _pumpOwnGuide(
  WidgetTester tester,
  FakeGuideRepository repo,
  String id,
  String authorId,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/community/guide/$id',
    routes: [
      GoRoute(
        path: '/community',
        builder: (_, _) => const Scaffold(body: Text('feed')),
        routes: [
          GoRoute(
            path: 'guide/:id',
            builder: (_, state) {
              final guideId = state.pathParameters['id']!;
              return Consumer(
                builder: (context, ref, _) => GuideDetailScreen(
                  guideId: guideId,
                  onDelete: () =>
                      deleteOwnGuide(context, ref, guideId: guideId),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...appOverrides(profile: onboardedProfile),
        guideRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: signedInUser.copyForAuthor(authorId)),
        ),
        growingGuideProjectsProvider.overrideWith(
          (ref) => Stream.value(const {}),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await settle(tester);
  return router;
}

Future<void> _tapDelete(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

/// A repository whose delete waits until [release] completes.
class _SlowDeleteRepository extends FakeGuideRepository {
  _SlowDeleteRepository({super.guides});

  final release = Completer<void>();

  @override
  Future<void> deleteGuide(String guideId) async {
    await release.future;
    return super.deleteGuide(guideId);
  }
}

void main() {
  final guide = testGuide('g1');

  testWidgets('confirming deletes the guide and returns to the feed', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    final router = await _pumpOwnGuide(tester, repo, 'g1', guide.authorId);

    // The feed stays mounted under CM-02 in the app, so hold it open.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GuideDetailScreen)),
    );
    final feed = container.listen(
      communityFeedProvider(const GuideFeedQuery()),
      (_, _) {},
    );
    addTearDown(feed.close);
    await tester.pumpAndSettle();
    final fetchesBefore = repo.fetches.length;
    expect(fetchesBefore, 1);

    await _tapDelete(tester);
    expect(find.text('Delete this guide?'), findsOneWidget);
    expect(repo.deleted, isEmpty);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleted, ['g1']);
    // The feed under CM-02 must not keep listing the deleted guide.
    expect(repo.fetches.length, greaterThan(fetchesBefore));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/community');
    expect(find.text('feed'), findsOneWidget);
    expect(find.text('Guide deleted'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Cancel deletes nothing and stays on the guide', (tester) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    final router = await _pumpOwnGuide(tester, repo, 'g1', guide.authorId);

    await _tapDelete(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this guide?'), findsNothing);
    expect(repo.deleted, isEmpty);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/community/guide/g1',
    );
    expect(find.text(guide.title), findsWidgets);
    await unmount(tester);
  });

  testWidgets('a failed delete says so and stays on the guide', (tester) async {
    final repo = FakeGuideRepository(guides: {'g1': guide})
      ..writeError = const NetworkException('offline');
    final router = await _pumpOwnGuide(tester, repo, 'g1', guide.authorId);

    await _tapDelete(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't delete the guide. Try again."), findsOneWidget);
    expect(find.text('Guide deleted'), findsNothing);
    expect(repo.deleted, isEmpty);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/community/guide/g1',
    );
    await unmount(tester);
  });

  testWidgets('a delete that finishes after CM-02 closed still refreshes the '
      'feed', (tester) async {
    final repo = _SlowDeleteRepository(guides: {'g1': guide});
    final router = await _pumpOwnGuide(tester, repo, 'g1', guide.authorId);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GuideDetailScreen)),
    );
    final feed = container.listen(
      communityFeedProvider(const GuideFeedQuery()),
      (_, _) {},
    );
    addTearDown(feed.close);
    await tester.pumpAndSettle();
    final fetchesBefore = repo.fetches.length;

    await _tapDelete(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump();
    // The user leaves while the request is in flight.
    router.go('/community');
    await tester.pumpAndSettle();
    repo.release.complete();
    await tester.pumpAndSettle();

    expect(repo.deleted, ['g1']);
    expect(repo.fetches.length, greaterThan(fetchesBefore));
    await unmount(tester);
  });
}
