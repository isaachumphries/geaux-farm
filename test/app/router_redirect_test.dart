import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/onboarding/data/attribution_repository.dart';
import 'package:geaux_farm/features/onboarding/data/onboarding_repository.dart';
import 'package:geaux_farm/features/onboarding/data/profile_writer.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/onboarding/presentation/welcome_screen.dart';
import 'package:go_router/go_router.dart';

import '../helpers/persisted_app_harness.dart';
import '../onboarding/finished_draft.dart';

final _now = DateTime(2026, 10, 7, 9);

/// Every plan/09 § Routes entry outside `/onboarding`, as a deep link
/// (path parameters and the `/care` date query filled in). Local is a
/// stretch tab and not routed yet.
const _appLinks = [
  '/',
  '/home',
  '/home/recommendations',
  '/plants/kale',
  '/weather',
  '/settings',
  '/settings/edit/space',
  '/garden',
  '/garden/planting/p1',
  '/garden/project/g1',
  '/care',
  '/care?date=2026-10-07',
  '/community',
  '/community/guide/g1',
  '/community/editor/new',
  '/community/me',
];

/// A fresh in-memory database the test closes when it ends.
AppDatabase _openDb(WidgetTester tester) {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => tester.runAsync(db.close));
  return db;
}

/// Writes the finished profile, as OB-07 Finish does.
Future<void> _seedOnboarded(WidgetTester tester, AppDatabase db) async {
  await tester.runAsync(
    () => OnboardingRepository(
      writer: ProfileWriter(db),
      attribution: NoopAttributionRepository(),
      now: () => _now,
    ).completeOnboarding(finishedDraft),
  );
}

/// The selected branch of the tab shell, or null when the top screen is
/// outside it.
int? _tabIndex(WidgetTester tester) {
  final shell = find.byType(StatefulNavigationShell);
  if (shell.evaluate().isEmpty) return null;
  return tester.widget<StatefulNavigationShell>(shell).currentIndex;
}

void main() {
  testWidgets('plan/09 § Routes: before onboarding, every deep link outside '
      '/onboarding lands on Welcome and every step stays put', (tester) async {
    final db = _openDb(tester);
    final c = await pumpAppOverDatabase(tester, db, now: _now);
    expect(routerLocation(c).path, OnboardingRoutes.welcome);

    for (final step in OnboardingRoutes.ordered) {
      await goAndSettle(tester, c, step);
      expect(routerLocation(c).path, step, reason: step);
    }

    for (final link in _appLinks) {
      // Start from a step that is not Welcome, so staying put would show.
      await goAndSettle(tester, c, OnboardingRoutes.goals);
      await goAndSettle(tester, c, link);
      expect(routerLocation(c).path, OnboardingRoutes.welcome, reason: link);
      expect(find.byType(WelcomeScreen), findsOneWidget, reason: link);
      expect(_tabIndex(tester), isNull, reason: link);
    }
    await unmountApp(tester);
  });

  testWidgets('plan/09 § Routes: the redirect re-runs when '
      'onboarding_completed_at goes back to null', (tester) async {
    final db = _openDb(tester);
    await _seedOnboarded(tester, db);
    final c = await pumpAppOverDatabase(tester, db, now: _now);
    await goAndSettle(tester, c, '/care?date=2026-10-07');
    expect(routerLocation(c).path, '/care');

    // No navigation: only the profile row changes.
    await tester.runAsync(() => db.delete(db.userProfileTable).go());
    await settleDrift(tester);
    expect(routerLocation(c).path, OnboardingRoutes.welcome);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('deep links into a tab open inside that tab', (tester) async {
    final db = _openDb(tester);
    await _seedOnboarded(tester, db);
    final c = await pumpAppOverDatabase(tester, db, now: _now);

    // Home, Garden, Care, Community (TabShell order).
    const tabs = {
      '/home': 0,
      '/home/recommendations': 0,
      '/garden': 1,
      '/garden/planting/p1': 1,
      '/garden/project/g1': 1,
      '/care': 2,
      '/care?date=2026-10-07': 2,
      '/community': 3,
      '/community/guide/g1': 3,
      '/community/editor/new': 3,
      '/community/me': 3,
    };
    for (final MapEntry(key: link, value: index) in tabs.entries) {
      await goAndSettle(tester, c, link);
      expect(routerLocation(c).toString(), link, reason: link);
      expect(_tabIndex(tester), index, reason: link);
    }

    // Tab roots show the bottom bar with their own tab selected.
    for (final MapEntry(key: root, value: index) in const {
      '/home': 0,
      '/garden': 1,
      '/care': 2,
      '/community': 3,
    }.entries) {
      await goAndSettle(tester, c, root);
      expect(
        tester.widget<GeauxBottomNav>(find.byType(GeauxBottomNav)).currentIndex,
        index,
        reason: root,
      );
    }
    await unmountApp(tester);
  });

  testWidgets('PD-01, WX-01 and ST-01 open full screen, above the tab bar '
      '(plan/01: no BottomNav on those frames)', (tester) async {
    final db = _openDb(tester);
    await _seedOnboarded(tester, db);
    final c = await pumpAppOverDatabase(tester, db, now: _now);

    for (final link in const [
      '/plants/kale',
      '/weather',
      '/settings',
      '/settings/edit/space',
    ]) {
      await goAndSettle(tester, c, link);
      expect(routerLocation(c).path, link, reason: link);
      expect(find.byType(GeauxBottomNav), findsNothing, reason: link);
      expect(_tabIndex(tester), isNull, reason: link);
    }
    await unmountApp(tester);
  });
}
