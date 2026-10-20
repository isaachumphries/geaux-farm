import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/domain/auth_repository.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:geaux_farm/features/community/presentation/sign_in_sheet.dart';

import 'fake_auth_repository.dart';

Future<void> pumpSheet(
  WidgetTester tester,
  FakeAuthRepository repo, {
  required VoidCallback onSignedIn,
  SignInAction reason = SignInAction.star,
}) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SignInSheet(reason: reason, onSignedIn: onSignedIn),
          ),
        ),
      ),
    ),
  );
}

Future<void> typeEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField), email);
  await tester.pump();
}

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump();
}

/// Email step through to the code step.
Future<void> reachCodeStep(WidgetTester tester) async {
  await typeEmail(tester, 'isaac@example.com');
  await tapButton(tester, 'SEND CODE');
  expect(find.text('Check your email'), findsOneWidget);
}

/// Through the code step to the username step (no profile yet).
Future<void> reachUsernameStep(WidgetTester tester) async {
  await reachCodeStep(tester);
  await tester.enterText(find.byType(TextField), '481926');
  await tester.pump();
  await tapButton(tester, 'VERIFY');
  expect(find.text('Pick a username'), findsOneWidget);
}

bool buttonEnabled(WidgetTester tester, String label) =>
    tester
        .widget<GeauxButton>(find.widgetWithText(GeauxButton, label))
        .onPressed !=
    null;

void main() {
  late FakeAuthRepository repo;
  late int signedIn;

  setUp(() {
    repo = FakeAuthRepository();
    signedIn = 0;
  });

  testWidgets('sign-in blocks tab navigation until dismissed', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    var switchedTab = false;
    late Future<bool> result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: switchedTab
                  ? const Text('Other tab opened')
                  : Navigator(
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (context) => Center(
                          child: TextButton(
                            onPressed: () {
                              result = showSignInSheet(context);
                            },
                            child: const Text('Open sign in'),
                          ),
                        ),
                      ),
                    ),
              bottomNavigationBar: TextButton(
                onPressed: () => setState(() => switchedTab = true),
                child: const Text('Other tab'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInSheet), findsOneWidget);

    await tester.tap(find.text('Other tab'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Other tab opened'), findsNothing);
    expect(find.byType(SignInSheet), findsOneWidget);

    await tester.tap(find.text('NOT NOW'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    await tester.tap(find.text('Other tab'));
    await tester.pumpAndSettle();
    expect(find.text('Other tab opened'), findsOneWidget);
  });

  group('happy path', () {
    testWidgets('email -> code -> username calls the repository in order', (
      tester,
    ) async {
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      expect(find.text('Sign in to star guides'), findsOneWidget);
      expect(
        find.text('We’ll email you a 6-digit code. No password needed.'),
        findsOneWidget,
      );

      await typeEmail(tester, '  Isaac@Example.com ');
      await tapButton(tester, 'SEND CODE');
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.text('Enter the 6-digit code we sent to isaac@example.com.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '481926');
      await tester.pump();
      await tapButton(tester, 'VERIFY');
      expect(find.text('Pick a username'), findsOneWidget);
      expect(signedIn, 0);

      await tester.enterText(find.byType(TextField), 'isaac_grows');
      await tester.pump();
      await tapButton(tester, 'CONTINUE');

      expect(repo.calls, [
        'sendEmailCode(isaac@example.com)',
        'verifyEmailCode(isaac@example.com, 481926)',
        'usernameAvailable(isaac_grows)',
        'createProfile(isaac_grows)',
      ]);
      expect(signedIn, 1);
    });

    testWidgets('a user who already has a profile skips the username step', (
      tester,
    ) async {
      repo.verifiedHasProfile = true;
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      await reachCodeStep(tester);
      await tester.enterText(find.byType(TextField), '481926');
      await tester.pump();
      await tapButton(tester, 'VERIFY');

      expect(find.text('Pick a username'), findsNothing);
      expect(signedIn, 1);
      expect(repo.calls.any((c) => c.startsWith('createProfile')), isFalse);
    });

    testWidgets('the title follows the action that asked', (tester) async {
      await pumpSheet(
        tester,
        repo,
        onSignedIn: () {},
        reason: SignInAction.publish,
      );
      expect(find.text('Sign in to publish guides'), findsOneWidget);
    });
  });

  group('email step', () {
    testWidgets('Send code is disabled until something is typed', (
      tester,
    ) async {
      await pumpSheet(tester, repo, onSignedIn: () {});
      expect(buttonEnabled(tester, 'SEND CODE'), isFalse);
      await typeEmail(tester, 'a');
      expect(buttonEnabled(tester, 'SEND CODE'), isTrue);
    });

    testWidgets('an invalid email shows an error and sends nothing', (
      tester,
    ) async {
      await pumpSheet(tester, repo, onSignedIn: () {});
      await typeEmail(tester, 'isaac@');
      await tapButton(tester, 'SEND CODE');

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(repo.calls, isEmpty);
      expect(find.text('Check your email'), findsNothing);

      await typeEmail(tester, 'isaac@example.com');
      expect(find.text('Enter a valid email address.'), findsNothing);
    });

    testWidgets('sending disables the button so a second tap sends nothing', (
      tester,
    ) async {
      repo.sendGate = Completer<void>();
      await pumpSheet(tester, repo, onSignedIn: () {});
      await typeEmail(tester, 'isaac@example.com');
      await tapButton(tester, 'SEND CODE');

      expect(find.text('SENDING…'), findsOneWidget);
      expect(buttonEnabled(tester, 'SENDING…'), isFalse);
      await tester.tap(find.text('SENDING…'));
      await tester.pump();
      expect(repo.calls, hasLength(1));

      repo.sendGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Check your email'), findsOneWidget);
    });

    testWidgets('offline keeps the email step and the typed email', (
      tester,
    ) async {
      repo.sendError = const NetworkException('down');
      await pumpSheet(tester, repo, onSignedIn: () {});
      await typeEmail(tester, 'isaac@example.com');
      await tapButton(tester, 'SEND CODE');

      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(find.text('isaac@example.com'), findsOneWidget);
      expect(find.text('Check your email'), findsNothing);
      expect(buttonEnabled(tester, 'SEND CODE'), isTrue);
    });

    testWidgets('a rate limit says to wait', (tester) async {
      repo.sendError = const RateLimitedException();
      await pumpSheet(tester, repo, onSignedIn: () {});
      await typeEmail(tester, 'isaac@example.com');
      await tapButton(tester, 'SEND CODE');
      expect(
        find.text('Too many tries. Wait a minute and try again.'),
        findsOneWidget,
      );
    });
  });

  group('code step', () {
    testWidgets('Verify needs all six digits and only accepts digits', (
      tester,
    ) async {
      await pumpSheet(tester, repo, onSignedIn: () {});
      await reachCodeStep(tester);
      expect(buttonEnabled(tester, 'VERIFY'), isFalse);

      await tester.enterText(find.byType(TextField), '48a19');
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('a'), findsNothing);
      expect(buttonEnabled(tester, 'VERIFY'), isFalse);

      await tester.enterText(find.byType(TextField), '4819261');
      await tester.pump();
      expect(buttonEnabled(tester, 'VERIFY'), isTrue);
      await tapButton(tester, 'VERIFY');
      expect(repo.calls.last, 'verifyEmailCode(isaac@example.com, 481926)');
    });

    testWidgets('a wrong code shows an error and keeps the email', (
      tester,
    ) async {
      repo.verifyError = const InvalidCodeException();
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      await reachCodeStep(tester);
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tapButton(tester, 'VERIFY');

      expect(
        find.text('That code didn’t work. Check it or send a new one.'),
        findsOneWidget,
      );
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.text('Enter the 6-digit code we sent to isaac@example.com.'),
        findsOneWidget,
      );
      expect(signedIn, 0);
      // The rejected digits are cleared, so Verify waits for a new code.
      expect(buttonEnabled(tester, 'VERIFY'), isFalse);

      // Typing again clears the error; a good code then signs in.
      repo.verifyError = null;
      repo.verifiedHasProfile = true;
      await tester.enterText(find.byType(TextField), '481926');
      await tester.pump();
      expect(find.textContaining('didn’t work'), findsNothing);
      await tapButton(tester, 'VERIFY');
      expect(signedIn, 1);
    });

    testWidgets('a rejected email keeps the email step and its value', (
      tester,
    ) async {
      repo.sendError = const InvalidEmailException();
      await pumpSheet(tester, repo, onSignedIn: () {});
      await typeEmail(tester, 'isaac@example.com');
      await tapButton(tester, 'SEND CODE');
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('isaac@example.com'), findsOneWidget);
    });

    testWidgets('offline on verify keeps the code step', (tester) async {
      repo.verifyError = const NetworkException('down');
      await pumpSheet(tester, repo, onSignedIn: () {});
      await reachCodeStep(tester);
      await tester.enterText(find.byType(TextField), '481926');
      await tester.pump();
      await tapButton(tester, 'VERIFY');

      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(find.text('Check your email'), findsOneWidget);
    });

    testWidgets('resend is locked for 60 s, then sends again', (tester) async {
      await pumpSheet(tester, repo, onSignedIn: () {});
      await reachCodeStep(tester);
      expect(find.text('Resend code in 1:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 18));
      expect(find.text('Resend code in 0:42'), findsOneWidget);
      expect(find.text('RESEND CODE'), findsNothing);

      await tester.pump(const Duration(seconds: 42));
      expect(find.text('RESEND CODE'), findsOneWidget);

      await tapButton(tester, 'RESEND CODE');
      expect(repo.calls, [
        'sendEmailCode(isaac@example.com)',
        'sendEmailCode(isaac@example.com)',
      ]);
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });
  });

  group('username step', () {
    testWidgets('a taken name shows the error and never creates a profile', (
      tester,
    ) async {
      repo.available = false;
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      await reachUsernameStep(tester);
      await tester.enterText(find.byType(TextField), 'isaac');
      await tester.pump();
      await tapButton(tester, 'CONTINUE');

      expect(find.text('That name is taken'), findsOneWidget);
      expect(repo.calls.any((c) => c.startsWith('createProfile')), isFalse);
      expect(find.text('Pick a username'), findsOneWidget);
      expect(signedIn, 0);
      // Same name again can't be submitted; editing it re-enables Continue.
      expect(buttonEnabled(tester, 'CONTINUE'), isFalse);
      await tester.enterText(find.byType(TextField), 'isaac2');
      await tester.pump();
      expect(find.text('That name is taken'), findsNothing);
      expect(buttonEnabled(tester, 'CONTINUE'), isTrue);
    });

    testWidgets('losing the name to a race at insert shows the same error', (
      tester,
    ) async {
      repo.createError = const UsernameTakenException();
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      await reachUsernameStep(tester);
      await tester.enterText(find.byType(TextField), 'isaac');
      await tester.pump();
      await tapButton(tester, 'CONTINUE');

      expect(find.text('That name is taken'), findsOneWidget);
      expect(signedIn, 0);
    });

    testWidgets('Continue needs 3+ characters; input is lowercased and '
        'stripped to the allowed set', (tester) async {
      await pumpSheet(tester, repo, onSignedIn: () {});
      await reachUsernameStep(tester);
      expect(
        find.text('3–20 characters: lowercase letters, numbers and _'),
        findsOneWidget,
      );
      expect(buttonEnabled(tester, 'CONTINUE'), isFalse);

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();
      expect(buttonEnabled(tester, 'CONTINUE'), isFalse);

      await tester.enterText(find.byType(TextField), 'Has Space!');
      await tester.pump();
      expect(find.text('hasspace'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'a' * 25);
      await tester.pump();
      expect(find.text('a' * 20), findsOneWidget);
    });

    testWidgets('offline on save keeps the username step', (tester) async {
      repo.availableError = const NetworkException('down');
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      await reachUsernameStep(tester);
      await tester.enterText(find.byType(TextField), 'isaac');
      await tester.pump();
      await tapButton(tester, 'CONTINUE');

      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(signedIn, 0);
    });

    testWidgets('a signed-in user who has a profile completes at once', (
      tester,
    ) async {
      repo = FakeAuthRepository(
        user: const AuthUser(
          id: 'u1',
          email: 'isaac@example.com',
          username: 'isaac',
        ),
      );
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      await tester.pump();
      expect(signedIn, 1);
    });

    testWidgets('a signed-in user with no profile opens on this step', (
      tester,
    ) async {
      repo = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'isaac@example.com'),
      );
      await pumpSheet(tester, repo, onSignedIn: () => signedIn++);
      expect(find.text('Pick a username'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });
  });

  group('requireSignIn', () {
    Future<void> pumpHost(
      WidgetTester tester,
      FakeAuthRepository repo,
      VoidCallback action,
    ) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => requireSignIn(
                    context,
                    ref,
                    reason: SignInAction.star,
                    action: action,
                  ),
                  child: const Text('star'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('signed out: opens the sheet and resumes once after '
        'sign-in', (tester) async {
      var resumed = 0;
      repo.verifiedHasProfile = true;
      await pumpHost(tester, repo, () => resumed++);
      await tester.tap(find.text('star'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to star guides'), findsOneWidget);
      expect(resumed, 0);

      await typeEmail(tester, 'isaac@example.com');
      await tapButton(tester, 'SEND CODE');
      await tester.enterText(find.byType(TextField), '481926');
      await tester.pump();
      await tapButton(tester, 'VERIFY');
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsNothing);
      expect(resumed, 1);
    });

    testWidgets('dismissing the sheet does not resume the action', (
      tester,
    ) async {
      var resumed = 0;
      await pumpHost(tester, repo, () => resumed++);
      await tester.tap(find.text('star'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NOT NOW'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to star guides'), findsNothing);
      expect(resumed, 0);
    });

    testWidgets('signed in without a profile: opens the sheet at the '
        'username step', (tester) async {
      var resumed = 0;
      repo = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'isaac@example.com'),
      );
      await pumpHost(tester, repo, () => resumed++);
      await tester.tap(find.text('star'));
      await tester.pumpAndSettle();

      expect(find.text('Pick a username'), findsOneWidget);
      expect(resumed, 0);
    });

    testWidgets('signed in with a profile: runs the action, no sheet', (
      tester,
    ) async {
      var resumed = 0;
      repo = FakeAuthRepository(
        user: const AuthUser(
          id: 'u1',
          email: 'isaac@example.com',
          username: 'isaac',
        ),
      );
      await pumpHost(tester, repo, () => resumed++);
      await tester.tap(find.text('star'));
      await tester.pumpAndSettle();

      expect(resumed, 1);
      expect(find.text('Sign in to star guides'), findsNothing);
    });
  });
}
