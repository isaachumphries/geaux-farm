import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/data/supabase_guide_repository.dart';
import 'package:geaux_farm/features/community/domain/report_reason.dart';
import 'package:http/http.dart' as http;

import '../../helpers/community_fixtures.dart';

// plan/07 § Moderation over the wire: one `guide_reports` row with the
// lowercase reason and the signed-in reporter, one report per user per
// guide, and a note the table's `char_length(note) <= 200` check accepts.

/// A repository whose `guide_reports` insert records the body and answers
/// with [status]; 409 is the primary key rejecting a second report.
({SupabaseGuideRepository repo, List<Map<String, Object?>> inserts}) _server({
  String? userId = 'u1',
  int status = 201,
}) {
  final inserts = <Map<String, Object?>>[];
  final client = mockSupabase((request) async {
    if (request.url.path.endsWith('/guide_reports')) {
      final body = jsonDecode(request.body);
      // postgrest sends one object for a single-row insert.
      inserts.add((body is List ? body.single : body) as Map<String, Object?>);
      if (status == 409) {
        return http.Response(
          jsonEncode({
            'code': '23505',
            'message': 'duplicate key value violates unique constraint',
          }),
          409,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', status, request: request);
    }
    return http.Response('[]', 200, request: request);
  });
  return (
    repo: SupabaseGuideRepository(client, currentUserId: () => userId),
    inserts: inserts,
  );
}

void main() {
  test('a report inserts the lowercase reason and the reporter id', () async {
    final s = _server();

    await s.repo.reportGuide('g1', reason: ReportReason.unsafe);

    expect(s.inserts, hasLength(1));
    expect(s.inserts.single, {
      'guide_id': 'g1',
      'reporter_id': 'u1',
      'reason': 'unsafe',
    });
  });

  test('a note is sent trimmed, and an empty one is left out', () async {
    final s = _server();

    await s.repo.reportGuide(
      'g1',
      reason: ReportReason.other,
      note: '  it is wrong  ',
    );
    await s.repo.reportGuide('g2', reason: ReportReason.spam, note: '   ');

    expect(s.inserts.first['note'], 'it is wrong');
    expect(s.inserts.last.containsKey('note'), isFalse);
  });

  test('a note longer than 200 characters never reaches the wire', () async {
    final s = _server();

    await expectLater(
      s.repo.reportGuide('g1', reason: ReportReason.spam, note: 'x' * 201),
      throwsArgumentError,
    );
    expect(s.inserts, isEmpty);

    await s.repo.reportGuide('g1', reason: ReportReason.spam, note: 'x' * 200);
    expect(s.inserts, hasLength(1));
  });

  test('a note is measured after trimming, as the column is', () async {
    final s = _server();

    // 205 characters, but 195 once trimmed: the column's
    // char_length(note) <= 200 accepts it, so the client must too.
    final padded = '${'x' * 195}          ';
    await s.repo.reportGuide('g1', reason: ReportReason.other, note: padded);

    expect(s.inserts.single['note'], 'x' * 195);
  });

  test('reporting the same guide twice is success, not an error', () async {
    final s = _server(status: 409);

    await s.repo.reportGuide('g1', reason: ReportReason.spam);

    expect(s.inserts, hasLength(1));
  });

  test('signed out, nothing is sent', () async {
    final s = _server(userId: null);

    await expectLater(
      s.repo.reportGuide('g1', reason: ReportReason.spam),
      throwsA(isA<AuthRequiredException>()),
    );
    expect(s.inserts, isEmpty);
  });
}
