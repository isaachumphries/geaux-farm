import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/recommendations/application/recommendations_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/presentation/recommendations_screen.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_card.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fixed_climate.dart';
import '../helpers/in_memory_database.dart';
import 'fixtures/baton_rouge.dart';
import 'fixtures/scored.dart';

// RC-01 (plan/04 § Filters): one chip at a time, ANDed with a
// case-insensitive substring search on the common or scientific name, in
// recommendationsProvider order.

/// The three synthetic plants from the issue table, in provider order.
ScoredPlant _plant({
  required String commonName,
  required String scientificName,
  required String category,
  required List<String> purposes,
  required bool indoorOk,
  required int weeklyMinutes,
}) {
  final raw = rawKale();
  return scored(
    kaleWith({
      'id': commonName.toLowerCase().replaceAll(' ', '-'),
      'commonName': commonName,
      'scientificName': scientificName,
      'category': category,
      'purposes': purposes,
      'space': {
        ...(raw['space'] as Map<String, dynamic>),
        'indoorOk': indoorOk,
      },
      'care': {
        ...(raw['care'] as Map<String, dynamic>),
        'weeklyMinutes': weeklyMinutes,
      },
    }),
  );
}

final _herb = _plant(
  commonName: 'Sweet Basil',
  scientificName: 'Ocimum basilicum',
  category: 'herb',
  purposes: ['food'],
  indoorOk: false,
  weeklyMinutes: 15,
);
final _flower = _plant(
  commonName: 'English Lavender',
  scientificName: 'Lavandula angustifolia',
  category: 'flower',
  purposes: [],
  indoorOk: true,
  weeklyMinutes: 40,
);
final _shrub = _plant(
  commonName: 'Blueberry',
  scientificName: 'Vaccinium corymbosum',
  category: 'shrub',
  purposes: [],
  indoorOk: false,
  weeklyMinutes: 16,
);

final _all = [_herb, _flower, _shrub];

/// The common names of the cards on screen, top to bottom.
List<String> _cardNames(WidgetTester tester) => [
  for (final card in tester.widgetList<PlantCard>(find.byType(PlantCard)))
    card.plant.plant.commonName,
];

Future<void> _pump(
  WidgetTester tester, {
  AsyncValue<List<ScoredPlant>> recs = const AsyncData([]),
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/home/recommendations',
    routes: [
      GoRoute(
        path: '/home/recommendations',
        builder: (_, _) => const RecommendationsScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const Text('Home stub')),
      GoRoute(
        path: '/plants/:plantId',
        builder: (_, state) =>
            Text('PD-01 stub: ${state.pathParameters['plantId']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inMemoryDatabaseOverride(),
        recommendationsProvider.overrideWithValue(recs),
        climateProvider.overrideWith(FixedClimate.new),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(defaultUserProfile),
        ),
        primarySpaceProvider.overrideWith((ref) => Stream.value(defaultSpace)),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  // One frame for the profile streams, one for the climate future.
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpAll(WidgetTester tester) =>
    _pump(tester, recs: AsyncData(_all));

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  testWidgets('All is selected on open and the list keeps provider order', (
    tester,
  ) async {
    await _pumpAll(tester);

    expect(_cardNames(tester), [
      'Sweet Basil',
      'English Lavender',
      'Blueberry',
    ]);
    for (final label in const [
      'All',
      'Food',
      'Herbs',
      'Flowers',
      'Shrubs',
      'Indoor',
      'Low maintenance',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('the chips appear in the plan order', (tester) async {
    await _pumpAll(tester);

    final labels = [
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(SingleChildScrollView).first,
          matching: find.byType(Text),
        ),
      ))
        text.data,
    ];
    expect(labels, [
      'All',
      'Food',
      'Herbs',
      'Flowers',
      'Shrubs',
      'Indoor',
      'Low maintenance',
    ]);
  });

  group('each chip keeps only the plants its rule allows', () {
    const cases = <(String, List<String>)>[
      ('Food', ['Sweet Basil']),
      ('Herbs', ['Sweet Basil']),
      ('Flowers', ['English Lavender']),
      ('Shrubs', ['Blueberry']),
      ('Indoor', ['English Lavender']),
      // 15 min is Low; 16 and 40 are not.
      ('Low maintenance', ['Sweet Basil']),
    ];
    for (final (chip, expected) in cases) {
      testWidgets('$chip → ${expected.join(', ')}', (tester) async {
        await _pumpAll(tester);
        await _tapChip(tester, chip);

        expect(_cardNames(tester), expected);
      });
    }
  });

  testWidgets('selecting a second chip replaces the first', (tester) async {
    await _pumpAll(tester);
    await _tapChip(tester, 'Flowers');
    expect(_cardNames(tester), ['English Lavender']);

    await _tapChip(tester, 'Herbs');

    expect(_cardNames(tester), ['Sweet Basil']);
  });

  group('search matches either name, case-insensitively', () {
    const cases = <(String, List<String>)>[
      ('basil', ['Sweet Basil']),
      ('LAVANDULA', ['English Lavender']),
      ('BLUE', ['Blueberry']),
    ];
    for (final (query, expected) in cases) {
      testWidgets('"$query" → ${expected.join(', ')}', (tester) async {
        await _pumpAll(tester);
        await _type(tester, query);

        expect(_cardNames(tester), expected);
      });
    }
  });

  testWidgets('the chip is ANDed with the search text', (tester) async {
    await _pumpAll(tester);
    await _tapChip(tester, 'Herbs');
    await _type(tester, 'lavandula');

    expect(find.byType(PlantCard), findsNothing);
    expect(find.text(recommendationsEmptyCopy), findsOneWidget);
  });

  testWidgets('a search with no matches shows the empty state', (tester) async {
    await _pumpAll(tester);
    await _type(tester, 'zzz');

    expect(find.byType(PlantCard), findsNothing);
    expect(find.text(recommendationsEmptyCopy), findsOneWidget);
  });

  testWidgets('loading recommendations show a spinner and no cards', (
    tester,
  ) async {
    await _pump(tester, recs: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PlantCard), findsNothing);
  });

  testWidgets('a list card fills the width', (tester) async {
    await _pumpAll(tester);

    // The cards are the list variant from #68. Its height is content
    // driven (247 here), not the 112 plan/01 § Components specifies; see
    // the note on #71.
    final card = tester.widgetList<PlantCard>(find.byType(PlantCard)).first;
    expect(card.size, PlantCardSize.list);
    expect(
      tester.getSize(find.byType(PlantCard).first).width,
      360 - 2 * AppSpacing.screenPadding,
    );
  });

  testWidgets('exactly one chip reads as selected', (tester) async {
    await _pumpAll(tester);
    bool chipSelected(String label) =>
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .selected ??
        false;
    List<String> selectedChips() => [
      for (final chip in const [
        'All',
        'Food',
        'Herbs',
        'Flowers',
        'Shrubs',
        'Indoor',
        'Low maintenance',
      ])
        if (chipSelected(chip)) chip,
    ];
    expect(selectedChips(), ['All']);

    await _tapChip(tester, 'Flowers');

    expect(selectedChips(), ['Flowers']);
  });

  testWidgets('tapping a card opens PD-01 for that plant', (tester) async {
    await _pumpAll(tester);

    await tester.tap(find.text('Sweet Basil'));
    await tester.pumpAndSettle();

    expect(find.text('PD-01 stub: sweet-basil'), findsOneWidget);
  });

  testWidgets('the header reads "Plants for you"', (tester) async {
    await _pumpAll(tester);

    expect(find.text('Plants for you'), findsOneWidget);
  });

  testWidgets('the count line counts the plants shown', (tester) async {
    await _pumpAll(tester);
    expect(find.text('3 plants · sorted by best fit'), findsOneWidget);

    await _tapChip(tester, 'Herbs');

    expect(find.text('1 plant · sorted by best fit'), findsOneWidget);
  });

  testWidgets('Back goes to Home when there is nothing to pop', (tester) async {
    await _pumpAll(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Home stub'), findsOneWidget);
  });
}
