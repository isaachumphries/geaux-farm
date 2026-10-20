import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/season_chip.dart';

Future<void> _pump(WidgetTester tester, SeasonTag tag, {double? width}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: width,
            child: SeasonChip(tag: tag),
          ),
        ),
      ),
    );

void main() {
  const labels = {
    SeasonTag.coolSeason: 'Cool-season',
    SeasonTag.warmSeason: 'Warm-season',
    SeasonTag.yearRound: 'Year-round',
    SeasonTag.evergreen: 'Evergreen',
    SeasonTag.deciduous: 'Deciduous',
    SeasonTag.perennial: 'Perennial',
    SeasonTag.winterInterest: 'Winter interest',
  };

  test('every SeasonTag has a label', () {
    expect(labels.keys.toSet(), SeasonTag.values.toSet());
  });

  for (final entry in labels.entries) {
    testWidgets('${entry.key.name} reads "${entry.value}"', (tester) async {
      await _pump(tester, entry.key);

      expect(find.text(entry.value), findsOneWidget);
    });
  }

  testWidgets('outline uses the leaf500 border at the chip radius', (
    tester,
  ) async {
    await _pump(tester, SeasonTag.yearRound);

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SeasonChip),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    final border = decoration.border as Border;

    expect(border.top.color, AppColors.leaf500);
    expect(border.top.width, AppBorders.width);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadii.chip));
  });

  testWidgets('a narrow slot ellipsizes the label without overflow', (
    tester,
  ) async {
    await _pump(tester, SeasonTag.winterInterest, width: 90);

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text('Winter interest'));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
