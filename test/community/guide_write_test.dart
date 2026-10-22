import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/data/supabase_guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide_validation.dart';
import 'package:http/http.dart' as http;

import '../helpers/community_fixtures.dart';

// plan/07 § Editor: the first save inserts a draft and reads back the
// server-generated id; later saves and publish update in place. Writes go
// to the `guides` table, never the read-only `guide_feed` view, and the
// client never sends the trigger-maintained counters.

/// Every request the repository sent.
class _Recorder {
  final requests = <http.Request>[];
  final bodies = <Map<String, Object?>>[];

  /// Rows the next response returns.
  List<Map<String, Object?>> rows = [
    {'id': 'g1'},
  ];

  Future<http.Response> call(http.Request request) async {
    requests.add(request);
    if (request.body.isNotEmpty) {
      final decoded = jsonDecode(request.body);
      bodies.add(
        (decoded is List ? decoded.first : decoded) as Map<String, Object?>,
      );
    }
    return http.Response(
      jsonEncode(rows),
      200,
      // postgrest reads the response's request back; without it the
      // client throws on a null check.
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}

SupabaseGuideRepository _repo(_Recorder recorder, {String? userId = 'u1'}) =>
    SupabaseGuideRepository(
      mockSupabase(recorder.call),
      currentUserId: () => userId,
    );

GuideDraft _draft({String? id, String summary = 'A made-up guide.'}) =>
    GuideDraft(
      id: id,
      title: 'Bucket tomatoes',
      summary: summary,
      difficulty: 2,
      spaceTypes: const ['balcony'],
      materials: const [GuideMaterial(name: 'Bucket', qty: '1')],
      steps: const [GuideStep(title: 'Drill holes', body: 'Six of them.')],
    );

void main() {
  late _Recorder recorder;

  setUp(() => recorder = _Recorder());

  group('first save', () {
    test(
      'inserts into guides with status draft and reads the id back',
      () async {
        final id = await _repo(recorder).saveDraft(_draft());

        expect(id, 'g1');
        expect(recorder.requests, hasLength(1));
        final request = recorder.requests.single;
        expect(request.method, 'POST');
        expect(request.url.path, '/rest/v1/guides');
        expect(request.url.query, contains('select=id'));
        expect(recorder.bodies.single['status'], 'draft');
        expect(recorder.bodies.single['author_id'], 'u1');
      },
    );

    test('an empty summary is sent as an empty string, not null', () async {
      await _repo(recorder).saveDraft(_draft(summary: ''));

      expect(recorder.bodies.single['summary'], '');
    });

    test('never writes the view', () async {
      await _repo(recorder).saveDraft(_draft());

      expect(recorder.requests.single.url.path, isNot(contains('guide_feed')));
    });
  });

  group('publish', () {
    test('a new draft is inserted with status published', () async {
      await _repo(recorder).publishGuide(_draft());

      expect(recorder.requests.single.method, 'POST');
      expect(recorder.bodies.single['status'], 'published');
    });

    test('an existing guide is updated in place, filtered by author', () async {
      final id = await _repo(recorder).publishGuide(_draft(id: 'g1'));

      expect(id, 'g1');
      final request = recorder.requests.single;
      expect(request.method, 'PATCH');
      expect(request.url.query, contains('id=eq.g1'));
      expect(request.url.query, contains('author_id=eq.u1'));
      expect(recorder.bodies.single['status'], 'published');
      // published_at is the trigger's, and the id is the server's.
      expect(recorder.bodies.single, isNot(contains('published_at')));
      expect(recorder.bodies.single, isNot(contains('id')));
    });
  });

  test('no payload carries a trigger-maintained counter', () async {
    final repo = _repo(recorder);
    await repo.saveDraft(_draft());
    await repo.publishGuide(_draft(id: 'g1'));

    for (final body in recorder.bodies) {
      expect(
        body.keys,
        isNot(
          anyElement(
            isIn(['star_count', 'grow_count', 'remix_count', 'report_count']),
          ),
        ),
      );
    }
  });

  group('signed out', () {
    test(
      'every write throws AuthRequiredException and sends nothing',
      () async {
        final repo = _repo(recorder, userId: null);

        await expectLater(
          repo.saveDraft(_draft()),
          throwsA(isA<AuthRequiredException>()),
        );
        await expectLater(
          repo.publishGuide(_draft()),
          throwsA(isA<AuthRequiredException>()),
        );
        await expectLater(
          repo.deleteGuide('g1'),
          throwsA(isA<AuthRequiredException>()),
        );
        await expectLater(
          repo.fetchDraft('g1'),
          throwsA(isA<AuthRequiredException>()),
        );
        expect(recorder.requests, isEmpty);
      },
    );
  });

  group('a write RLS refuses', () {
    test(
      'an update matching no row is rejected, not reported as success',
      () async {
        // guides_update is `author_id = auth.uid() and status <> 'hidden'`,
        // so a hidden guide comes back as zero rows.
        recorder.rows = [];

        await expectLater(
          _repo(recorder).publishGuide(_draft(id: 'g1')),
          throwsA(isA<GuideWriteRejectedException>()),
        );
      },
    );
  });

  group('delete', () {
    test('deletes by id and author', () async {
      await _repo(recorder).deleteGuide('g1');

      final request = recorder.requests.single;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/rest/v1/guides');
      expect(request.url.query, contains('id=eq.g1'));
      expect(request.url.query, contains('author_id=eq.u1'));
    });
  });

  group('open for editing', () {
    test('reads the author\'s own row from guides, draft included', () async {
      recorder.rows = [
        {
          'id': 'g1',
          'author_id': 'u1',
          'title': 'Bucket tomatoes',
          'summary': '',
          'cover_path': null,
          'difficulty': 2,
          'space_types': ['balcony'],
          'est_cost_usd': 12,
          'setup_minutes': null,
          'materials': [
            {'name': 'Bucket', 'qty': '1', 'estCostUsd': 5, 'url': null},
          ],
          'steps': [
            {'title': 'Drill holes', 'body': 'Six.', 'imagePath': null},
          ],
          'plant_ids': ['tomato'],
          'tags': ['budget'],
          'status': 'draft',
        },
      ];

      final guide = await _repo(recorder).fetchDraft('g1');

      final request = recorder.requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/guides');
      expect(request.url.query, contains('id=eq.g1'));
      expect(request.url.query, contains('author_id=eq.u1'));
      expect(guide.status, GuideStatus.draft);
      expect(guide.draft.id, 'g1');
      expect(guide.draft.summary, '');
      expect(guide.draft.estCostUsd, 12);
      expect(guide.draft.materials.single.estCostUsd, 5);
      expect(guide.draft.steps.single.title, 'Drill holes');
      expect(guide.draft.plantIds, ['tomato']);
      expect(guide.draft.tags, ['budget']);
    });

    test('another author\'s guide is not found', () async {
      recorder.rows = [];

      await expectLater(
        _repo(recorder).fetchDraft('g1'),
        throwsA(isA<GuideNotFoundException>()),
      );
    });
  });
}
