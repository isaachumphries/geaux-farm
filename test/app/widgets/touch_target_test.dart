import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// plan/01 § Foundations: every interactive element is at least 48×48.
/// The AvailabilityGrid cell (40×44) is the one exception and has its own
/// test in test/onboarding/availability_grid_semantics_test.dart.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    // The plan's base frame.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );
  }

  void expectTarget(WidgetTester tester, Finder finder) {
    final size = tester.getSize(finder);
    expect(size.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
  }

  test('the minimum touch target token is 48', () {
    expect(AppSpacing.minTouchTarget, 48);
  });

  testWidgets('GeauxCircleButton is 48×48 and labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      GeauxCircleButton(
        icon: Symbols.arrow_back_rounded,
        tooltip: 'Back',
        onPressed: () {},
      ),
    );
    expectTarget(tester, find.byType(GeauxCircleButton));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Back')),
      isSemantics(label: 'Back', isButton: true),
    );
    handle.dispose();
  });

  testWidgets('each GeauxSegmentedChoice option is at least 48×48', (
    tester,
  ) async {
    await pump(
      tester,
      GeauxSegmentedChoice<int>(
        options: const [(0, 'A'), (1, 'B'), (2, 'C')],
        selected: 0,
        onSelected: (_) {},
      ),
    );
    final options = find.byType(GeauxCard);
    expect(options, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expectTarget(tester, options.at(i));
    }
  });

  testWidgets('GeauxSelectCard is at least 48×48', (tester) async {
    await pump(
      tester,
      GeauxSelectCard(title: 'Balcony', selected: false, onTap: () {}),
    );
    expectTarget(tester, find.byType(GeauxSelectCard));
  });

  testWidgets('GeauxTopBar keeps a 48×48 slot when a side is empty', (
    tester,
  ) async {
    await pump(tester, const GeauxTopBar(title: 'My Garden'));
    final slots = find.descendant(
      of: find.byType(GeauxTopBar),
      matching: find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == AppSpacing.minTouchTarget &&
            w.height == AppSpacing.minTouchTarget,
      ),
    );
    expect(slots, findsNWidgets(2));
  });
}
