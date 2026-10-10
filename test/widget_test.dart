import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geaux_farm/main.dart';

void main() {
  Future<void> openQuestions(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Add garden'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('Answering every question adds the garden to the home page', (
    tester,
  ) async {
    await openQuestions(tester);

    expect(find.text('Where do you want to grow?'), findsOneWidget);
    await tapText(tester, 'Balcony');
    await tapText(tester, 'CONTINUE');

    expect(find.text('How much sun does it get?'), findsOneWidget);
    await tapText(tester, 'Full sun');
    await tapText(tester, 'CONTINUE');

    expect(find.text('How much space do you have?'), findsOneWidget);
    await tapText(tester, 'Small');
    await tapText(tester, 'CONTINUE');

    await tapText(tester, 'Basil');
    await tapText(tester, 'Tomatoes');
    await tapText(tester, 'Okra');
    await tapText(tester, 'Okra');
    await tapText(tester, 'CONTINUE');

    await tester.enterText(find.byKey(const Key('gardenName')), 'Back Yard');
    await tester.pump();
    await tapText(tester, 'FINISH');

    expect(find.text('FINISH'), findsNothing);
    expect(find.text('Back Yard'), findsOneWidget);
    expect(
      find.text('Balcony · Full sun · Small\nGrowing: Tomatoes, Basil'),
      findsOneWidget,
    );
  });

  testWidgets('Cannot continue without answering', (tester) async {
    await openQuestions(tester);

    await tapText(tester, 'CONTINUE');
    expect(find.text('Where do you want to grow?'), findsOneWidget);

    await tapText(tester, 'Patio');
    await tapText(tester, 'CONTINUE');
    await tapText(tester, 'Shade');
    await tapText(tester, 'CONTINUE');
    await tapText(tester, 'Large');
    await tapText(tester, 'CONTINUE');

    await tapText(tester, 'CONTINUE');
    expect(find.text('Mint'), findsOneWidget);

    await tapText(tester, 'Mint');
    await tapText(tester, 'CONTINUE');
    await tester.enterText(find.byKey(const Key('gardenName')), '   ');
    await tester.pump();
    await tapText(tester, 'FINISH');
    expect(find.text('FINISH'), findsOneWidget);
  });

  testWidgets('Back returns to the previous question and keeps the answer', (
    tester,
  ) async {
    await openQuestions(tester);

    await tapText(tester, 'Indoors');
    await tapText(tester, 'CONTINUE');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Where do you want to grow?'), findsOneWidget);
    await tapText(tester, 'CONTINUE');
    expect(find.text('How much sun does it get?'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(
      find.text('No gardens yet. Tap "Add garden" to submit one.'),
      findsOneWidget,
    );
  });
}
