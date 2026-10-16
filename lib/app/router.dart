import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_first_run_screen.dart';
import '../features/onboarding/data/profile_providers.dart';
import '../features/onboarding/domain/user_profile.dart';
import '../features/onboarding/presentation/onboarding_placeholder.dart';
import '../features/onboarding/presentation/onboarding_routes.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import 'tab_shell.dart';
import 'titled_scaffold.dart';

/// Where a fresh install starts (OB-01).
const onboardingStart = OnboardingRoutes.welcome;

/// The `date` query parameter of `/care?date=2026-10-07`, or null when it
/// is missing or not a `yyyy-MM-dd` date.
DateTime? careDateFrom(Uri uri) {
  final raw = uri.queryParameters['date'];
  if (raw == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    return null;
  }
  return DateTime.tryParse(raw);
}

/// Sends every location outside `/onboarding` to [onboardingStart] until
/// onboarding is complete. Returns null (no redirect) otherwise, and while
/// the profile is still loading.
String? onboardingRedirect(AsyncValue<UserProfile> profile, Uri location) {
  if (!profile.hasValue) return null;
  final onboarded = profile.requireValue.onboardingCompletedAt != null;
  if (onboarded || location.path.startsWith('/onboarding')) return null;
  return onboardingStart;
}

GoRoute _placeholder(String path, String title, {List<RouteBase>? routes}) =>
    GoRoute(
      path: path,
      builder: (context, state) => TitledScaffold(title),
      routes: routes ?? const [],
    );

GoRoute _onboardingPlaceholder(String path, String title) => GoRoute(
  path: path,
  builder: (context, state) => OnboardingPlaceholder(title: title, route: path),
);

/// The app's route table (plan/09 § Routes). Local (`/local/...`) is a
/// stretch tab and ships with its own issues.
final goRouterProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the profile row changes, e.g. when OB-07
  // sets onboarding_completed_at.
  final refresh = ValueNotifier<int>(0);
  ref.listen(userProfileProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) =>
        onboardingRedirect(ref.read(userProfileProvider), state.uri),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      GoRoute(
        path: onboardingStart,
        builder: (context, state) => const WelcomeScreen(),
      ),
      _onboardingPlaceholder(OnboardingRoutes.location, 'OB-02 Location'),
      _onboardingPlaceholder(OnboardingRoutes.climate, 'OB-02b Climate reveal'),
      _onboardingPlaceholder(OnboardingRoutes.space, 'OB-03 Space'),
      _onboardingPlaceholder(OnboardingRoutes.goals, 'OB-04 Goals'),
      _onboardingPlaceholder(OnboardingRoutes.time, 'OB-05 Availability'),
      _onboardingPlaceholder(OnboardingRoutes.source, 'OB-06 Heard about us'),
      _onboardingPlaceholder(OnboardingRoutes.summary, 'OB-07 Profile summary'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TabShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeFirstRunScreen(),
                routes: [
                  _placeholder('recommendations', 'RC-01 Recommendations'),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _placeholder(
                '/garden',
                'GD-01 My Garden',
                routes: [
                  _placeholder('planting/:id', 'GD-02 Planting detail'),
                  _placeholder('project/:id', 'GD-03 Guide project'),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_placeholder('/care', 'CR-01 Care schedule')],
          ),
          StatefulShellBranch(
            routes: [
              _placeholder(
                '/community',
                'CM-01 Feed',
                routes: [
                  _placeholder('guide/:id', 'CM-02 Guide detail'),
                  _placeholder('editor/:id', 'CM-03 Editor'),
                  _placeholder('me', 'CM-05 My profile'),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen routes above the tab bar.
      _placeholder('/plants/:plantId', 'PD-01 Plant detail'),
      _placeholder('/weather', 'WX-01 Weather'),
      _placeholder(
        '/settings',
        'ST-01 Settings',
        routes: [_placeholder('edit/:step', 'OB-07 Edit step')],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
