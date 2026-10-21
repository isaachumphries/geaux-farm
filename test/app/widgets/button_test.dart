import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  for (final variant in GeauxButtonVariant.values) {
    testWidgets('$variant fires onPressed and is at least 48x48', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          GeauxButton(label: 'Go', onPressed: () => taps++, variant: variant),
        ),
      );

      await tester.tap(find.text('GO'));

      expect(taps, 1);
      final size = tester.getSize(find.byType(GeauxButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('$variant with null onPressed is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(GeauxButton(label: 'Go', onPressed: null, variant: variant)),
      );

      await tester.tap(find.text('GO'), warnIfMissed: false);

      expect(
        tester.getSemantics(find.text('GO')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });
  }
  testWidgets('icon draws before the label and the tap still fires', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        GeauxButton(
          label: 'Go',
          icon: Symbols.add_rounded,
          onPressed: () => taps++,
        ),
      ),
    );

    final icon = tester.getCenter(find.byIcon(Symbols.add_rounded));
    final label = tester.getCenter(find.text('GO'));
    expect(icon.dx, lessThan(label.dx));
    await tester.tap(find.text('GO'));
    expect(taps, 1);
  });
}
