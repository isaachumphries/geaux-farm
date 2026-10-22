import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/settings/presentation/widgets/units_tile.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/in_memory_database.dart';

Future<void> _seedProfile(AppDatabase db, {required String units}) => db
    .into(db.userProfileTable)
    .insert(
      UserProfileTableCompanion.insert(
        id: const Value(1),
        city: 'Baton Rouge',
        admin1: 'Louisiana',
        countryCode: 'US',
        lat: 30.45,
        lon: -91.19,
        timezone: 'America/Chicago',
        goals: [Goal.food],
        experience: Experience.beginner,
        availability: careAllFree,
        units: units,
        notificationsEnabled: const Value(true),
      ),
    );

Future<UserProfileRow> _row(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.userProfileTable).getSingle()))!;

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  Future<AppDatabase> pump(WidgetTester tester, {required String units}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inMemoryDatabaseOverride()],
        child: const MaterialApp(home: Scaffold(body: UnitsTile())),
      ),
    );
    final db = ProviderScope.containerOf(tester.element(find.byType(UnitsTile)))
        .read(appDatabaseProvider);
    await tester.runAsync(() => _seedProfile(db, units: units));
    await _settle(tester);
    return db;
  }

  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  void expectSelected(WidgetTester tester, String label, bool selected) {
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text(label)),
      isSemantics(label: label, isSelected: selected),
    );
    handle.dispose();
  }

  testWidgets('shows both unit systems with the profile one selected', (
    tester,
  ) async {
    await pump(tester, units: 'imperial');
    expect(find.text('Units'), findsOneWidget);
    expectSelected(tester, '°F / in', true);
    expectSelected(tester, '°C / mm', false);
    await tearDownTree(tester);
  });

  testWidgets('choosing °C / mm stores metric and nothing else changes', (
    tester,
  ) async {
    final db = await pump(tester, units: 'imperial');
    final before = await _row(tester, db);

    await tester.tap(find.text('°C / mm'));
    await _settle(tester);

    final after = await _row(tester, db);
    expect(after.units, 'metric');
    // Only the units column moves; the rest of the row is as seeded.
    expect(
      (after.city, after.lat, after.lon, after.notificationsEnabled),
      (before.city, before.lat, before.lon, before.notificationsEnabled),
    );
    expectSelected(tester, '°C / mm', true);
    await tearDownTree(tester);
  });

  testWidgets('choosing °F / in from metric stores imperial', (tester) async {
    final db = await pump(tester, units: 'metric');
    expectSelected(tester, '°C / mm', true);

    await tester.tap(find.text('°F / in'));
    await _settle(tester);

    expect((await _row(tester, db)).units, 'imperial');
    await tearDownTree(tester);
  });
}
