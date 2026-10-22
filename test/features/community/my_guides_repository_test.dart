import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/data/supabase_guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:http/http.dart' as http;

import '../../helpers/community_fixtures.dart';

http.Response _json(Object body, http.Request request) => http.Response(
  jsonEncode(body),
  200,
  request: request,
  headers: {'content-type': 'application/json'},
);

/// A `guides` row for [id] by [authorId] at [status], with its author's
/// profile embedded the way the CM-05 select asks for it.
Map<String, Object?> _ownRow(
  String id, {
  required String authorId,
  required String status,
  required String updatedAt,
}) {
  final row =
      guideRow(
          testGuide(
            id,
            title: 'Guide $id',
            authorId: authorId,
            author: authorId,
          ),
        )
        ..remove('author_username')
        ..remove('author_display_name')
        ..remove('stars_7d');
  return {
    ...row,
    'status': status,
    'updated_at': updatedAt,
    'author': {'username': '$authorId-name', 'display_name': null},
  };
}

/// Both users' rows, as the table holds them. RLS would hide neither
/// user's published guides from the other, so the client's own
/// `author_id` filter is what keeps a list to one user.
final _table = [
  _ownRow(
    'a-old',
    authorId: 'alice',
    status: 'published',
    updatedAt: '2026-10-01T00:00:00+00:00',
  ),
  _ownRow(
    'b-pub',
    authorId: 'bob',
    status: 'published',
    updatedAt: '2026-10-05T00:00:00+00:00',
  ),
  _ownRow(
    'a-new',
    authorId: 'alice',
    status: 'draft',
    updatedAt: '2026-10-09T00:00:00+00:00',
  ),
  _ownRow(
    'a-hid',
    authorId: 'alice',
    status: 'hidden',
    updatedAt: '2026-10-03T00:00:00+00:00',
  ),
];

/// A repository over [_table] for [userId] that answers `author_id=eq.` and
/// `order=updated_at.desc` like PostgREST, and records every request.
({SupabaseGuideRepository repo, List<Uri> requests}) _server(String? userId) {
  final requests = <Uri>[];
  final client = mockSupabase((request) async {
    requests.add(request.url);
    final q = request.url.queryParameters;
    var rows = [..._table];
    final author = q['author_id'];
    if (author != null) {
      rows = rows.where((r) => 'eq.${r['author_id']}' == author).toList();
    }
    if (q['order']?.startsWith('updated_at.desc') ?? false) {
      rows.sort(
        (a, b) =>
            (b['updated_at']! as String).compareTo(a['updated_at']! as String),
      );
    }
    return _json(rows, request);
  });
  return (
    repo: SupabaseGuideRepository(client, currentUserId: () => userId),
    requests: requests,
  );
}

void main() {
  group('fetchMyGuides', () {
    test(
      'lists only the signed-in user\'s guides, newest update first',
      () async {
        final alice = _server('alice');
        final bob = _server('bob');

        final mine = await alice.repo.fetchMyGuides();
        final bobs = await bob.repo.fetchMyGuides();

        expect([for (final g in mine) g.guide.id], ['a-new', 'a-hid', 'a-old']);
        expect([for (final g in bobs) g.guide.id], ['b-pub']);
        expect(mine.every((g) => g.guide.authorId == 'alice'), isTrue);
      },
    );

    test('reads the table with every status, not guide_feed', () async {
      final s = _server('alice');

      final mine = await s.repo.fetchMyGuides();

      expect(s.requests.single.path, endsWith('/guides'));
      expect(s.requests.single.queryParameters['author_id'], 'eq.alice');
      expect(
        {for (final g in mine) g.guide.id: g.status},
        {
          'a-new': GuideStatus.draft,
          'a-hid': GuideStatus.hidden,
          'a-old': GuideStatus.published,
        },
      );
    });

    test('takes the username from the embedded author profile', () async {
      final s = _server('alice');

      final mine = await s.repo.fetchMyGuides();

      expect(mine.first.guide.authorUsername, 'alice-name');
      expect(
        s.requests.single.queryParameters['select'],
        contains('author:profiles'),
      );
    });

    test('signed out: throws without a request', () async {
      final s = _server(null);

      await expectLater(
        s.repo.fetchMyGuides(),
        throwsA(isA<AuthRequiredException>()),
      );
      expect(s.requests, isEmpty);
    });
  });

  group('fetchGuidesByIds', () {
    test('reads guide_feed for the ids and keeps their order', () async {
      final requests = <Uri>[];
      final client = mockSupabase((request) async {
        requests.add(request.url);
        // PostgREST returns rows in its own order, and drops an id that has
        // no published guide.
        return _json([
          guideRow(testGuide('g1')),
          guideRow(testGuide('g3')),
        ], request);
      });
      final repo = SupabaseGuideRepository(client, currentUserId: () => 'u');

      final guides = await repo.fetchGuidesByIds(['g3', 'gone', 'g1']);

      expect([for (final g in guides) g.id], ['g3', 'g1']);
      expect(requests.single.path, endsWith('/guide_feed'));
      expect(requests.single.queryParameters['id'], 'in.("g3","gone","g1")');
    });

    test('no ids: no request', () async {
      final requests = <Uri>[];
      final client = mockSupabase((request) async {
        requests.add(request.url);
        return _json([], request);
      });
      final repo = SupabaseGuideRepository(client, currentUserId: () => 'u');

      expect(await repo.fetchGuidesByIds(const []), isEmpty);
      expect(requests, isEmpty);
    });
  });

  test('starredGuideIds asks for the newest star first and keeps it', () async {
    final requests = <Uri>[];
    final client = mockSupabase((request) async {
      requests.add(request.url);
      return _json([
        {'guide_id': 'newest'},
        {'guide_id': 'older'},
        {'guide_id': 'oldest'},
      ], request);
    });
    final repo = SupabaseGuideRepository(client, currentUserId: () => 'u');

    final ids = await repo.starredGuideIds();

    expect(ids.toList(), ['newest', 'older', 'oldest']);
    expect(
      requests.single.queryParameters['order'],
      startsWith('created_at.desc'),
    );
  });
}
