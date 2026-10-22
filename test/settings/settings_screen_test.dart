import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:geaux_farm/features/settings/presentation/settings_screen.dart';
import 'package:geaux_farm/features/weather/presentation/attribution_footer.dart';

import '../community/fake_auth_repository.dart';
import '../helpers/in_memory_database.dart';

void main() {
  late List<Uri> opened;

  Future<void> pump(WidgetTester tester, {AuthUser? user}) async {
    // ST-01 checked at the narrow Android size (AGENTS.md, plan/01).
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    opened = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inMemoryDatabaseOverride(),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: user),
          ),
          linkOpenerProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('rows run Units, Care reminders, Account, About at 360 wide', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.takeException(), isNull);

    final order = [
      'PREFERENCES',
      'Units',
      'Care reminders',
      'ACCOUNT',
      'Sign in',
      'ABOUT',
      'Weather data by Open-Meteo.com (CC BY 4.0)',
      'Hardiness zones: phzmapi.org / USDA',
    ];
    for (var i = 1; i < order.length; i++) {
      expect(
        top(tester, order[i]),
        greaterThan(top(tester, order[i - 1])),
        reason: '${order[i]} should sit below ${order[i - 1]}',
      );
    }
    await tearDownTree(tester);
  });

  testWidgets('signed out shows Sign in; signed in shows Sign out', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsNothing);
    await tearDownTree(tester);

    await pump(
      tester,
      user: const AuthUser(id: 'u1', email: 'a@example.com', username: 'ana'),
    );
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    await tearDownTree(tester);
  });

  testWidgets('About shows both attribution strings exactly', (tester) async {
    await pump(tester);
    expect(
      find.text('Weather data by Open-Meteo.com (CC BY 4.0)'),
      findsOneWidget,
    );
    expect(find.text('Hardiness zones: phzmapi.org / USDA'), findsOneWidget);
    await tearDownTree(tester);
  });

  testWidgets('tapping the Open-Meteo credit opens open-meteo.com', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Weather data by Open-Meteo.com (CC BY 4.0)'));
    await tester.pump();
    expect(opened, [Uri.parse('https://open-meteo.com/')]);

    await tester.tap(find.text('Hardiness zones: phzmapi.org / USDA'));
    await tester.pump();
    expect(opened, hasLength(1));
    await tearDownTree(tester);
  });
}
