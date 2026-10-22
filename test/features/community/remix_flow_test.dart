import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/presentation/guide_detail_screen.dart';
import 'package:geaux_farm/features/community/presentation/sign_in_sheet.dart';

import '../../helpers/community_fixtures.dart';
import '../../community/fake_auth_repository.dart';
import '../../community/guide_detail_harness.dart';

// plan/07 § Remix through the real CM-02 wiring: sign-in first, one draft
// insert, then the editor on the new id.

Future<void> _tapRemix(WidgetTester tester) async {
  await tester.tap(find.text('Remix'));
  await tester.pumpAndSettle();
}

void main() {
  final guide = testGuide('g1', title: 'Fall greens for Louisiana');

  testWidgets('signed in: one insert, then the editor on the new id', (
    tester,
  ) async {
    final repo = FakeGuideRepository(
      guides: {'g1': guide},
      newGuideId: 'remix-1',
    );
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireRemix: true,
    );

    await _tapRemix(tester);

    expect(repo.remixInserts, hasLength(1));
    expect(repo.remixInserts.single['forked_from'], 'g1');
    expect(repo.remixInserts.single['status'], 'draft');
    expect(
      repo.remixInserts.single['title'],
      'Remix of Fall greens for Louisiana',
    );
    expect(find.text('editor remix-1'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('signed out: CM-04 opens and nothing is inserted', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(),
      wireRemix: true,
    );

    await _tapRemix(tester);

    expect(find.byType(SignInSheet), findsOneWidget);
    expect(find.text('Sign in to remix guides'), findsOneWidget);
    expect(repo.remixInserts, isEmpty);
    // The editor stub reads "editor <id>": no push happened.
    expect(find.textContaining('editor '), findsNothing);
    await unmount(tester);
  });

  testWidgets('insert failure: stays on CM-02 with the guide unchanged', (
    tester,
  ) async {
    final repo = FakeGuideRepository(
      guides: {'g1': guide},
      writeError: Exception('offline'),
    );
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireRemix: true,
    );

    await _tapRemix(tester);

    expect(repo.remixInserts, hasLength(1));
    // The editor stub reads "editor <id>": no push happened.
    expect(find.textContaining('editor '), findsNothing);
    expect(find.byType(GuideDetailScreen), findsOneWidget);
    expect(find.text('Fall greens for Louisiana'), findsOneWidget);
    await unmount(tester);
  });
}
