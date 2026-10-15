import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';

const _labels = ['Location', 'Space', 'Goals', 'Time', 'Source'];

Future<void> _pump(WidgetTester tester, int current) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 328,
        child: GeauxStepProgress(labels: _labels, current: current),
      ),
    ),
  ),
);

Color _dotColor(WidgetTester tester, String label) {
  final box = tester.widget<Container>(find.byKey(ValueKey('step-dot-$label')));
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('shows one labeled dot per step', (tester) async {
    await _pump(tester, 0);
    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
      expect(find.byKey(ValueKey('step-dot-$label')), findsOneWidget);
    }
  });

  testWidgets('done, active and upcoming dots use their tokens', (
    tester,
  ) async {
    await _pump(tester, 2);
    expect(_dotColor(tester, 'Location'), AppColors.leaf500);
    expect(_dotColor(tester, 'Space'), AppColors.leaf500);
    expect(_dotColor(tester, 'Goals'), AppColors.leaf700);
    expect(_dotColor(tester, 'Time'), AppColors.stone200);
    expect(_dotColor(tester, 'Source'), AppColors.stone200);
    expect(
      tester.getSize(find.byKey(const ValueKey('step-dot-Goals'))).width,
      greaterThan(
        tester.getSize(find.byKey(const ValueKey('step-dot-Time'))).width,
      ),
    );
  });

  testWidgets('announces the current step', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, 3);
    expect(find.bySemanticsLabel('Step 4 of 5: Time'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('fits five labels at 360 wide without overflow', (tester) async {
    await _pump(tester, 4);
    expect(tester.takeException(), isNull);
  });
}
