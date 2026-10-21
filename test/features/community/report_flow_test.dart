import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/domain/report_reason.dart';
import 'package:geaux_farm/features/community/presentation/report_sheet.dart';
import 'package:geaux_farm/features/community/presentation/sign_in_sheet.dart';

import '../../helpers/community_fixtures.dart';
import '../../community/fake_auth_repository.dart';
import '../../community/guide_detail_harness.dart';

// plan/07 § Moderation, through the real CM-02 wiring: Report is in the
// overflow menu of a guide the user did not write, a reason is required,
// and one report per user per guide.

/// Opens the overflow menu and taps Report.
Future<void> _openReportSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Report'));
  await tester.pumpAndSettle();
}

void main() {
  final guide = testGuide('g1');

  testWidgets('choosing unsafe and sending reports the guide once', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireReport: true,
    );

    await _openReportSheet(tester);
    expect(find.byType(ReportSheet), findsOneWidget);

    await tester.tap(find.text('Unsafe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REPORT'));
    await tester.pumpAndSettle();

    expect(repo.writes, ['report:g1']);
    expect(repo.reports['g1']?.reason, ReportReason.unsafe);
    expect(find.byType(ReportSheet), findsNothing);
    await unmount(tester);
  });

  testWidgets('sending is disabled until a reason is chosen', (tester) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireReport: true,
    );
    await _openReportSheet(tester);

    await tester.tap(find.text('SEND REPORT'));
    await tester.pumpAndSettle();

    expect(repo.writes, isEmpty);
    expect(find.byType(ReportSheet), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a second report for the same guide adds no second row', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireReport: true,
    );

    await _openReportSheet(tester);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REPORT'));
    await tester.pumpAndSettle();

    await _openReportSheet(tester);
    await tester.tap(find.text('Offensive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REPORT'));
    await tester.pumpAndSettle();

    // Two sends, but the primary key keeps the first reason.
    expect(repo.writes, ['report:g1', 'report:g1']);
    expect(repo.reports, hasLength(1));
    expect(repo.reports['g1']?.reason, ReportReason.spam);
    await unmount(tester);
  });

  testWidgets('signed out: Report opens CM-04 and writes nothing', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(),
      wireReport: true,
    );

    await _openReportSheet(tester);

    expect(find.byType(SignInSheet), findsOneWidget);
    expect(find.text('Sign in to report guides'), findsOneWidget);
    expect(find.byType(ReportSheet), findsNothing);
    expect(repo.writes, isEmpty);
    await unmount(tester);
  });

  testWidgets('Report is absent from the author\'s own guide', (tester) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(
        user: signedInUser.copyForAuthor(guide.authorId),
      ),
      wireReport: true,
    );

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.text('Report'), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the note field stops at 200 characters', (tester) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireReport: true,
    );
    await _openReportSheet(tester);
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();

    // The field caps input, so an over-long note cannot reach the wire:
    // typing 201 characters leaves 200. The repository still rejects a
    // longer note on its own (report_repository_test.dart).
    await tester.enterText(find.byType(TextField), 'x' * 201);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REPORT'));
    await tester.pumpAndSettle();

    expect(repo.writes, ['report:g1']);
    expect(repo.reports['g1']?.note, 'x' * maxReportNoteLength);
    await unmount(tester);
  });

  test('the fake rejects an over-long note before recording a write', () {
    // The real repository validates before it sends, so a widget test
    // asserting on writes must not see one the real app would not make.
    final repo = FakeGuideRepository();
    expect(
      () => repo.reportGuide('g1', reason: ReportReason.spam, note: 'x' * 201),
      throwsArgumentError,
    );
    expect(repo.writes, isEmpty);
  });

  testWidgets('a sent report is confirmed on screen', (tester) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireReport: true,
    );
    await _openReportSheet(tester);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REPORT'));
    await tester.pumpAndSettle();

    // Without this the sheet just vanishes and the user cannot tell the
    // report was filed, so they file it again.
    expect(find.text('Thanks. We will review this guide.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the sheet takes no dismiss while a send is in flight', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    repo.writeGate = Completer<void>();
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireReport: true,
    );
    await _openReportSheet(tester);
    await tester.tap(find.text('Offensive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REPORT'));
    await tester.pump();

    // Tapping the scrim must not cancel a report that is already on its
    // way: the insert would land anyway.
    await tester.tapAt(const Offset(180, 40));
    await tester.pump();
    expect(find.byType(ReportSheet), findsOneWidget);

    repo.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ReportSheet), findsNothing);
    expect(repo.reports['g1']?.reason, ReportReason.offensive);
    await unmount(tester);
  });

  testWidgets('a failed send keeps its message until the user reacts', (
    tester,
  ) async {
    final repo = FakeGuideRepository(guides: {'g1': guide});
    repo.writeError = Exception('offline');
    await pumpGuideDetail(
      tester,
      repo,
      auth: FakeAuthRepository(user: signedInUser),
      wireReport: true,
    );
    await _openReportSheet(tester);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REPORT'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't send your report. Try again."), findsOneWidget);

    // Picking a different reason answers the message, so it goes.
    await tester.tap(find.text('Unsafe'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't send your report. Try again."), findsNothing);
    await unmount(tester);
  });

  testWidgets('signing in as the author does not open the report sheet', (
    tester,
  ) async {
    // The fake signs in as u1, so this guide belongs to whoever completes
    // CM-04 here.
    final own = testGuide('g1', authorId: 'u1');
    final repo = FakeGuideRepository(guides: {'g1': own});
    // Signed out, CM-02 cannot tell the guide is the user's own, so it
    // offers Report.
    final auth = FakeAuthRepository(verifiedHasProfile: true);
    await pumpGuideDetail(tester, repo, auth: auth, wireReport: true);

    await _openReportSheet(tester);
    expect(find.byType(SignInSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'isaac@example.com');
    await tester.pump();
    await tester.tap(find.text('SEND CODE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '481926');
    await tester.pump();
    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();

    // Signed in as the author: reporting your own guide counts toward
    // hiding it, and RLS does not stop you.
    expect(find.byType(ReportSheet), findsNothing);
    expect(repo.writes, isEmpty);
    await unmount(tester);
  });
}
