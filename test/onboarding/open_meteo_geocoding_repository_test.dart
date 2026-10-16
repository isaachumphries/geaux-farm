import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/onboarding/data/open_meteo_geocoding_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fixture = File('test/fixtures/open_meteo/geocoding_baton_rouge.json')
      .readAsStringSync();

  test('requests the plan/02 URL and parses rows', () async {
    final urls = <Uri>[];
    final repo = OpenMeteoGeocodingRepository(
      AppHttpClient(
        MockClient((req) async {
          urls.add(req.url);
          return http.Response(fixture, 200);
        }),
      ),
    );

    final places = await repo.search('Baton Rouge');

    expect(
      urls.single.toString(),
      'https://geocoding-api.open-meteo.com/v1/search?name=Baton%20Rouge&count=8&language=en',
    );
    expect(places.single.label, 'Baton Rouge, Louisiana, US');
    expect(places.single.lat, 30.45075);
    expect(places.single.postcode, '70801');
    expect(places.single.timezone, 'America/Chicago');
  });

  test('a response without results is an empty list', () async {
    final repo = OpenMeteoGeocodingRepository(
      AppHttpClient(
        MockClient(
          (_) async => http.Response('{"generationtime_ms":0.1}', 200),
        ),
      ),
    );
    expect(await repo.search('Zzzz'), isEmpty);
  });

  test('a non-200 answer throws NetworkException', () async {
    final repo = OpenMeteoGeocodingRepository(
      AppHttpClient(MockClient((_) async => http.Response('', 500))),
    );
    expect(repo.search('Baton'), throwsA(isA<NetworkException>()));
  });
}
