import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:go_router/go_router.dart';

/// Pumps one onboarding [screen] at [route] in a 360×800 view (or [size]). Every other
/// onboarding route, `/home`, and `/settings/edit/:step` is a stub that
/// shows its path, so a test can check where a button went with
/// `find.text(path)`. Returns the scope's container and the router.
Future<({ProviderContainer container, GoRouter router})> pumpOnboardingStep(
  WidgetTester tester, {
  required String route,
  required Widget screen,
  List<Override> overrides = const [],
  Map<String, Widget Function(GoRouterState)> screens = const {},
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget stub(GoRouterState state) =>
      Scaffold(body: Center(child: Text(state.uri.toString())));
  final paths = {...OnboardingRoutes.ordered, '/home', '/settings/edit/:step'}
    ..remove(route);
  final router = GoRouter(
    initialLocation: route,
    routes: [
      GoRoute(path: route, builder: (_, _) => screen),
      for (final p in paths)
        GoRoute(path: p, builder: (_, state) => (screens[p] ?? stub)(state)),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  return (container: container, router: router);
}
