import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/data/guide_feed_request.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';
import 'package:http/http.dart' as http;

import '../../helpers/community_fixtures.dart';

/// The request [query] builds at [offset], as the server would receive it.
Future<Uri> _request(GuideFeedQuery query, {int offset = 0}) async {
  Uri? url;
  final client = mockSupabase((request) async {
    url = request.url;
    return http.Response('[]', 200, request: request);
  });
  await buildGuideFeedRequest(client, query, offset: offset);
  return url!;
}

void main() {
  group('request for each tab', () {
    test('Top: star_count desc, published_at desc, no filters', () async {
      final url = await _request(const GuideFeedQuery());

      expect(url.path, '/rest/v1/guide_feed');
      expect(url.queryParameters, {
        'select': '*',
        'order': 'star_count.desc.nullslast,published_at.desc.nullslast',
        'offset': '0',
        'limit': '20',
      });
    });

    test('Trending: stars_7d desc, star_count desc', () async {
      final url = await _request(
        const GuideFeedQuery(sort: GuideSort.trending),
      );

      expect(
        url.queryParameters['order'],
        'stars_7d.desc.nullslast,star_count.desc.nullslast',
      );
      expect(url.queryParameters.keys, {'select', 'order', 'offset', 'limit'});
    });

    test('New: published_at desc only', () async {
      final url = await _request(const GuideFeedQuery(sort: GuideSort.newest));

      expect(url.queryParameters['order'], 'published_at.desc.nullslast');
    });

    test('every sort has an order, and the order map has no extras', () {
      expect(guideFeedOrder.keys, GuideSort.values);
    });
  });

  group('filters', () {
    test('balcony + difficulty 1 + budget + "lettuce" on Top', () async {
      final url = await _request(
        const GuideFeedQuery(
          spaceTypes: ['balcony'],
          difficulty: 1,
          tags: ['budget'],
          search: 'lettuce',
        ),
      );

      expect(url.queryParameters, {
        'select': '*',
        'space_types': 'cs.{"balcony"}',
        'difficulty': 'eq.1',
        'tags': 'cs.{"budget"}',
        'title': 'ilike.%lettuce%',
        'order': 'star_count.desc.nullslast,published_at.desc.nullslast',
        'offset': '0',
        'limit': '20',
      });
    });

    test('filters combine with the Trending order', () async {
      final url = await _request(
        const GuideFeedQuery(
          sort: GuideSort.trending,
          spaceTypes: ['windowsill'],
        ),
      );

      expect(url.queryParameters['space_types'], 'cs.{"windowsill"}');
      expect(
        url.queryParameters['order'],
        'stars_7d.desc.nullslast,star_count.desc.nullslast',
      );
    });

    test('several space types and tags must all match', () async {
      final url = await _request(
        const GuideFeedQuery(
          spaceTypes: ['balcony', 'windowsill'],
          tags: ['budget', 'kids'],
        ),
      );

      expect(url.queryParameters['space_types'], 'cs.{"balcony","windowsill"}');
      expect(url.queryParameters['tags'], 'cs.{"budget","kids"}');
    });

    test('search is trimmed; blank search adds no filter', () async {
      final padded = await _request(const GuideFeedQuery(search: '  kale '));
      final blank = await _request(const GuideFeedQuery(search: '   '));

      expect(padded.queryParameters['title'], 'ilike.%kale%');
      expect(blank.queryParameters.containsKey('title'), isFalse);
    });

    test('typed %, _ and \\ match literally', () async {
      final url = await _request(const GuideFeedQuery(search: r'50%_a\b'));

      expect(url.queryParameters['title'], r'ilike.%50\%\_a\\b%');
    });
  });

  group('paging window', () {
    test('page n asks for rows offset..offset+19', () async {
      for (final offset in [0, 20, 40]) {
        final url = await _request(const GuideFeedQuery(), offset: offset);
        expect(url.queryParameters['offset'], '$offset');
        expect(url.queryParameters['limit'], '$guideFeedPageSize');
      }
      expect(guideFeedPageSize, 20);
    });
  });

  group('GuideFeedQuery', () {
    test('equal queries are ==, with equal hashCodes', () {
      const a = GuideFeedQuery(
        sort: GuideSort.trending,
        spaceTypes: ['balcony'],
        difficulty: 2,
        tags: ['kids'],
        search: 'x',
      );
      const b = GuideFeedQuery(
        sort: GuideSort.trending,
        spaceTypes: ['balcony'],
        difficulty: 2,
        tags: ['kids'],
        search: 'x',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('each field takes part in equality', () {
      const base = GuideFeedQuery(
        spaceTypes: ['balcony'],
        difficulty: 1,
        tags: ['kids'],
        search: 'x',
      );

      expect(base.withSort(GuideSort.newest), isNot(base));
      expect(base.copyWith(spaceTypes: ['windowsill']), isNot(base));
      expect(base.withDifficulty(2), isNot(base));
      expect(base.copyWith(tags: ['budget']), isNot(base));
      expect(base.copyWith(search: 'y'), isNot(base));
    });

    test('withSort keeps the filters; withDifficulty(null) clears one', () {
      const q = GuideFeedQuery(
        spaceTypes: ['balcony'],
        difficulty: 3,
        tags: ['kids'],
        search: 'x',
      );

      final trending = q.withSort(GuideSort.trending);
      expect(trending.sort, GuideSort.trending);
      expect(trending.spaceTypes, ['balcony']);
      expect(trending.difficulty, 3);
      expect(trending.tags, ['kids']);
      expect(trending.search, 'x');
      expect(q.withDifficulty(null).difficulty, isNull);
    });

    test('isFiltered ignores the sort and blank search', () {
      expect(const GuideFeedQuery().isFiltered, isFalse);
      expect(const GuideFeedQuery(sort: GuideSort.newest).isFiltered, isFalse);
      expect(const GuideFeedQuery(search: '  ').isFiltered, isFalse);
      expect(const GuideFeedQuery(search: 'a').isFiltered, isTrue);
      expect(const GuideFeedQuery(spaceTypes: ['balcony']).isFiltered, isTrue);
      expect(const GuideFeedQuery(difficulty: 1).isFiltered, isTrue);
      expect(const GuideFeedQuery(tags: ['kids']).isFiltered, isTrue);
    });
  });
}
