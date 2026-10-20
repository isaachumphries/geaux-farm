import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/data/supabase_guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/community_fixtures.dart';

http.Response _json(Object body, http.Request request, [int status = 200]) =>
    http.Response(
      jsonEncode(body),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

/// A repository over a fake `guide_feed` of [total] guides that slices
/// `offset`/`limit` like PostgREST and records every request.
({SupabaseGuideRepository repo, List<Uri> requests}) _server(
  int total, {
  String? userId,
}) {
  final requests = <Uri>[];
  final all = [
    for (var i = 0; i < total; i++) testGuide('g$i', title: 'Guide number $i'),
  ];
  final client = mockSupabase((request) async {
    requests.add(request.url);
    final q = request.url.queryParameters;
    if (request.url.path.endsWith('/guide_feed')) {
      final offset = int.parse(q['offset']!);
      final limit = int.parse(q['limit']!);
      final rows = all.skip(offset).take(limit).map(guideRow).toList();
      return _json(rows, request);
    }
    return _json([
      {'guide_id': 'g1'},
      {'guide_id': 'g7'},
    ], request);
  });
  return (
    repo: SupabaseGuideRepository(client, currentUserId: () => userId),
    requests: requests,
  );
}

void main() {
  group('fetchFeed paging', () {
    test('three pages of 45 guides: range 0-19, 20-39, 40-59', () async {
      final s = _server(45);
      const query = GuideFeedQuery();

      final first = await s.repo.fetchFeed(query);
      final second = await s.repo.fetchFeed(query, offset: 20);
      final third = await s.repo.fetchFeed(query, offset: 40);

      expect(
        s.requests.map(
          (u) => (u.queryParameters['offset'], u.queryParameters['limit']),
        ),
        [('0', '20'), ('20', '20'), ('40', '20')],
      );
      expect([first.length, second.length, third.length], [20, 20, 5]);
      final ids = [...first, ...second, ...third].map((g) => g.id).toList();
      expect(ids, [for (var i = 0; i < 45; i++) 'g$i']);
    });

    test('rows become guides with every column mapped', () async {
      final client = mockSupabase((request) async {
        return _json([
          {
            ...guideRow(
              testGuide(
                'g1',
                title: 'Lettuce tower',
                difficulty: 2,
                spaceTypes: ['balcony', 'smallYard'],
                tags: ['vertical'],
                stars: 128,
                grows: 42,
                remixes: 9,
                stars7d: 5,
                coverPath: 'u1/cover.jpg',
              ),
            ),
            'author_display_name': 'Geaux Farm',
            'setup_minutes': 90,
            'forked_from': 'g0',
            'plant_ids': ['kale'],
            'materials': [
              {'name': 'Pot', 'qty': '4', 'estCostUsd': 12, 'url': null},
            ],
            'steps': [
              {'title': 'Fill', 'body': 'Add soil.', 'imagePath': 'u1/s.jpg'},
            ],
          },
        ], request);
      });

      final guide = (await SupabaseGuideRepository(
        client,
      ).fetchFeed(const GuideFeedQuery())).single;

      expect(guide.id, 'g1');
      expect(guide.authorUsername, 'geauxfarm');
      expect(guide.authorDisplayName, 'Geaux Farm');
      expect(guide.title, 'Lettuce tower');
      expect(guide.coverPath, 'u1/cover.jpg');
      expect(guide.difficulty, 2);
      expect(guide.spaceTypes, ['balcony', 'smallYard']);
      expect(guide.estCostUsd, 35);
      expect(guide.setupMinutes, 90);
      expect(guide.tags, ['vertical']);
      expect(guide.plantIds, ['kale']);
      expect(guide.forkedFrom, 'g0');
      expect(
        [guide.starCount, guide.growCount, guide.remixCount],
        [128, 42, 9],
      );
      expect(guide.stars7d, 5);
      expect(guide.publishedAt, DateTime.utc(2026, 10, 1));
      expect(guide.materials.single.name, 'Pot');
      expect(guide.materials.single.qty, '4');
      expect(guide.materials.single.estCostUsd, 12);
      expect(guide.materials.single.url, isNull);
      expect(guide.steps.single.title, 'Fill');
      expect(guide.steps.single.imagePath, 'u1/s.jpg');
    });

    test('a guide without cost or cover keeps them null', () async {
      final client = mockSupabase(
        (request) async =>
            _json([guideRow(testGuide('g1', cost: null))], request),
      );

      final guide = (await SupabaseGuideRepository(
        client,
      ).fetchFeed(const GuideFeedQuery())).single;

      expect(guide.estCostUsd, isNull);
      expect(guide.coverPath, isNull);
    });
  });

  group('failures', () {
    test('a dropped connection is a NetworkException, tried once', () async {
      var calls = 0;
      final client = mockSupabase((_) async {
        calls++;
        throw const SocketException('unreachable');
      });

      await expectLater(
        SupabaseGuideRepository(client).fetchFeed(const GuideFeedQuery()),
        throwsA(isA<NetworkException>()),
      );
      expect(calls, 1);
    });

    test('a 503 is not retried', () async {
      var calls = 0;
      final client = mockSupabase((request) async {
        calls++;
        return http.Response('', 503, request: request);
      });

      await expectLater(
        SupabaseGuideRepository(client).fetchFeed(const GuideFeedQuery()),
        throwsA(isA<PostgrestException>()),
      );
      expect(calls, 1);
    });
  });

  group('starredGuideIds', () {
    test('signed out: empty, with no request', () async {
      final s = _server(0);

      expect(await s.repo.starredGuideIds(), isEmpty);
      expect(s.requests, isEmpty);
    });

    test('signed in: the guide ids of that user only', () async {
      final s = _server(0, userId: 'user-1');

      expect(await s.repo.starredGuideIds(), {'g1', 'g7'});
      final url = s.requests.single;
      expect(url.path, '/rest/v1/guide_stars');
      expect(url.queryParameters['select'], 'guide_id');
      expect(url.queryParameters['user_id'], 'eq.user-1');
    });
  });

  test('coverUrl is the public guide-images URL', () {
    final repo = SupabaseGuideRepository(
      mockSupabase((_) async => http.Response('', 500)),
    );

    expect(
      repo.coverUrl('u1/cover.jpg'),
      'http://supabase.test/storage/v1/object/public/guide-images/u1/cover.jpg',
    );
  });
}
