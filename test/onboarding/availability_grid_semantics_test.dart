import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/domain/availability_edits.dart';
import 'package:geaux_farm/features/onboarding/presentation/widgets/availability_grid.dart';

void main() {
  group('availabilityCellLabel', () {
    test('says the meridiem once when both ends share it', () {
      expect(
        availabilityCellLabel(0, 6, selected: true),
        'Monday 6–8 PM, selected',
      );
      expect(
        availabilityCellLabel(6, 0, selected: false),
        'Sunday 6–8 AM, not selected',
      );
    });

    test('names both ends across noon', () {
      expect(
        availabilityCellLabel(2, 2, selected: false),
        'Wednesday 10 AM–12 PM, not selected',
      );
      expect(
        availabilityCellLabel(2, 3, selected: false),
        'Wednesday 12–2 PM, not selected',
      );
    });

    test('every block matches its row label and runs two hours', () {
      final ranges = [
        for (var b = 0; b < availabilityBlocks; b++)
          availabilityCellLabel(
            0,
            b,
            selected: false,
          ).replaceFirst('Monday ', '').replaceFirst(', not selected', ''),
      ];
      expect(ranges, [
        '6–8 AM',
        '8–10 AM',
        '10 AM–12 PM',
        '12–2 PM',
        '2–4 PM',
        '4–6 PM',
        '6–8 PM',
        '8–10 PM',
      ]);
      for (var b = 0; b < availabilityBlocks; b++) {
        expect(ranges[b], startsWith(blockLabels[b].split(' ').first));
      }
    });

    test('names each day in full, Monday first', () {
      expect(
        [
          for (var d = 0; d < availabilityDays; d++)
            availabilityCellLabel(d, 0, selected: false).split(' ').first,
        ],
        [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ],
      );
    });
  });

  group('AvailabilityGrid semantics', () {
    late List<int> value;

    Future<void> pump(WidgetTester tester, List<int> initial) async {
      value = initial;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AvailabilityGrid(
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('all 56 cells carry a day, block and state label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, setBlock(List.filled(7, 0), 0, 6, true));

      for (var d = 0; d < availabilityDays; d++) {
        for (var b = 0; b < availabilityBlocks; b++) {
          final selected = d == 0 && b == 6;
          final label = availabilityCellLabel(d, b, selected: selected);
          expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
        }
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday 6–8 PM, selected')),
        isSemantics(isButton: true, isSelected: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('a screen-reader tap toggles that one cell', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, List.filled(7, 0));

      tester.semantics.tap(
        find.semantics.byLabel('Tuesday 8–10 AM, not selected'),
      );
      await tester.pump();

      expect(value, setBlock(List.filled(7, 0), 1, 1, true));
      expect(
        find.bySemanticsLabel('Tuesday 8–10 AM, selected'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('cells stay 44 tall at 360 wide with no overflow', (
      tester,
    ) async {
      await pump(tester, List.filled(7, 0));
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byKey(const ValueKey('cell-0-0')));
      // Cell plus its 2 px gap padding; the only plan/01 touch-target
      // exception.
      expect(size.height, AvailabilityGrid.cellHeight + AvailabilityGrid.gap);
      expect(size.width, lessThanOrEqualTo(AvailabilityGrid.cellWidth + 2));
    });
  });
}
