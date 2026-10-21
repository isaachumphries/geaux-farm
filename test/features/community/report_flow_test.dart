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
}
