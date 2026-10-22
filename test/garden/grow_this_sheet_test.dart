import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/data/garden_repository.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/garden/application/grow_setup_controller.dart';
import 'package:geaux_farm/features/garden/presentation/grow_this_sheet.dart';
import 'package:geaux_farm/features/garden/presentation/planting_added_screen.dart';
import 'package:geaux_farm/features/recommendations/domain/compat_level.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/compat_badge.dart';
import 'package:go_router/go_router.dart';

import '../helpers/persisted_app_harness.dart' show settleDrift;
import '../recommendations/fixtures/scored.dart';
import 'garden_harness.dart';

class _FailingRepository extends GardenRepository {
  _FailingRepository(super.db) : super(now: () => gardenNow);

  @override
  Future<String> addPlanting({
    required Plant plant,
    required String spaceId,
    required String nickname,
    required GrowSetup setup,
    required bool inContainer,
    required StartMethod startMethod,
    required DateTime plantedOn,
  }) => Future.error(StateError('disk full'));
}

/// Opens PD-02 for [plant] over a database holding one space.
Future<(AppDatabase, GoRouter)> _openSheet(
  WidgetTester tester, {
  SpaceType space = SpaceType.balcony,
  bool inContainerDefault = true,
  ScoredPlant? plant,
  List<Override> Function(AppDatabase db)? extra,
}) async {
  final db = openGardenDb();
  await tester.runAsync(
    () => seedSpace(db, type: space, inContainerDefault: inContainerDefault),
  );
  final router = await pumpGarden(
    tester,
    db,
    location: '/',
    plantToGrow: plant ?? scored(kaleWith({}), score: 82),
    extra: extra?.call(db) ?? const [],
  );
  await tester.tap(find.text('Grow it'));
  await tester.pumpAndSettle();
  return (db, router);
}

GrowSetup _setup(WidgetTester tester) => tester
    .widget<GeauxSegmentedChoice<GrowSetup>>(
      find.byType(GeauxSegmentedChoice<GrowSetup>),
    )
    .selected;

bool _inContainer(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch)).value;

/// The selected start method, read from the cards' semantics.
Finder _selectedStart(String title) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.selected == true,
  description: 'selected $title',
);

Future<List<PlantingRow>> _plantings(
  WidgetTester tester,
  AppDatabase db,
) async => (await tester.runAsync(() => db.select(db.plantingsTable).get()))!;

Future<void> _tapAdd(WidgetTester tester) async {
  await tester.tap(find.text('ADD TO MY GARDEN'));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('PD-02 defaults', () {
    testWidgets('a balcony defaults to Outdoors, in a container', (
      tester,
    ) async {
      await _openSheet(tester, space: SpaceType.balcony);
      expect(find.text('Grow Kale'), findsOneWidget);
      expect(_setup(tester), GrowSetup.outdoor);
      expect(_inContainer(tester), isTrue);
    });

    testWidgets('a windowsill defaults to Indoors, in a container', (
      tester,
    ) async {
      await _openSheet(tester, space: SpaceType.windowsill);
      expect(_setup(tester), GrowSetup.indoor);
      expect(_inContainer(tester), isTrue);
    });

    testWidgets('a yard bed defaults to Outdoors, in the ground', (
      tester,
    ) async {
      await _openSheet(
        tester,
        space: SpaceType.smallYard,
        inContainerDefault: false,
      );
      expect(_setup(tester), GrowSetup.outdoor);
      expect(_inContainer(tester), isFalse);
    });

    testWidgets('the first start method is selected, the date is today', (
      tester,
    ) async {
      await _openSheet(tester);

      expect(find.text('Transplant'), findsOneWidget);
      expect(find.text('Harvest in 50–65 days'), findsOneWidget);
      expect(find.text('Seed'), findsOneWidget);
      expect(find.text('Harvest in 55–75 days'), findsOneWidget);
      expect(_selectedStart('Transplant'), findsWidgets);
      expect(find.text('Today, Oct 7'), findsOneWidget);
    });

    testWidgets('shows the plant\'s fit badge', (tester) async {
      await _openSheet(tester);
      expect(find.byType(CompatBadge), findsOneWidget);
    });

    testWidgets('the container card names the pot size the plant needs', (
      tester,
    ) async {
      await _openSheet(tester);
      expect(find.text('3+ gallon pot recommended'), findsOneWidget);
    });

    testWidgets('a plant that is fine in a pot with no size says so', (
      tester,
    ) async {
      final plant = kaleWith({
        'space': {'sqFtPerPlant': 2, 'containerOk': true, 'indoorOk': false},
      });
      await _openSheet(tester, plant: scored(plant));
      expect(find.text('Grows fine in a pot'), findsOneWidget);
    });

    testWidgets('a plant that cannot be potted locks the toggle off', (
      tester,
    ) async {
      final plant = kaleWith({
        'space': {'sqFtPerPlant': 2, 'containerOk': false, 'indoorOk': false},
      });
      await _openSheet(tester, plant: scored(plant));

      expect(find.text('Best grown in the ground'), findsOneWidget);
      expect(_inContainer(tester), isFalse);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });
  });

  group('PD-02 adding', () {
    testWidgets(
      'Add to my garden writes an active planting from the defaults',
      (tester) async {
        final (db, router) = await _openSheet(tester);

        await _tapAdd(tester);
        await settleDrift(tester);
        expect(find.byType(PlantingAddedScreen), findsOneWidget);
        expect(find.text('Kale is in your garden!'), findsOneWidget);

        final rows = await _plantings(tester, db);
        expect(rows, hasLength(1));
        final r = rows.single;
        expect(r.plantId, 'kale');
        expect(r.spaceId, 's1');
        expect(r.nickname, 'Kale');
        expect(r.setup, GrowSetup.outdoor);
        expect(r.inContainer, isTrue);
        expect(r.startMethod, 'transplant');
        expect(r.plantedOn, DateTime(2026, 10, 7));
        expect(r.status, PlantingStatus.active);

        // PD-03 → HM-02 (plan/01 § PD-03 prototype).
        await tester.tap(find.text('NOT NOW'));
        await settleDrift(tester);
        expect(find.byType(PlantingAddedScreen), findsNothing);
        expect(locationOf(router).path, '/home');
      },
    );

    testWidgets('PD-03 names the planting by its nickname', (tester) async {
      await _openSheet(tester);
      await tester.enterText(find.byType(TextField), 'Big Kale');
      await tester.pump();
      await _tapAdd(tester);
      await settleDrift(tester);
      expect(find.text('Big Kale is in your garden!'), findsOneWidget);
    });

    testWidgets('records the setup, container, start, and nickname chosen', (
      tester,
    ) async {
      final (db, _) = await _openSheet(tester);

      await tester.tap(find.text('Greenhouse'));
      await tester.pump();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Seed'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Big Kale');
      await tester.pump();
      await _tapAdd(tester);
      await settleDrift(tester);

      final r = (await _plantings(tester, db)).single;
      expect(r.setup, GrowSetup.greenhouse);
      expect(r.inContainer, isFalse);
      expect(r.startMethod, 'seed');
      expect(r.nickname, 'Big Kale');
    });

    testWidgets('Indoors is a choice on an outdoor space', (tester) async {
      final (db, _) = await _openSheet(tester);
      await tester.tap(find.text('Indoors'));
      await tester.pump();
      expect(_setup(tester), GrowSetup.indoor);
      await _tapAdd(tester);
      await settleDrift(tester);
      expect((await _plantings(tester, db)).single.setup, GrowSetup.indoor);
    });

    testWidgets('a failed add keeps the sheet open and says so', (
      tester,
    ) async {
      final (db, _) = await _openSheet(
        tester,
        extra: (db) => [
          gardenRepositoryProvider.overrideWithValue(_FailingRepository(db)),
        ],
      );

      await _tapAdd(tester);

      expect(find.text("Couldn't add it. Try again."), findsOneWidget);
      expect(find.text('Grow Kale'), findsOneWidget);
      expect(await _plantings(tester, db), isEmpty);
      // The button is live again for a retry.
      final add = tester.widget<GeauxButton>(find.byType(GeauxButton));
      expect(add.onPressed, isNotNull);
    });

    testWidgets('a plant with no start methods cannot be added', (
      tester,
    ) async {
      final plant = kaleWith({'starts': <Map<String, dynamic>>[]});
      await _openSheet(tester, plant: scored(plant));

      expect(find.text('How are you starting it?'), findsNothing);
      final add = tester.widget<GeauxButton>(find.byType(GeauxButton));
      expect(add.onPressed, isNull);
    });
  });

  group('PD-02 planted date', () {
    testWidgets('picks an earlier day and labels it without "Today"', (
      tester,
    ) async {
      final (db, _) = await _openSheet(tester);

      await tester.tap(find.text('Today, Oct 7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Oct 3'), findsOneWidget);

      await _tapAdd(tester);
      await settleDrift(tester);
      expect(
        (await _plantings(tester, db)).single.plantedOn,
        DateTime(2026, 10, 3),
      );
    });

    testWidgets('the picker offers only today−365 through today', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.tap(find.text('Today, Oct 7'));
      await tester.pumpAndSettle();

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.firstDate, DateTime(2025, 10, 7));
      expect(picker.lastDate, DateTime(2026, 10, 7));
    });

    testWidgets('a day after today cannot be picked', (tester) async {
      await _openSheet(tester);

      await tester.tap(find.text('Today, Oct 7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Today, Oct 7'), findsOneWidget);
    });

    testWidgets('the earliest day is the same date a year ago', (tester) async {
      final (db, _) = await _openSheet(tester);

      await tester.tap(find.text('Today, Oct 7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();
      // Oct 6, 2025 is a day too early, so the tap does nothing.
      await tester.tap(find.text('6'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Oct 7'), findsOneWidget);

      await _tapAdd(tester);
      await settleDrift(tester);
      expect(
        (await _plantings(tester, db)).single.plantedOn,
        DateTime(2025, 10, 7),
      );
    });

    testWidgets('cancelling the picker keeps the date', (tester) async {
      await _openSheet(tester);

      await tester.tap(find.text('Today, Oct 7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Today, Oct 7'), findsOneWidget);
    });
  });

  group('PD-02 setup', () {
    Compatibility compat(int score) => Compatibility(
      score: score,
      level: compatLevelFor(score),
      fits: const {},
      inSeason: true,
      outdoorViable: false,
      monthStrip: List.filled(12, true),
    );
    // Scores by setup, so the badge shows which setup was scored.
    final scores = {
      GrowSetup.outdoor: compat(31),
      GrowSetup.indoor: compat(64),
      GrowSetup.greenhouse: compat(88),
    };
    List<Override> fakeScorer(AppDatabase db) => [
      growScorerProvider.overrideWithValue(
        (plant, setup) async => scores[setup]!,
      ),
    ];
    int badge(WidgetTester tester) =>
        tester.widget<CompatBadge>(find.byType(CompatBadge)).score;
    const warning =
        'This plant struggles outdoors in Baton Rouge. '
        'Indoors or a greenhouse gives it a better shot.';

    testWidgets('switching setup shows the new score on the badge', (
      tester,
    ) async {
      await _openSheet(
        tester,
        plant: scored(kaleWith({}), score: 31, outdoorViable: false),
        extra: fakeScorer,
      );
      expect(badge(tester), 31);

      await tester.tap(find.text('Indoors'));
      await tester.pumpAndSettle();
      expect(badge(tester), 64);
      await tester.tap(find.text('Greenhouse'));
      await tester.pumpAndSettle();
      expect(badge(tester), 88);
    });

    testWidgets('Outdoors on a plant that struggles outdoors warns', (
      tester,
    ) async {
      await _openSheet(
        tester,
        plant: scored(kaleWith({}), outdoorViable: false),
        extra: fakeScorer,
      );
      expect(_setup(tester), GrowSetup.outdoor);
      expect(find.text(warning), findsOneWidget);
      // Non-blocking: the plant can still be added.
      final add = tester.widget<GeauxButton>(find.byType(GeauxButton));
      expect(add.onPressed, isNotNull);

      await tester.tap(find.text('Indoors'));
      await tester.pumpAndSettle();
      expect(find.text(warning), findsNothing);
    });

    testWidgets('Indoors on a windowsill never warns', (tester) async {
      await _openSheet(
        tester,
        space: SpaceType.windowsill,
        plant: scored(kaleWith({}), outdoorViable: false),
        extra: fakeScorer,
      );
      expect(_setup(tester), GrowSetup.indoor);
      expect(find.text(warning), findsNothing);
    });

    testWidgets('an outdoor-viable plant never warns', (tester) async {
      await _openSheet(tester);
      expect(_setup(tester), GrowSetup.outdoor);
      expect(find.textContaining('struggles outdoors'), findsNothing);
    });

    testWidgets('shows the plan copy for the toggle and the date helper', (
      tester,
    ) async {
      await _openSheet(tester);
      expect(find.text('In a pot or container'), findsOneWidget);
      expect(
        find.text('Already growing it? Set the date you planted.'),
        findsOneWidget,
      );
    });
  });

  group('labels', () {
    test('time to grow follows the maturity kind', () {
      const start = PlantStart(
        method: StartMethod.seed,
        daysMin: 10,
        daysMax: 20,
      );
      Plant of(String kind) => kaleWith({'maturityKind': kind});
      expect(startTimeLabel(of('harvest'), start), 'Harvest in 10–20 days');
      expect(startTimeLabel(of('bloom'), start), 'Blooms in 10–20 days');
      expect(
        startTimeLabel(of('establish'), start),
        'Settles in over 10–20 days',
      );
      expect(startTimeLabel(of('foliage'), start), 'Grows year-round');
    });

    test('start methods', () {
      expect(startMethodLabel(StartMethod.seed), 'Seed');
      expect(startMethodLabel(StartMethod.transplant), 'Transplant');
      expect(startMethodLabel(StartMethod.cutting), 'Cutting');
    });

    test('outdoor warning names the city', () {
      expect(
        outdoorWarningCopy('Baton Rouge'),
        'This plant struggles outdoors in Baton Rouge. '
        'Indoors or a greenhouse gives it a better shot.',
      );
    });

    test('planted date says Today only for today', () {
      final today = DateTime(2026, 10, 7);
      expect(
        plantedDateLabel(DateTime(2026, 10, 7, 15), today),
        'Today, Oct 7',
      );
      expect(plantedDateLabel(DateTime(2026, 10, 5), today), 'Oct 5');
    });
  });
}
