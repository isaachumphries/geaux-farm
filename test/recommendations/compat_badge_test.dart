import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/compat_badge.dart';

Future<void> _pump(WidgetTester tester, int score) => tester.pumpWidget(
  MaterialApp(
    home: Center(child: CompatBadge(score: score)),
  ),
);

/// Fill of the badge's pill.
Color? _fill(WidgetTester tester) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(CompatBadge),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color;

void main() {
  const cases = [
    (100, 'Great fit', AppColors.great),
    (80, 'Great fit', AppColors.great),
    (79, 'Good fit', AppColors.good),
    (60, 'Good fit', AppColors.good),
    (59, 'Possible with care', AppColors.possible),
    (40, 'Possible with care', AppColors.possible),
    (39, 'Tough here', AppColors.indoor),
    (0, 'Tough here', AppColors.indoor),
  ];
  for (final (score, label, color) in cases) {
    testWidgets('$score reads "$score · $label" in its band color', (
      tester,
    ) async {
      await _pump(tester, score);

      expect(find.text('$score · $label'), findsOneWidget);
      expect(_fill(tester), color);
    });
  }

  testWidgets('text keeps 4.5:1 contrast on every fill', (tester) async {
    for (final (score, _, _) in cases) {
      await _pump(tester, score);
      final fill = _fill(tester)!;
      final ink = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(CompatBadge),
              matching: find.byType(Text),
            ),
          )
          .style!
          .color!;
      final (hi, lo) = (fill.computeLuminance() > ink.computeLuminance()
          ? (fill.computeLuminance(), ink.computeLuminance())
          : (ink.computeLuminance(), fill.computeLuminance()));
      expect(
        (hi + 0.05) / (lo + 0.05),
        greaterThanOrEqualTo(4.5),
        reason: 'score $score',
      );
    }
  });
}
