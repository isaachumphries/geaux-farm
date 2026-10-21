import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Failure mapping of the shared wrapper (plan/09 § Errors, plan/06
/// § Requests "HTTP timeout 15 s"). Timing runs on the fake clock of
/// `testWidgets`, so no test waits in real time.
void main() {
  final uri = Uri.parse('https://example.test/data');

  test('a client error is a NetworkException without a status code', () async {
    var sent = 0;
    final client = AppHttpClient(
      MockClient((_) async {
        sent++;
        throw http.ClientException('connection reset');
      }),
    );

    await expectLater(
      client.get(uri),
      throwsA(
        isA<NetworkException>().having((e) => e.statusCode, 'status', isNull),
      ),
    );
    expect(sent, 1);
  });

  testWidgets('a hung request fails at exactly 15 s, not before', (
    tester,
  ) async {
    final client = AppHttpClient(
      MockClient((_) => Completer<http.Response>().future),
    );
    Object? error;
    var done = false;
    unawaited(
      client
          .get(uri)
          .then(
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

  testWidgets('an answer just inside 15 s is returned as is', (tester) async {
    final client = AppHttpClient(
      MockClient(
        (_) => Future.delayed(
          const Duration(seconds: 14, milliseconds: 999),
          () => http.Response('busy', 429),
        ),
      ),
    );
    http.Response? response;
    unawaited(client.get(uri).then((r) => response = r));

    await tester.pump(const Duration(seconds: 15));
    expect(response?.statusCode, 429);
  });
}
