import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  testWidgets('shows its message and icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: GeauxEmptyState(
            message: 'Nothing here.',
            icon: Symbols.eco_rounded,
          ),
        ),
      ),
    );
    expect(find.text('Nothing here.'), findsOneWidget);
    expect(find.byIcon(Symbols.eco_rounded), findsOneWidget);
  });

  testWidgets('has a default icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: GeauxEmptyState(message: 'Empty')),
      ),
    );
    expect(find.byIcon(Symbols.task_alt_rounded), findsOneWidget);
  });
}
