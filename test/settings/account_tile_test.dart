import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:geaux_farm/features/community/presentation/sign_in_sheet.dart';
import 'package:geaux_farm/features/settings/presentation/widgets/account_tile.dart';

import '../community/fake_auth_repository.dart';

const _isaac = AuthUser(
  id: 'u1',
  email: 'isaac@example.com',
  username: 'isaac',
);

void main() {
  Future<void> pump(WidgetTester tester, FakeAuthRepository repo) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AccountTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out: shows Sign in and no Sign out', (tester) async {
    await pump(tester, FakeAuthRepository());
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsNothing);
  });

  testWidgets('signed out: tapping the row opens the CM-04 sheet', (
    tester,
  ) async {
    await pump(tester, FakeAuthRepository());
    await tester.tap(find.byType(AccountTile));
    await tester.pumpAndSettle();

    final sheet = tester.widget<SignInSheet>(find.byType(SignInSheet));
    expect(sheet.reason, SignInAction.account);
    expect(find.text(SignInSheet.subtitle), findsOneWidget);
  });

  testWidgets('a session without a username still offers Sign in', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'isaac@example.com'),
    );
    await pump(tester, repo);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsNothing);
  });

  testWidgets('signed in: names the user and offers Sign out', (tester) async {
    await pump(tester, FakeAuthRepository(user: _isaac));
    expect(find.text('@isaac'), findsOneWidget);
    expect(find.text('isaac@example.com'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('Sign out clears the session and shows the signed-out state', (
    tester,
  ) async {
    final repo = FakeAuthRepository(user: _isaac);
    await pump(tester, repo);

    await tester.tap(find.text('SIGN OUT'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['signOut']);
    expect(repo.user, isNull);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('@isaac'), findsNothing);
    expect(find.byType(SignInSheet), findsNothing);
  });
}
