import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/garden/application/garden_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/garden/presentation/planting_detail_screen.dart';
import 'package:geaux_farm/features/garden/presentation/widgets/planting_card.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';

import '../helpers/persisted_app_harness.dart' show settleDrift;
import 'garden_harness.dart';

void main() {
  group('GD-01 empty state', () {
    testWidgets('says the garden is empty and offers a first plant', (
      tester,
    ) async {
      final db = openGardenDb();
      await tester.runAsync(() => seedSpace(db));
      await pumpGarden(tester, db);

      expect(find.text('My Garden'), findsOneWidget);
      expect(find.text('Your garden is empty'), findsOneWidget);
      expect(find.byType(PlantingCard), findsNothing);
    });

    testWidgets('the empty-state button opens RC-01', (tester) async {
      final db = openGardenDb();
      await tester.runAsync(() => seedSpace(db));
      await pumpGarden(tester, db);

      await tester.tap(find.text('FIND A PLANT'));
      await tester.pumpAndSettle();

      expect(find.text('RC-01 stub'), findsOneWidget);
    });

    testWidgets('the add button opens RC-01 too', (tester) async {
      final db = openGardenDb();
      await tester.runAsync(() async {
        await seedSpace(db);
        await seedPlanting(db);
      });
      await pumpGarden(tester, db);

      await tester.tap(find.byTooltip('Add a plant'));
      await tester.pumpAndSettle();

      expect(find.text('RC-01 stub'), findsOneWidget);
    });
  });

  group('GD-01 sections', () {
    Future<void> seedMixed(WidgetTester tester) async {
      final db = openGardenDb();
      await tester.runAsync(() async {
        await seedSpace(db);
        await seedPlanting(
          db,
          id: 'a1',
          nickname: 'Balcony Kale',
          plantedOn: gardenNow,
          createdAt: DateTime(2026, 9, 1),
        );
        await seedPlanting(
          db,
          id: 'a2',
          plantId: 'sweet-basil',
          nickname: 'Basil',
          setup: GrowSetup.outdoor,
          plantedOn: DateTime(2026, 9, 19),
          createdAt: DateTime(2026, 9, 2),
        );
        await seedPlanting(
          db,
          id: 'pl',
          nickname: 'Next Year Kale',
          status: PlantingStatus.planned,
        );
        await seedPlanting(
          db,
          id: 'h1',
          nickname: 'Old Kale',
          plantedOn: DateTime(2026, 6, 1),
          status: PlantingStatus.harvested,
        );
        await seedPlanting(
          db,
          id: 'rm',
          nickname: 'Gone Kale',
          status: PlantingStatus.removed,
        );
      });
      await pumpGarden(tester, db);
    }

    testWidgets('groups plantings Active, Planned, Harvested with counts', (
      tester,
    ) async {
      await seedMixed(tester);

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Harvested'), findsNWidgets(2)); // title + Old Kale
      expect(find.text('Balcony Kale'), findsOneWidget);
      expect(find.text('Basil'), findsOneWidget);
      expect(find.text('Next Year Kale'), findsOneWidget);
      expect(find.text('Old Kale'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Active count badge
    });

    testWidgets('a removed planting is not listed', (tester) async {
      await seedMixed(tester);
      expect(find.text('Gone Kale'), findsNothing);
    });

    testWidgets('sections run in order, each planting under its own', (
      tester,
    ) async {
      await seedMixed(tester);
      double y(String text) => tester.getTopLeft(find.text(text).first).dy;

      expect(y('Balcony Kale'), lessThan(y('Basil')));
      expect(y('Basil'), lessThan(y('Next Year Kale')));
      expect(y('Next Year Kale'), lessThan(y('Old Kale')));
    });

    testWidgets('a card shows where, stage, next water, and the ring', (
      tester,
    ) async {
      await seedMixed(tester);

      expect(find.text('Balcony · Indoors'), findsNWidgets(3));
      expect(find.text('Balcony · Outdoors'), findsOneWidget);
      // Kale planted today: first water is due today.
      expect(find.text('Planted today'), findsOneWidget);
      expect(find.text('Water today'), findsOneWidget);
      // Basil planted 18 days ago, never watered: overdue.
      expect(find.text('Growing · Day 18'), findsOneWidget);
      expect(find.text('Water now'), findsOneWidget);
      // Rings only on the two active plantings, 0% and 18/30 = 60%.
      final rings = tester.widgetList<GrowthRing>(find.byType(GrowthRing));
      expect(rings.map((r) => r.progress), unorderedEquals([0.0, 0.6]));
    });

    testWidgets('a harvested card says Harvested, with no ring or chip', (
      tester,
    ) async {
      await seedMixed(tester);
      final harvested = find.widgetWithText(PlantingCard, 'Old Kale');
      expect(
        find.descendant(of: harvested, matching: find.text('Harvested')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: harvested, matching: find.textContaining('Water')),
        findsNothing,
      );
      expect(
        find.descendant(of: harvested, matching: find.byType(GrowthRing)),
        findsNothing,
      );
    });

    testWidgets('a planned planting has no stage line yet', (tester) async {
      await seedMixed(tester);
      final planned = find.widgetWithText(PlantingCard, 'Next Year Kale');
      expect(
        find.descendant(of: planned, matching: find.textContaining('Day')),
        findsNothing,
      );
      expect(
        find.descendant(of: planned, matching: find.text('Planted today')),
        findsNothing,
      );
    });

    testWidgets(
      'a filter chip per section narrows the list, tap again clears',
      (tester) async {
        await seedMixed(tester);
        expect(find.text('Active · 2'), findsOneWidget);
        expect(find.text('Planned · 1'), findsOneWidget);
        expect(find.text('Harvested · 1'), findsOneWidget);

        await tester.tap(find.text('Planned · 1'));
        await tester.pumpAndSettle();
        expect(find.text('Next Year Kale'), findsOneWidget);
        expect(find.text('Balcony Kale'), findsNothing);
        expect(find.text('Old Kale'), findsNothing);

        await tester.tap(find.text('Planned · 1'));
        await tester.pumpAndSettle();
        expect(find.text('Balcony Kale'), findsOneWidget);
        expect(find.text('Old Kale'), findsOneWidget);
      },
    );

    testWidgets('tapping a planting opens GD-02', (tester) async {
      final db = openGardenDb();
      await tester.runAsync(() async {
        await seedSpace(db);
        await seedPlanting(db, nickname: 'Kale Corner', plantedOn: gardenNow);
      });
      final router = await pumpGarden(tester, db);

      await tester.tap(find.text('Kale Corner'));
      await settleDrift(tester);

      expect(locationOf(router).path, '/garden/planting/p1');
      expect(find.byType(PlantingDetailScreen), findsOneWidget);
      expect(find.text('Kale Corner'), findsWidgets);
    });

    testWidgets('chips are left out when only one section has plantings', (
      tester,
    ) async {
      final db = openGardenDb();
      await tester.runAsync(() async {
        await seedSpace(db, type: SpaceType.windowsill);
        await seedPlanting(db, plantedOn: gardenNow);
      });
      await pumpGarden(tester, db);

      expect(find.text('Windowsill · Indoors'), findsOneWidget);
      expect(find.textContaining('Active ·'), findsNothing);
    });

    testWidgets('a new planting appears without reopening the screen', (
      tester,
    ) async {
      final db = openGardenDb();
      await tester.runAsync(() => seedSpace(db));
      await pumpGarden(tester, db);
      expect(find.text('Your garden is empty'), findsOneWidget);

      await tester.runAsync(
        () => seedPlanting(db, nickname: 'Late Kale', plantedOn: gardenNow),
      );
      await settleDrift(tester);

      expect(find.text('Late Kale'), findsOneWidget);
      expect(find.text('Your garden is empty'), findsNothing);
    });
  });

  group('GD-01 loading and failure', () {
    testWidgets('shows a spinner while the garden loads', (tester) async {
      final db = openGardenDb();
      await tester.runAsync(() => seedSpace(db));
      final never = Completer<List<PlantingView>>();
      await pumpGarden(
        tester,
        db,
        settle: false,
        extra: [gardenProvider.overrideWith((ref) => never.future)],
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('says so when the garden cannot load', (tester) async {
      final db = openGardenDb();
      await tester.runAsync(() => seedSpace(db));
      await pumpGarden(
        tester,
        db,
        extra: [
          gardenProvider.overrideWith(
            (ref) => Future<List<PlantingView>>.error(StateError('boom')),
          ),
        ],
      );
      expect(find.text("Couldn't load your garden."), findsOneWidget);
    });
  });
}
