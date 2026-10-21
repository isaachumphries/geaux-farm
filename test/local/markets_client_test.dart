import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/local/data/overpass_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// plan/08 § Markets: one Overpass POST per fetch, parsed into rows sorted
// by distance from the profile location. Failures are NetworkException and
// are never retried (plan/09 § Errors).

final _fixture = File('test/fixtures/overpass/markets_baton_rouge.json')
    .readAsStringSync();

/// Baton Rouge, the profile location in the plan's fixture.
const _lat = 30.45;
const _lon = -91.19;

OverpassMarketsClient _client(
  Future<http.Response> Function(http.Request) handler, {
  Duration timeout = AppHttpClient.defaultTimeout,
}) =>
    OverpassMarketsClient(AppHttpClient(MockClient(handler), timeout: timeout));

void main() {
  group('the request', () {
    test('posts the plan query to Overpass once', () async {
      final requests = <http.Request>[];
      await _client((request) async {
        requests.add(request);
        return http.Response(_fixture, 200);
      }).fetchMarkets(_lat, _lon);

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url, OverpassMarketsClient.endpoint);
      expect(
        request.body,
        '[out:json][timeout:25];'
        'nwr["amenity"="marketplace"](around:40000,30.45,-91.19);'
        'out center 50;',
      );
    });

    test('the query timeout is the server\'s 25 s, not the client\'s 15 s', () {
      expect(OverpassMarketsClient.queryTimeoutSeconds, 25);
      expect(AppHttpClient.defaultTimeout, const Duration(seconds: 15));
      expect(OverpassMarketsClient.query(_lat, _lon), contains('[timeout:25]'));
    });
  });

  group('parsing', () {
    test('returns named, located markets nearest first', () async {
      final markets = await _client((_) async => http.Response(_fixture, 200))
          .fetchMarkets(_lat, _lon);

      expect(markets.map((m) => m.name), [
        'Red Stick Farmers Market', // 0 mi, the profile location itself
        'Lafayette Hub City Market', // 51.98 mi
        'Crescent City Farmers Market', // 75.28 mi
      ]);
      expect(markets.first.distanceMi, 0);
      expect(markets[1].distanceMi, closeTo(51.9843087951321, 1e-9));
      expect(markets.last.distanceMi, closeTo(75.27634614455094, 1e-9));
    });

    test('a way reads its coordinates from center', () async {
      final markets = await _client((_) async => http.Response(_fixture, 200))
          .fetchMarkets(_lat, _lon);
      final way = markets.firstWhere((m) => m.id == 'way/4002');

      expect(way.lat, 30.22);
      expect(way.lon, -92.02);
    });

    test('optional tags come through, and absent ones stay null', () async {
      final markets = await _client((_) async => http.Response(_fixture, 200))
          .fetchMarkets(_lat, _lon);

      final crescent = markets.firstWhere((m) => m.id == 'node/3001');
      expect(crescent.openingHours, 'Sa 08:00-12:00');
      expect(crescent.website, 'https://example.test/crescent');

      final redStick = markets.firstWhere((m) => m.id == 'node/3003');
      expect(redStick.openingHours, isNull);
      expect(redStick.website, isNull);

      final lafayette = markets.firstWhere((m) => m.id == 'way/4002');
      expect(lafayette.openingHours, 'Sa 07:30-12:00');
      expect(lafayette.website, isNull);
    });

    test('elements with no name or no coordinates are skipped', () async {
      final markets = await _client((_) async => http.Response(_fixture, 200))
          .fetchMarkets(_lat, _lon);

      // node/3004 has no name; relation/5005 has no center.
      expect(markets, hasLength(3));
      expect(markets.map((m) => m.id), isNot(contains('node/3004')));
      expect(markets.map((m) => m.id), isNot(contains('relation/5005')));
    });

    test('an empty result set is empty, not an error', () async {
      final markets = await _client(
        (_) async => http.Response('{"elements": []}', 200),
      ).fetchMarkets(_lat, _lon);

      expect(markets, isEmpty);
    });
  });

  group('failures become NetworkException, with one attempt', () {
    test('a non-200 status', () async {
      var calls = 0;
      await expectLater(
        _client((_) async {
          calls++;
          return http.Response('rate limited', 429);
        }).fetchMarkets(_lat, _lon),
        throwsA(
          isA<NetworkException>().having((e) => e.statusCode, 'status', 429),
        ),
      );
      expect(calls, 1);
    });

    test('a timeout', () async {
      var calls = 0;
      await expectLater(
        _client((_) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return http.Response(_fixture, 200);
        }, timeout: const Duration(milliseconds: 10)).fetchMarkets(_lat, _lon),
        throwsA(isA<NetworkException>()),
      );
      expect(calls, 1);
    });

    test('a socket error', () async {
      await expectLater(
        _client((_) async => throw const SocketException('no route'))
            .fetchMarkets(_lat, _lon),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a body that is not the shape we expect', () async {
      await expectLater(
        _client((_) async => http.Response('not json', 200))
            .fetchMarkets(_lat, _lon),
        throwsA(isA<NetworkException>()),
      );
      await expectLater(
        _client((_) async => http.Response(jsonEncode({'elements': 7}), 200))
            .fetchMarkets(_lat, _lon),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
