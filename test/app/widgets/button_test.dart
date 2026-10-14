import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';

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
}
