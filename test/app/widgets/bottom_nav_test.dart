import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';

const _tabs = [
  GeauxNavItem(icon: Icons.home, label: 'Home'),
  GeauxNavItem(icon: Icons.yard, label: 'Garden'),
  GeauxNavItem(icon: Icons.event, label: 'Care'),
  GeauxNavItem(icon: Icons.group, label: 'Community'),
  GeauxNavItem(icon: Icons.place, label: 'Local'),
];

Widget _host(List<GeauxNavItem> items, int current, ValueChanged<int> onTap) =>
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: GeauxBottomNav(
          items: items,
          currentIndex: current,
          onTap: onTap,
        ),
      ),
    );

void main() {
  testWidgets('tapping a tab reports its index', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(_host(_tabs.sublist(0, 4), 0, taps.add));

    await tester.tap(find.text('Community'));
    await tester.tap(find.text('Garden'));
    await tester.tap(find.text('Home'));

    expect(taps, [3, 1, 0]);
  });

  testWidgets('the 5-tab variant reports the Local index', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(_host(_tabs, 2, taps.add));

    await tester.tap(find.text('Local'));

    expect(taps, [4]);
  });

  test('3 or 6 items assert', () {
    expect(
      () => GeauxBottomNav(
        items: _tabs.sublist(0, 3),
        currentIndex: 0,
        onTap: (_) {},
      ),
      throwsAssertionError,
    );
    expect(
      () => GeauxBottomNav(
        items: [..._tabs, _tabs.first],
        currentIndex: 0,
        onTap: (_) {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('only the current tab is selected in semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_tabs.sublist(0, 4), 2, (_) {}));

    expect(
      tester.getSemantics(find.text('Care')),
      isSemantics(label: 'Care', isSelected: true, isButton: true),
    );
    for (final other in ['Home', 'Garden', 'Community']) {
      expect(
        tester.getSemantics(find.text(other)),
        isSemantics(label: other, isSelected: false),
      );
    }
    handle.dispose();
  });

  testWidgets('every tab is at least 48x48', (tester) async {
    await tester.pumpWidget(_host(_tabs, 0, (_) {}));

    for (final item in _tabs) {
      final size = tester.getSize(
        find
            .ancestor(
              of: find.text(item.label),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}
