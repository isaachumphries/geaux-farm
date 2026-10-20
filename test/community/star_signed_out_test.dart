import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:geaux_farm/features/community/presentation/sign_in_sheet.dart';

import '../helpers/community_fixtures.dart';
import 'fake_auth_repository.dart';
import 'guide_detail_harness.dart';

void main() {
  final guide = testGuide('g1', stars: 5);

  testWidgets('a signed-out tap opens CM-04 and writes nothing', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(tester, repo, auth: FakeAuthRepository());

    await tester.tap(find.text('Star'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInSheet), findsOneWidget);
    expect(find.text('Sign in to star guides'), findsOneWidget);
    expect(repo.writes, isEmpty);
    // The pill did not move.
    expect(find.text('Star'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('dismissing the sheet leaves the guide unstarred', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(tester, repo, auth: FakeAuthRepository());
    await tester.tap(find.text('Star'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('NOT NOW'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInSheet), findsNothing);
    expect(repo.writes, isEmpty);
    expect(find.text('Star'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('signed in without a username: the sheet opens, no write', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'isaac@example.com'),
    );
    await pumpGuideDetail(tester, repo, auth: auth);

    await tester.tap(find.text('Star'));
    await tester.pumpAndSettle();

    expect(find.text('Pick a username'), findsOneWidget);
    expect(repo.writes, isEmpty);
    await unmount(tester);
  });

  testWidgets('signing in from the star tap stars the guide once', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    final auth = FakeAuthRepository()..verifiedHasProfile = true;
    await pumpGuideDetail(tester, repo, auth: auth);

    await tester.tap(find.text('Star'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'isaac@example.com');
    await tester.pump();
    await tester.tap(find.text('SEND CODE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '481926');
    await tester.pump();
    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInSheet), findsNothing);
    expect(repo.writes, ['star:g1']);
    expect(find.text('Starred'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('signing in shows a star you already gave, and stars nothing', (
    tester,
  ) async {
    // The guide looked unstarred while signed out; signing in reveals that
    // this account starred it on another device. The tap meant "starred".
    final repo = FakeGuideRepository(guides: {'g1': guide});
    final auth = FakeAuthRepository()..verifiedHasProfile = true;
    await pumpGuideDetail(tester, repo, auth: auth);

    await tester.tap(find.text('Star'));
    await tester.pumpAndSettle();
    repo.starred.add('g1');
    await tester.enterText(find.byType(TextField), 'isaac@example.com');
    await tester.pump();
    await tester.tap(find.text('SEND CODE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '481926');
    await tester.pump();
    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();

    expect(repo.writes, isEmpty);
    expect(find.text('Starred'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('signing in after a new account made a profile stars once', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    final auth = FakeAuthRepository();
    await pumpGuideDetail(tester, repo, auth: auth);

    await tester.tap(find.text('Star'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'isaac@example.com');
    await tester.pump();
    await tester.tap(find.text('SEND CODE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '481926');
    await tester.pump();
    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();
    // New account: the username step comes before the star.
    expect(find.text('Pick a username'), findsOneWidget);
    expect(repo.writes, isEmpty);
    await tester.enterText(find.byType(TextField), 'isaac');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(repo.writes, ['star:g1']);
    expect(find.text('Starred'), findsOneWidget);
    await unmount(tester);
  });
}
