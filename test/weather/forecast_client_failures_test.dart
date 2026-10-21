import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// plan/06 § Requests: one attempt, 15 s timeout; every failure surfaces
/// as a typed `NetworkException` so the provider can keep cached data.
void main() {
  final fetchedAt = DateTime(2026, 10, 13, 17, 20);

  Future<void> fetch(OpenMeteoForecastClient client) =>
      client.fetchForecast(30.45, -91.19, fetchedAt: fetchedAt);

  test('a client error is a NetworkException, sent once', () async {
    var sent = 0;
    final client = OpenMeteoForecastClient(
      MockClient((_) async {
        sent++;
        throw http.ClientException('connection reset');
      }),
    );
    await expectLater(fetch(client), throwsA(isA<NetworkException>()));
    expect(sent, 1);
  });

  for (final status in [204, 301, 404, 429]) {
    test('HTTP $status carries its status code', () async {
      final client = OpenMeteoForecastClient(
        MockClient((_) async => http.Response('{}', status)),
      );
      await expectLater(
        fetch(client),
        throwsA(
          isA<NetworkException>().having((e) => e.statusCode, 'status', status),
        ),
      );
    });
  }

  for (final (label, body) in [
    ('a JSON array', '[]'),
    ('a daily block with a missing column', '{"current":null,"daily":{}}'),
    ('an empty body', ''),
  ]) {
    test('$label is a NetworkException', () async {
      final client = OpenMeteoForecastClient(
        MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(fetch(client), throwsA(isA<NetworkException>()));
    });
  }

  testWidgets('the default timeout fires at 15 s, not before', (tester) async {
    final client = OpenMeteoForecastClient(
      MockClient((_) => Completer<http.Response>().future),
    );
    Object? error;
    var done = false;
    unawaited(
      fetch(client).then(
        (_) => done = true,
        onError: (Object e) {
          error = e;
          done = true;
        },
      ),
    );

    await tester.pump(const Duration(seconds: 14, milliseconds: 999));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(error, isA<NetworkException>());
  });
}
