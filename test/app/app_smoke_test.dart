import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';

void main() {
  testWidgets('empty shell shows the app name once', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GeauxFarmApp()));

    expect(tester.takeException(), isNull);
    expect(find.text('Geaux Farm'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });
}
