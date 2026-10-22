import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/application/planting_actions.dart';
import 'package:geaux_farm/features/garden/data/garden_repository.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/garden/presentation/planting_detail_screen.dart';
import 'package:geaux_farm/features/garden/presentation/widgets/planting_card.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:geaux_farm/features/care/presentation/widgets/task_row.dart';

import '../helpers/persisted_app_harness.dart' show settleDrift;
import '../recommendations/fixtures/baton_rouge.dart';
import 'garden_harness.dart';

/// GD-02 for an indoor kale planted six days before [gardenNow], nicknamed
/// so the header shows both names. The profile (garden_harness.dart) is
/// free Mon and Wed 18:00 and Sat and Sun 08:00, and [gardenNow] is Wed
/// Oct 7 09:00: a task due today or overdue lands Wed 18:00, one due Sat
/// Oct 10 lands Sat 08:00.
const _kaleId = 'p1';
final _plantedSixDaysAgo = DateTime(2026, 10, 1);

class _FailingRepository extends GardenRepository {
  _FailingRepository(super.db) : super(now: () => gardenNow);

  @override
  Future<void> logCare(String plantingId, CareEventType type, {String? note}) =>
      Future.error(StateError('disk full'));
}

Future<(AppDatabase, GoRouter)> _pump(
  WidgetTester tester, {
  String plantId = 'kale',
  String nickname = 'Greenie',
  String startMethod = 'transplant',
  DateTime? plantedOn,
  bool planted = true,
  PlantingStatus status = PlantingStatus.active,
  Future<void> Function(AppDatabase db)? seed,
  String? id,
  List<Override> extra = const [],
}) async {
  final db = openGardenDb();
  await tester.runAsync(() async {
    await seedSpace(db);
    await seedProfile(db);
    await seedPlanting(
      db,
      id: _kaleId,
      plantId: plantId,
      nickname: nickname,
      startMethod: startMethod,
      plantedOn: planted ? (plantedOn ?? _plantedSixDaysAgo) : null,
      status: status,
    );
    await seed?.call(db);
  });
  final router = await pumpGarden(
    tester,
    db,
    location: '/garden/planting/${id ?? _kaleId}',
    height: 3000,
    extra: extra,
  );
  return (db, router);
}

Future<List<CareEventRow>> _events(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.careEventsTable).get()))!;

Future<PlantingRow> _row(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.plantingsTable).getSingle()))!;

/// Taps a quick-action tile. The tile's label is a sibling under the card,
/// so aim above the label.
Future<void> _tapAction(WidgetTester tester, String label) async {
  final at = tester.getCenter(find.text(label).first) - const Offset(0, 40);
  await tester.tapAt(at);
}

/// The overdue chip and header slot of a never-watered planting.
const _wedEvening = 'Next water: Wed, Oct 7 · 6:00 PM';

/// After watering on Wed Oct 7: due Sat Oct 10, in Saturday's 08:00 block.
const _satMorning = 'Next water: Sat, Oct 10 · 8:00 AM';

/// Taps the check on the [TaskRow] titled [title].
Future<void> _markDone(WidgetTester tester, String title) async {
  await tester.tap(
    find.descendant(
      of: find.widgetWithText(TaskRow, title),
      matching: find.byIcon(Symbols.check_rounded),
    ),
  );
}

/// Lets a Drift write land and shows the first frames after it, while a
/// snackbar is still up.
Future<void> _afterTap(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final kale = loadReferencePlants()['kale']!;

  group('GD-02 header', () {
    testWidgets('shows nickname, plant, where, start, and stage', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Greenie'), findsNWidgets(2)); // top bar + header
      expect(find.text('Kale'), findsOneWidget);
      expect(find.text('Balcony · Indoors · Transplant'), findsOneWidget);
      expect(find.text('Growing · Day 6'), findsOneWidget);
    });

    testWidgets('a nickname equal to the plant name is shown once', (
      tester,
    ) async {
      await _pump(tester, nickname: 'Kale');
      expect(find.text('Kale'), findsNWidgets(2)); // top bar + header only
    });

    testWidgets('the ring shows growth toward maturity', (tester) async {
      await _pump(tester);
      final ring = tester.widget<GrowthRing>(find.byType(GrowthRing));
      expect(ring.progress, closeTo(6 / 50, 1e-9));
      expect(find.text('12%'), findsOneWidget);
    });

    testWidgets('shows the harvest window for the start method', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Harvest window: Nov 20 – Dec 5'), findsOneWidget);
    });

    testWidgets('next water chip counts from the last water', (tester) async {
      await _pump(
        tester,
        seed: (db) => seedCare(
          db,
          _kaleId,
          CareEventType.water,
          DateTime(2026, 10, 7, 8),
        ),
      );
      // Indoor kale waters every 3 days: Oct 7 + 3 is Saturday, and
      // Saturday's free block starts at 08:00.
      expect(find.text(_satMorning), findsOneWidget);
    });

    testWidgets('a never-watered planting is due now, in the next free block', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text(_wedEvening), findsOneWidget);
    });

    testWidgets('a foliage plant has no progress ring', (tester) async {
      await _pump(tester, plantId: 'pothos', startMethod: 'cutting');
      expect(find.byType(GrowthRing), findsNothing);
      expect(find.text('Grows year-round'), findsOneWidget);
      expect(find.text('Growing · Day 6'), findsOneWidget);
    });
  });

  group('GD-02 actions', () {
    testWidgets('offers Water, Skip, the plant\'s tasks, and Add note', (
      tester,
    ) async {
      await _pump(tester);
      for (final label in ['Water', 'Skip', 'Fertilize', 'Add note']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      // Kale has no prune task, and six days in it is not ready to harvest.
      expect(find.text('Prune'), findsNothing);
      expect(find.text('Harvest'), findsNothing);
    });

    testWidgets('Harvest appears once the planting is mature (#30)', (
      tester,
    ) async {
      // Transplanted kale matures at 50 days.
      await _pump(tester, plantedOn: DateTime(2026, 8, 1));
      expect(find.text('Harvest'), findsOneWidget);
    });

    testWidgets('a bloom plant has no Harvest action', (tester) async {
      await _pump(tester, plantId: 'english-lavender', nickname: 'Lavender');
      expect(find.text('Prune'), findsOneWidget);
      expect(find.text('Harvest'), findsNothing);
      expect(find.text('MARK HARVESTED'), findsNothing);
    });

    testWidgets('Water logs a water event and updates the next-water chip', (
      tester,
    ) async {
      final (db, _) = await _pump(tester);
      expect(find.text(_wedEvening), findsOneWidget);

      await _tapAction(tester, 'Water');
      await _afterTap(tester);
      expect(find.text('Logged: watered'), findsOneWidget);
      await settleDrift(tester);

      final events = await _events(tester, db);
      expect(events, hasLength(1));
      expect(events.single.plantingId, _kaleId);
      expect(events.single.type, CareEventType.water);
      expect(events.single.at, gardenNow);
      // Watered Wednesday Oct 7; every 3 days is Saturday.
      expect(find.text(_satMorning), findsOneWidget);
      expect(find.text(_wedEvening), findsNothing);
      expect(find.text('Watered'), findsOneWidget);
      expect(find.text('Today · 9:00 AM'), findsOneWidget);
    });

    testWidgets('Skip logs skip_water and resets the water clock', (
      tester,
    ) async {
      final (db, _) = await _pump(tester);

      await _tapAction(tester, 'Skip');
      await _afterTap(tester);
      expect(find.text('Logged: skipped watering'), findsOneWidget);
      await settleDrift(tester);

      expect((await _events(tester, db)).single.type, CareEventType.skipWater);
      expect(find.text('Skipped watering'), findsOneWidget);
      expect(find.text(_satMorning), findsOneWidget);
    });

    for (final (label, type, done) in [
      ('Fertilize', CareEventType.fertilize, 'fertilized'),
      ('Harvest', CareEventType.harvest, 'harvested'),
    ]) {
      testWidgets('$label logs a ${type.name} event', (tester) async {
        final (db, _) = await _pump(tester, plantedOn: DateTime(2026, 8, 1));

        await _tapAction(tester, label);
        await _afterTap(tester);
        expect(find.text('Logged: $done'), findsOneWidget);
        await settleDrift(tester);

        expect((await _events(tester, db)).single.type, type);
      });
    }

    testWidgets('Prune logs a prune event', (tester) async {
      final (db, _) = await _pump(
        tester,
        plantId: 'english-lavender',
        nickname: 'Lavender',
      );
      await _tapAction(tester, 'Prune');
      await _afterTap(tester);
      expect(find.text('Logged: pruned'), findsOneWidget);
      await settleDrift(tester);
      expect((await _events(tester, db)).single.type, CareEventType.prune);
    });

    testWidgets('a failed write says so and logs nothing', (tester) async {
      final db = openGardenDb();
      await tester.runAsync(() async {
        await seedSpace(db);
        await seedProfile(db);
        await seedPlanting(db, plantedOn: _plantedSixDaysAgo);
      });
      await pumpGarden(
        tester,
        db,
        location: '/garden/planting/$_kaleId',
        height: 3000,
        extra: [
          gardenRepositoryProvider.overrideWithValue(_FailingRepository(db)),
        ],
      );

      await _tapAction(tester, 'Water');
      await _afterTap(tester);

      expect(find.text("Couldn't save that. Try again."), findsOneWidget);
      expect(await _events(tester, db), isEmpty);
    });
  });

  group('GD-02 upcoming tasks', () {
    testWidgets('rows show CR-01\'s slot and mark done from the row', (
      tester,
    ) async {
      final (db, _) = await _pump(tester);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Water Greenie'), findsOneWidget);
      // Due on planting day, Oct 1: overdue, in the next free block.
      expect(find.text('OVERDUE · WED, OCT 7 · 6:00 PM'), findsOneWidget);
      expect(find.text('Overdue · 6 days'), findsOneWidget);

      await _markDone(tester, 'Water Greenie');
      await _afterTap(tester);
      await settleDrift(tester);

      expect((await _events(tester, db)).single.type, CareEventType.water);
      expect(find.text('Overdue · 6 days'), findsNothing);
      expect(find.text('SAT, OCT 10 · 8:00 AM'), findsOneWidget);
    });

    testWidgets('a note task logs a note with the task\'s own text', (
      tester,
    ) async {
      final db = openGardenDb();
      await tester.runAsync(() async {
        await seedSpace(db);
        await seedProfile(db);
        await seedPlanting(db, plantedOn: _plantedSixDaysAgo);
      });
      const check = 'Check for aphids';
      final aphids = Plant.fromJson({
        ...rawKale(),
        'care': {
          'dailyMinutes': 1,
          'weeklyMinutes': 1,
          'tasks': [
            {'type': 'other', 'everyDays': 3, 'note': check},
          ],
        },
      });
      await pumpGarden(
        tester,
        db,
        location: '/garden/planting/$_kaleId',
        height: 3000,
        extra: [
          catalogProvider.overrideWith((ref) async => [aphids]),
        ],
      );

      expect(find.text(check), findsWidgets);
      await _markDone(tester, check);
      await _afterTap(tester);
      await settleDrift(tester);

      final e = (await _events(tester, db)).single;
      expect(e.type, CareEventType.note);
      expect(e.note, check);
    });
  });

  group('GD-02 notes', () {
    testWidgets('Add note saves what was typed and shows it in the log', (
      tester,
    ) async {
      final (db, _) = await _pump(tester);

      await _tapAction(tester, 'Add note');
      await tester.pumpAndSettle();
      expect(find.text('Add a note'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'New leaves coming in!');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await _afterTap(tester);
      await settleDrift(tester);

      final e = (await _events(tester, db)).single;
      expect(e.type, CareEventType.note);
      expect(e.note, 'New leaves coming in!');
      expect(find.text('“New leaves coming in!”'), findsOneWidget);
    });

    testWidgets('the Add note button in the log opens the same dialog', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('ADD NOTE'));
      await tester.pumpAndSettle();
      expect(find.text('Add a note'), findsOneWidget);
    });

    testWidgets('Cancel or a blank note logs nothing', (tester) async {
      final (db, _) = await _pump(tester);

      await _tapAction(tester, 'Add note');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await _tapAction(tester, 'Add note');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await _afterTap(tester);

      expect(await _events(tester, db), isEmpty);
    });
  });

  group('GD-02 care log', () {
    testWidgets('lists events newest first, then the planting itself', (
      tester,
    ) async {
      await _pump(
        tester,
        seed: (db) async {
          await seedCare(
            db,
            _kaleId,
            CareEventType.water,
            DateTime(2026, 10, 2, 8),
          );
          await seedCare(
            db,
            _kaleId,
            CareEventType.fertilize,
            DateTime(2026, 10, 5, 8),
          );
          await seedCare(
            db,
            _kaleId,
            CareEventType.skipWater,
            DateTime(2026, 10, 6, 8),
          );
        },
      );

      double y(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(y('Skipped watering'), lessThan(y('Fertilized')));
      expect(y('Fertilized'), lessThan(y('Watered')));
      expect(y('Watered'), lessThan(y('Planted on the balcony')));
      // Each row shows its date and time (#30).
      expect(find.text('Tue, Oct 6 · 8:00 AM'), findsOneWidget);
      expect(find.text('Mon, Oct 5 · 8:00 AM'), findsOneWidget);
      expect(find.text('Fri, Oct 2 · 8:00 AM'), findsOneWidget);
      expect(find.text('Thu, Oct 1'), findsOneWidget); // planting row
    });

    testWidgets('shows only this planting\'s events', (tester) async {
      await _pump(
        tester,
        seed: (db) async {
          await seedPlanting(db, id: 'p2', nickname: 'Other');
          await seedCare(
            db,
            'p2',
            CareEventType.prune,
            DateTime(2026, 10, 5, 8),
          );
        },
      );
      expect(find.text('Pruned'), findsNothing);
    });

    testWidgets('a planting with no planted date has an empty log', (
      tester,
    ) async {
      await _pump(tester, planted: false, status: PlantingStatus.planned);
      expect(find.text('Nothing logged yet.'), findsOneWidget);
    });
  });

  group('GD-02 harvested and removed', () {
    testWidgets('Mark harvested logs one harvest and shows the harvested '
        'state in place (#30)', (tester) async {
      final (db, router) = await _pump(tester);

      await tester.tap(find.text('MARK HARVESTED'));
      await _afterTap(tester);
      await settleDrift(tester);

      expect((await _row(tester, db)).status, PlantingStatus.harvested);
      final events = await _events(tester, db);
      expect(events.single.type, CareEventType.harvest);
      expect(locationOf(router).path, '/garden/planting/$_kaleId');
      expect(find.text('Harvested'), findsWidgets);
      expect(find.text('Water'), findsNothing);
      expect(find.text('MARK HARVESTED'), findsNothing);
      expect(find.text('REMOVE'), findsOneWidget);
    });

    testWidgets('a harvested planting has no actions or ring', (tester) async {
      await _pump(tester, status: PlantingStatus.harvested);

      expect(find.text('Harvested'), findsOneWidget);
      expect(find.byType(GrowthRing), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Upcoming'), findsNothing);
      expect(find.text('MARK HARVESTED'), findsNothing);
      expect(find.text('ADD NOTE'), findsNothing);
      expect(find.text('REMOVE'), findsOneWidget);
    });

    testWidgets('Remove asks first, and Cancel keeps the planting', (
      tester,
    ) async {
      final (db, router) = await _pump(tester);

      await tester.tap(find.text('REMOVE'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Greenie?'), findsOneWidget);
      expect(
        find.text('It leaves your garden and its reminders stop.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect((await _row(tester, db)).status, PlantingStatus.active);
      expect(locationOf(router).path, '/garden/planting/$_kaleId');
    });

    testWidgets('confirming Remove leaves the garden but keeps the log', (
      tester,
    ) async {
      final (db, router) = await _pump(
        tester,
        seed: (db) => seedCare(
          db,
          _kaleId,
          CareEventType.water,
          DateTime(2026, 10, 6, 8),
        ),
      );

      await tester.tap(find.text('REMOVE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await settleDrift(tester);

      expect((await _row(tester, db)).status, PlantingStatus.removed);
      expect(await _events(tester, db), hasLength(1));
      expect(locationOf(router).path, '/garden');
      expect(
        find.text('Your garden is empty — pick a first plant'),
        findsOneWidget,
      );
    });
  });

  group('GD-02 without a planting', () {
    testWidgets('an unknown id says the plant is gone and Back goes home', (
      tester,
    ) async {
      final (_, router) = await _pump(tester, id: 'nope');

      expect(
        find.text("This plant isn't in your garden anymore."),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Back'));
      await settleDrift(tester);
      expect(locationOf(router).path, '/garden');
    });

    testWidgets('a planted-date-less planned planting still opens', (
      tester,
    ) async {
      await _pump(tester, planted: false, status: PlantingStatus.planned);

      expect(find.text('Greenie'), findsNWidgets(2));
      expect(find.byType(GrowthRing), findsNothing);
      expect(find.textContaining('Next water'), findsNothing);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('Back pops to GD-01 when opened from the garden', (
      tester,
    ) async {
      final (_, router) = await _pump(tester, id: _kaleId);
      router.go('/garden');
      await settleDrift(tester);
      await tester.tap(find.text('Greenie'));
      await settleDrift(tester);
      expect(locationOf(router).path, '/garden/planting/$_kaleId');

      await tester.tap(find.byTooltip('Back'));
      await settleDrift(tester);
      expect(locationOf(router).path, '/garden');
    });
  });

  group('quickActionsFor', () {
    test('water and skip need a water need; note is always there', () {
      final raw = rawKale()..remove('water');
      expect(quickActionsFor(Plant.fromJson(raw), progress: 1), [
        CareEventType.fertilize,
        CareEventType.harvest,
        CareEventType.note,
      ]);
    });

    test('order follows the GD-02 frame', () {
      expect(quickActionsFor(kale, progress: 1), [
        CareEventType.water,
        CareEventType.skipWater,
        CareEventType.fertilize,
        CareEventType.harvest,
        CareEventType.note,
      ]);
    });

    test('harvest appears only at progress 1 (#30)', () {
      expect(
        quickActionsFor(kale, progress: 0.99),
        isNot(contains(CareEventType.harvest)),
      );
      expect(
        quickActionsFor(kale, progress: 1),
        contains(CareEventType.harvest),
      );
    });
  });

  group('GD-02 recompute hook (#30)', () {
    for (final (name, act) in <(String, Future<void> Function(WidgetTester))>[
      ('Water', (t) => _tapAction(t, 'Water')),
      ('Skip', (t) => _tapAction(t, 'Skip')),
      ('Fertilize', (t) => _tapAction(t, 'Fertilize')),
      ('Mark done', (t) => _markDone(t, 'Water Greenie')),
      ('Mark harvested', (t) => t.tap(find.text('MARK HARVESTED'))),
    ]) {
      testWidgets('$name writes one event and recomputes once', (tester) async {
        var recomputes = 0;
        late AppDatabase db;
        (db, _) = await _pump(
          tester,
          extra: [
            plantingActionsProvider.overrideWith(
              (ref) => PlantingActions(
                ref.watch(gardenRepositoryProvider),
                () => recomputes++,
              ),
            ),
          ],
        );
        await act(tester);
        await _afterTap(tester);
        await settleDrift(tester);
        expect(await _events(tester, db), hasLength(1));
        expect(recomputes, 1);
      });
    }

    testWidgets('Remove writes no event and recomputes once', (tester) async {
      var recomputes = 0;
      final (db, _) = await _pump(
        tester,
        extra: [
          plantingActionsProvider.overrideWith(
            (ref) => PlantingActions(
              ref.watch(gardenRepositoryProvider),
              () => recomputes++,
            ),
          ),
        ],
      );
      await tester.tap(find.text('REMOVE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await settleDrift(tester);
      expect(await _events(tester, db), isEmpty);
      expect((await _row(tester, db)).status, PlantingStatus.removed);
      expect(recomputes, 1);
    });
  });
}
