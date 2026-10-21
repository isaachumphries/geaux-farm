import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/community/application/growing_guides_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:geaux_farm/features/community/presentation/guide_detail_screen.dart';
import 'package:geaux_farm/features/community/presentation/report_sheet.dart';
import 'package:go_router/go_router.dart';

import '../helpers/app_harness.dart';
import '../helpers/community_fixtures.dart';
import 'fake_auth_repository.dart';

/// A signed-in user with a profile.
const signedInUser = AuthUser(
  id: 'u1',
  email: 'isaac@example.com',
  username: 'isaac',
);

extension AuthUserForTest on AuthUser {
  /// This user, with the id of a guide's author, so the guide is theirs.
  AuthUser copyForAuthor(String authorId) =>
      AuthUser(id: authorId, email: email, username: username);
}

/// Pumps CM-02 for guide [id] at 360x800 (or [height]) on its real route,
/// next to stub routes for everything it opens, and returns the router.
///
/// [growing] maps guide ids to the Drift project that makes them "Growing".
Future<GoRouter> pumpGuideDetail(
  WidgetTester tester,
  FakeGuideRepository repo, {
  FakeAuthRepository? auth,
  String id = 'g1',
  Map<String, String> growing = const {},
  double height = 800,
  VoidCallback? onGrow,
  VoidCallback? onRemix,
  VoidCallback? onReport,
  bool wireReport = false,
}) async {
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/community/guide/$id',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(
        path: '/community/guide/:id',
        builder: (_, state) {
          final guideId = state.pathParameters['id']!;
          // wireReport runs the real router wiring (sign-in gate plus the
          // report sheet) instead of a stub callback, so #60's flow test
          // covers what the app actually does.
          return Consumer(
            builder: (context, ref, _) => GuideDetailScreen(
              guideId: guideId,
              onGrow: onGrow,
              onRemix: onRemix,
              onReport: wireReport
                  ? () => reportGuide(context, ref, guideId: guideId)
                  : onReport,
            ),
          );
        },
      ),
      GoRoute(
        path: '/community/editor/:id',
        builder: (_, state) => Text('editor ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/plants/:id',
        builder: (_, state) => Text('plant ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/garden/project/:id',
        builder: (_, state) => Text('project ${state.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...appOverrides(profile: onboardedProfile),
        guideRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        growingGuideProjectsProvider.overrideWith(
          (ref) => Stream.value(growing),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await settle(tester);
  return router;
}

/// Lets providers, the catalog load and the screen's futures finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Removes the app so its providers and their timers are disposed.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}
