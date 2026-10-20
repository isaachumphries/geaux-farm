import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/recommendations/application/recommendations_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/presentation/recommendations_screen.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_list_card.dart';
import 'package:go_router/go_router.dart';

import 'fixtures/scored.dart';

/// The #71 test table: three synthetic plants, in provider order.
Plant _synthetic({
  required String id,
  required String common,
  required String scientific,
  required String category,
  required List<String> purposes,
  required bool indoorOk,
  required int weeklyMinutes,
}) {
  final kale = kaleWith({});
  return kaleWith({
    'id': id,
    'commonName': common,
    'scientificName': scientific,
    'category': category,
    'purposes': purposes,
    'space': {'sqFtPerPlant': 2, 'containerOk': true, 'indoorOk': indoorOk},
    'care': {
      'dailyMinutes': 2,
      'weeklyMinutes': weeklyMinutes,
      'tasks': const <Map<String, dynamic>>[],
    },
    'maturityKind': kale.maturityKind.json,
  });
}

final _herb = scored(
  _synthetic(
    id: 'herb',
    common: 'Sweet Basil',
    scientific: 'Ocimum basilicum',
    category: 'herb',
    purposes: ['food'],
    indoorOk: false,
    weeklyMinutes: 15,
  ),
  score: 90,
);
final _flower = scored(
  _synthetic(
    id: 'flower',
    common: 'English Lavender',
    scientific: 'Lavandula angustifolia',
    category: 'flower',
    purposes: [],
    indoorOk: true,
    weeklyMinutes: 40,
  ),
  score: 80,
);
final _shrub = scored(
  _synthetic(
    id: 'shrub',
    common: 'Blueberry',
    scientific: 'Vaccinium corymbosum',
    category: 'shrub',
    purposes: [],
    indoorOk: false,
    weeklyMinutes: 16,
  ),
  score: 70,
);

Future<GoRouter> _pump(
  WidgetTester tester, {
  AsyncValue<List<ScoredPlant>>? recs,
}) async {
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/home/recommendations',
    routes: [
      GoRoute(
        path: '/home/recommendations',
        builder: (_, _) => const RecommendationsScreen(),
      ),
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
        recommendationsProvider.overrideWithValue(
          recs ?? AsyncData([_herb, _flower, _shrub]),
        ),
        primarySpaceProvider.overrideWith((ref) => Stream.value(defaultSpace)),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
  return router;
}

List<String> _shown(WidgetTester tester) => [
  for (final c in tester.widgetList<PlantListCard>(find.byType(PlantListCard)))
    c.plant.plant.id,
];

/// Taps a chip, dragging the horizontal chip row until it is on screen.
Future<void> _chip(WidgetTester tester, String label) async {
  final row = find.byWidgetPredicate(
    (w) => w is ListView && w.scrollDirection == Axis.horizontal,
  );
  // Back to the start first: chips scrolled off the left aren't built.
  await tester.drag(row, const Offset(2000, 0));
  await tester.pump();
  await tester.dragUntilVisible(find.text(label), row, const Offset(-80, 0));
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pump();
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  testWidgets('opens on All: every plant in provider order', (tester) async {
    await _pump(tester);
    expect(_shown(tester), ['herb', 'flower', 'shrub']);
  });

  final chipCases = {
    'Food': ['herb'],
    'Herbs': ['herb'],
    'Flowers': ['flower'],
    'Shrubs': ['shrub'],
    'Indoor': ['flower'],
  };
  for (final MapEntry(key: label, value: ids) in chipCases.entries) {
    testWidgets('$label → $ids', (tester) async {
      await _pump(tester);
      await _chip(tester, label);
      expect(_shown(tester), ids);
    });
  }

  testWidgets('one chip at a time: Flowers then Herbs → herb only', (
    tester,
  ) async {
    await _pump(tester);
    await _chip(tester, 'Flowers');
    await _chip(tester, 'Herbs');
    expect(_shown(tester), ['herb']);
  });

  final searchCases = {
    'basil': ['herb'],
    'LAVANDULA': ['flower'],
    'BLUE': ['shrub'],
  };
  for (final MapEntry(key: q, value: ids) in searchCases.entries) {
    testWidgets('search "$q" with All → $ids', (tester) async {
      await _pump(tester);
      await _search(tester, q);
      expect(_shown(tester), ids);
    });
  }

  testWidgets('loading: a spinner and no cards', (tester) async {
    await _pump(tester, recs: const AsyncLoading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PlantListCard), findsNothing);
  });
}
