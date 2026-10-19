import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_card.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/season_chip.dart';

import 'fixtures/baton_rouge.dart';
import 'fixtures/scored.dart';

Future<void> _pump(
  WidgetTester tester,
  ScoredPlant plant, {
  PlantCardState state = PlantCardState.defaultState,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Align(
      alignment: Alignment.topLeft,
      child: PlantCard(plant: plant, state: state),
    ),
  ),
);

Map<String, dynamic> _care(int daily, int weekly) => {
  ...(rawKale()['care'] as Map<String, dynamic>),
  'dailyMinutes': daily,
  'weeklyMinutes': weekly,
};

Map<String, dynamic> _start(int min, int max) => {
  'starts': [
    {'method': 'seed', 'daysMin': min, 'daysMax': max},
  ],
};

void main() {
  group('care line', () {
    testWidgets('no daily care reads "Daily —"', (tester) async {
      await _pump(tester, scored(kaleWith({'care': _care(0, 20)})));
      expect(find.text('Daily — · Weekly ~20m'), findsOneWidget);
    });

    testWidgets('daily minutes read "Daily ~{d}m"', (tester) async {
      await _pump(tester, scored(kaleWith({'care': _care(5, 20)})));
      expect(find.text('Daily ~5m · Weekly ~20m'), findsOneWidget);
    });
  });

  for (final (weekly, label) in [
    (15, 'Low care'),
    (16, 'Medium care'),
    (40, 'Medium care'),
    (41, 'High care'),
  ]) {
    testWidgets('weeklyMinutes $weekly → $label', (tester) async {
      await _pump(tester, scored(kaleWith({'care': _care(2, weekly)})));
      expect(find.text(label), findsOneWidget);
    });
  }

  for (final (changes, label) in [
    ({..._start(60, 75), 'maturityKind': 'harvest'}, 'Harvest in 60–75 days'),
    ({..._start(90, 120), 'maturityKind': 'bloom'}, 'Blooms in 90–120 days'),
    (
      {..._start(200, 365), 'maturityKind': 'establish'},
      'Settles in over ~13 months',
    ),
    ({'maturityKind': 'foliage'}, 'Grows year-round'),
  ]) {
    testWidgets('time to grow: $label', (tester) async {
      await _pump(tester, scored(kaleWith(changes)));
      expect(find.text(label), findsOneWidget);
    });
  }

  testWidgets('"Plant now" shows only in the inSeason state', (tester) async {
    final kale = scored(kaleWith({}));
    await _pump(tester, kale, state: PlantCardState.inSeason);
    expect(find.text('PLANT NOW'), findsOneWidget);
    expect(find.text('Indoor / greenhouse'), findsNothing);

    await _pump(tester, kale);
    expect(find.text('PLANT NOW'), findsNothing);
  });

  testWidgets('"Indoor / greenhouse" shows only in the indoorOnly state', (
    tester,
  ) async {
    final kale = scored(kaleWith({}));
    await _pump(tester, kale, state: PlantCardState.indoorOnly);
    expect(find.text('Indoor / greenhouse'), findsOneWidget);
    expect(find.text('PLANT NOW'), findsNothing);

    await _pump(tester, kale);
    expect(find.text('Indoor / greenhouse'), findsNothing);
  });

  testWidgets('shows at most two season chips from the plant tags', (
    tester,
  ) async {
    final plant = scored(
      kaleWith({
        'seasonTags': ['cool-season', 'warm-season', 'year-round'],
      }),
    );
    await _pump(tester, plant);
    expect(find.byType(SeasonChip), findsNWidgets(2));
    expect(find.text('Cool-season'), findsOneWidget);
    expect(find.text('Warm-season'), findsOneWidget);
    expect(find.text('Year-round'), findsNothing);
  });

  testWidgets('no season chips when the plant has no season tags', (
    tester,
  ) async {
    await _pump(tester, scored(kaleWith({'seasonTags': <String>[]})));
    expect(find.byType(SeasonChip), findsNothing);
  });

  group('PlantCardState.of', () {
    final kale = kaleWith({});
    PlantCardState of(
      GrowSetup setup, {
      required bool inSeason,
      required bool viable,
    }) => PlantCardState.of(
      scored(kale, inSeason: inSeason, outdoorViable: viable).compatibility,
      setup,
    );

    test('outdoor and not viable outdoors → indoorOnly, even in season', () {
      expect(
        of(GrowSetup.outdoor, inSeason: true, viable: false),
        PlantCardState.indoorOnly,
      );
    });

    test('in season and viable → inSeason; out of season → default', () {
      expect(
        of(GrowSetup.outdoor, inSeason: true, viable: true),
        PlantCardState.inSeason,
      );
      expect(
        of(GrowSetup.outdoor, inSeason: false, viable: true),
        PlantCardState.defaultState,
      );
    });

    test('indoor lists never show the indoor chip', () {
      expect(
        of(GrowSetup.indoor, inSeason: true, viable: false),
        PlantCardState.inSeason,
      );
    });
  });

  testWidgets('compact card is 160 wide and grows with a two-line name', (
    tester,
  ) async {
    await _pump(tester, scored(kaleWith({'commonName': 'Kale'})));
    final short = tester.getSize(find.byType(PlantCard));

    await _pump(
      tester,
      scored(kaleWith({'commonName': 'Kale Kale Kale Kale Kale Kale'})),
    );
    final long = tester.getSize(find.byType(PlantCard));

    expect(short.width, plantCardCompactWidth);
    expect(long.width, plantCardCompactWidth);
    expect(long.height, greaterThan(short.height));
  });

  testWidgets('the longest badge and the indoor chip fit without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      scored(
        kaleWith({'commonName': 'A very long plant name that wraps twice'}),
        score: 45,
      ),
      state: PlantCardState.indoorOnly,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('45 · Possible with care'), findsOneWidget);
  });
}
