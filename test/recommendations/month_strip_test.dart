import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/month_strip.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

Future<void> _pump(
  WidgetTester tester, {
  required Set<int> inSeason,
  required int current,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: MonthStrip(inSeasonMonths: inSeason, currentMonth: current),
    ),
  ),
);

/// The cell decoration of month [month] (1 = January).
BoxDecoration _cell(WidgetTester tester, int month) {
  final cells = find.descendant(
    of: find.byType(MonthStrip),
    matching: find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          _months.any((m) => w.properties.label?.startsWith(m) ?? false),
    ),
  );
  expect(cells, findsNWidgets(12));
  final box = find.descendant(
    of: cells.at(month - 1),
    matching: find.byType(DecoratedBox),
  );
  return tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
}

bool _filled(BoxDecoration d) => d.color == AppColors.geauxGold;

bool _marked(BoxDecoration d) =>
    (d.border! as Border).top.color == AppColors.soil900;

void main() {
  testWidgets('fills exactly the in-season months', (tester) async {
    const inSeason = {3, 4, 5, 10};
    await _pump(tester, inSeason: inSeason, current: 1);
    for (var m = 1; m <= 12; m++) {
      expect(_filled(_cell(tester, m)), inSeason.contains(m), reason: '$m');
    }
  });

  testWidgets('an empty set fills no cell', (tester) async {
    await _pump(tester, inSeason: const {}, current: 6);
    for (var m = 1; m <= 12; m++) {
      expect(_filled(_cell(tester, m)), isFalse, reason: '$m');
    }
  });

  testWidgets('marks only the current month, filled or not', (tester) async {
    await _pump(tester, inSeason: const {4}, current: 4);
    for (var m = 1; m <= 12; m++) {
      expect(_marked(_cell(tester, m)), m == 4, reason: '$m');
    }
    await _pump(tester, inSeason: const {4}, current: 9);
    for (var m = 1; m <= 12; m++) {
      expect(_marked(_cell(tester, m)), m == 9, reason: '$m');
    }
    expect(_filled(_cell(tester, 9)), isFalse);
  });

  testWidgets('cells read January to December', (tester) async {
    await _pump(tester, inSeason: const {}, current: 1);
    final letters = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(MonthStrip),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .take(12);
    expect(letters.join(), 'JFMAMJJASOND');
  });
}
