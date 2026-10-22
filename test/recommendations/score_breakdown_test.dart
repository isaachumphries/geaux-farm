import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/score_reasons.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/score_breakdown.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'fixtures/baton_rouge.dart';

const _sample = <ScoreRow>[
  ScoreRow(
    factor: ScoreFactor.climate,
    fit: 0.8,
    reason: "Hardy in zones 5a–8b; you're in 8b",
  ),
  ScoreRow(
    factor: ScoreFactor.light,
    fit: 0.5,
    reason: 'Needs full sun; your spot gets partial sun',
  ),
  ScoreRow(
    factor: ScoreFactor.space,
    fit: 1,
    reason: 'Needs ~2 sq ft; you have 32 sq ft',
  ),
  ScoreRow(
    factor: ScoreFactor.care,
    fit: 1,
    reason: 'Water every ~3 days; you have 4 care days',
  ),
  ScoreRow(
    factor: ScoreFactor.goals,
    fit: 0.3,
    reason: 'Not one of your goals',
  ),
  ScoreRow(
    factor: ScoreFactor.experience,
    fit: 0.5,
    reason: 'Difficulty: Moderate',
  ),
];

List<ScoreRow> _rowsFor(String plantId) {
  final plant = loadReferencePlants()[plantId]!;
  return scoreRows(
    plant: plant,
    ctx: workedExample,
    setup: GrowSetup.outdoor,
    compat: scorePlant(
      plant,
      workedExample,
      GrowSetup.outdoor,
      workedExampleDate,
    ),
  );
}

Future<void> _pump(WidgetTester tester, List<ScoreRow> rows) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: ScoreBreakdown(rows: rows)),
    ),
  );
}

Finder _fills() => find.descendant(
  of: find.byType(ScoreBreakdown),
  matching: find.byType(FractionallySizedBox),
);

void main() {
  testWidgets('shows each factor label with its rounded percent', (
    tester,
  ) async {
    await _pump(tester, _sample);

    for (final label in const [
      'Climate',
      'Light',
      'Space',
      'Care time',
      'Your goals',
      'Experience',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('50%'), findsNWidgets(2));
    expect(find.text('100%'), findsNWidgets(2));
    expect(find.text('30%'), findsOneWidget);
  });

  testWidgets('shows each reason under its bar', (tester) async {
    await _pump(tester, _sample);

    for (final row in _sample) {
      expect(find.text(row.reason), findsOneWidget);
    }
  });

  testWidgets('sizes each bar fill to its fit', (tester) async {
    await _pump(tester, _sample);

    expect(_fills(), findsNWidgets(_sample.length));
    for (var i = 0; i < _sample.length; i++) {
      expect(
        tester.widget<FractionallySizedBox>(_fills().at(i)).widthFactor,
        _sample[i].fit,
      );
    }
  });

  testWidgets('clamps bar fill to the 0 to 1 range', (tester) async {
    await _pump(tester, const [
      ScoreRow(factor: ScoreFactor.climate, fit: 1.4, reason: 'over'),
      ScoreRow(factor: ScoreFactor.light, fit: -0.2, reason: 'under'),
    ]);

    expect(
      tester.widget<FractionallySizedBox>(_fills().at(0)).widthFactor,
      1.0,
    );
    expect(
      tester.widget<FractionallySizedBox>(_fills().at(1)).widthFactor,
      0.0,
    );
  });

  testWidgets('uses one icon per factor', (tester) async {
    await _pump(tester, _sample);

    expect(find.byIcon(Symbols.thermostat_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.light_mode_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.straighten_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.schedule_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.restaurant_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.school_rounded), findsOneWidget);
  });

  testWidgets('renders the reference lavender breakdown', (tester) async {
    await _pump(tester, _rowsFor('english-lavender'));

    expect(find.text('80%'), findsOneWidget);
    expect(find.text('50%'), findsNWidgets(2));
    expect(find.text('100%'), findsNWidgets(2));
    expect(find.text('30%'), findsOneWidget);
  });

  testWidgets('renders every bar full for sweet basil', (tester) async {
    await _pump(tester, _rowsFor('sweet-basil'));

    expect(find.text('100%'), findsNWidgets(6));
  });

  group('worked example fixtures (plan/04)', () {
    int total(String id) => scorePlant(
      loadReferencePlants()[id]!,
      workedExample,
      GrowSetup.outdoor,
      workedExampleDate,
    ).score;

    test('english-lavender bars are 80/50/100/100/30/50 and total 74', () {
      expect(_rowsFor('english-lavender').map((r) => r.percent), [
        80,
        50,
        100,
        100,
        30,
        50,
      ]);
      expect(total('english-lavender'), 74);
    });

    test('sweet-basil earns all six bars in full and totals 100', () {
      expect(_rowsFor('sweet-basil').map((r) => r.percent), everyElement(100));
      expect(total('sweet-basil'), 100);
    });
  });
}
