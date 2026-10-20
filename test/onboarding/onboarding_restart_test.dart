import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/home/application/first_plant_prompt_provider.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/onboarding_draft.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';
import 'package:geaux_farm/features/onboarding/presentation/welcome_screen.dart';

import '../helpers/persisted_app_harness.dart';
import 'finished_draft.dart';

// plan/02 § Persistence: Finish writes user_profile (with
// onboarding_completed_at) and the primary space to Drift; the draft itself
// is in memory, so a restart mid-onboarding begins again at Welcome. A
// restart is a fresh ProviderScope over the same database.

final _finishedAt = DateTime(2026, 10, 7, 9, 41);

/// [finishedDraft] with every optional answer filled, so the restore
/// check covers them too.
final _draft = finishedDraft.copyWith(
  sunUnsure: true,
  goals: {Goal.food, Goal.other},
  goalOtherText: 'Medicinal herbs',
  heardFrom: HeardFrom.other,
  heardOtherText: 'A poster',
);

AppDatabase _openDb(WidgetTester tester) {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => tester.runAsync(db.close));
  return db;
}

/// Puts [_draft] in the draft, opens OB-07, taps [button].
Future<void> _finishWith(
  WidgetTester tester,
  ProviderContainer c,
  String button,
) async {
  c.read(onboardingDraftProvider.notifier).state = _draft;
  await goAndSettle(tester, c, OnboardingRoutes.summary);
  await tester.tap(find.text(button));
  await settleDrift(tester);
  expect(routerLocation(c).path, '/home');
}

/// Unmounts the app and pumps it again over [db].
Future<ProviderContainer> _restart(WidgetTester tester, AppDatabase db) async {
  await unmountApp(tester);
  return pumpAppOverDatabase(tester, db, now: DateTime(2026, 10, 8, 7));
}

void main() {
  testWidgets("I'll set up later: after a restart the app opens on HM-01b "
      'with every answer restored', (tester) async {
    final db = _openDb(tester);
    final first = await pumpAppOverDatabase(tester, db, now: _finishedAt);
    expect(routerLocation(first).path, OnboardingRoutes.welcome);
    await _finishWith(tester, first, "I'LL SET UP LATER");

    final c = await _restart(tester, db);
    expect(routerLocation(c).path, '/home');
    expect(find.byType(HomeFirstRunScreen), findsOneWidget);
    // HM-01b: the collapsed card, not the carousel with "I'll pick later".
    expect(c.read(firstPlantPromptDismissedProvider), isTrue);
    expect(find.text('Pick your first plant'), findsOneWidget);
    expect(find.text("I'LL PICK LATER"), findsNothing);

    final profile = c.read(userProfileProvider).requireValue;
    expect(profile.onboardingCompletedAt, _finishedAt);
    expect(profile.city, 'Baton Rouge');
    expect(profile.admin1, 'Louisiana');
    expect(profile.countryCode, 'US');
    expect(profile.postcode, '70801');
    expect((profile.lat, profile.lon), (30.45, -91.19));
    expect(profile.timezone, 'America/Chicago');
    expect(profile.goals.toSet(), {Goal.food, Goal.other});
    expect(profile.goalOtherText, 'Medicinal herbs');
    expect(profile.experience, Experience.intermediate);
    expect(profile.heardFrom, HeardFrom.other);
    expect(profile.heardOtherText, 'A poster');
    expect(profile.availability.days, [64, 0, 64, 0, 0, 2, 2]);

    final space = c.read(primarySpaceProvider).requireValue;
    expect(space.type, SpaceType.balcony);
    expect(space.areaSqFt, 16);
    expect(space.sun, SunLevel.partial);
    expect(space.sunUnsure, isTrue);
    expect(space.rainExposed, isTrue);
    expect(space.inContainerDefault, isTrue);
    expect(space.isPrimary, isTrue);

    // Onboarded: deep links are no longer sent back to Welcome.
    await goAndSettle(tester, c, '/care');
    expect(routerLocation(c).path, '/care');
    await unmountApp(tester);
  });

  testWidgets('Find my first plant: after a restart the app opens on HM-01 '
      'with the carousel', (tester) async {
    final db = _openDb(tester);
    final first = await pumpAppOverDatabase(tester, db, now: _finishedAt);
    await _finishWith(tester, first, 'FIND MY FIRST PLANT');

    final c = await _restart(tester, db);
    expect(routerLocation(c).path, '/home');
    expect(c.read(firstPlantPromptDismissedProvider), isFalse);
    expect(find.text("I'LL PICK LATER"), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('killed mid-onboarding: the restart begins at Welcome with an '
      'empty draft and nothing saved', (tester) async {
    final db = _openDb(tester);
    final first = await pumpAppOverDatabase(tester, db, now: _finishedAt);
    first.read(onboardingDraftProvider.notifier).state = OnboardingDraft(
      city: _draft.city,
      admin1: _draft.admin1,
      countryCode: _draft.countryCode,
      lat: _draft.lat,
      lon: _draft.lon,
      timezone: _draft.timezone,
      spaceType: _draft.spaceType,
      areaSqFt: _draft.areaSqFt,
      sun: _draft.sun,
    );
    await goAndSettle(tester, first, OnboardingRoutes.goals);

    final c = await _restart(tester, db);
    expect(routerLocation(c).path, OnboardingRoutes.welcome);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(c.read(onboardingDraftProvider), const OnboardingDraft());
    expect(
      c.read(userProfileProvider).requireValue.onboardingCompletedAt,
      isNull,
    );
    final rows = await tester.runAsync(
      () => db.select(db.userProfileTable).get(),
    );
    expect(rows, isEmpty);
    expect(c.read(goRouterProvider).canPop(), isFalse);
    await unmountApp(tester);
  });
}
