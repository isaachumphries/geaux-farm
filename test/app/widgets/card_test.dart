import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('onTap fires once per tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(GeauxCard(onTap: () => taps++, child: const Text('Kale'))),
    );

    await tester.tap(find.text('Kale'));

    expect(taps, 1);
  });

  testWidgets('a card without onTap is not tappable', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const GeauxCard(child: Text('Kale'))));

    expect(
      find.descendant(
        of: find.byType(GeauxCard),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.text('Kale')),
      isNot(isSemantics(hasTapAction: true)),
    );
    handle.dispose();
  });

  testWidgets('pressing sinks the face without changing the height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Center(
          child: GeauxCard(onTap: () {}, child: const Text('Kale')),
        ),
      ),
    );
    final restTop = tester.getTopLeft(find.text('Kale')).dy;
    final height = tester.getSize(find.byType(GeauxCard)).height;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Kale')),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Kale')).dy, restTop + 2);
    expect(tester.getSize(find.byType(GeauxCard)).height, height);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Kale')).dy, restTop);
  });
}
