import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:http/http.dart' as http;

/// Counts `send` calls and fails or answers with what the test sets.
class _FakeClient extends http.BaseClient {
  _FakeClient(this.onSend);

  final Future<http.StreamedResponse> Function() onSend;
  int sendCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sendCount++;
    return onSend();
  }
}

void main() {
  final uri = Uri.parse('https://example.test/data');

  test('the configured timeout is 15 s', () {
    final client = AppHttpClient(_FakeClient(() => throw StateError('no')));
    expect(client.timeout, const Duration(seconds: 15));
    expect(AppHttpClient.defaultTimeout, const Duration(seconds: 15));
  });

  test('a timeout throws NetworkException and is not retried', () async {
    final fake = _FakeClient(() => throw TimeoutException('slow'));
    final client = AppHttpClient(fake);

    await expectLater(client.get(uri), throwsA(isA<NetworkException>()));
    expect(fake.sendCount, 1);
  });

  test('the wrapper applies its own timeout to a hung request', () async {
    final fake = _FakeClient(() => Completer<http.StreamedResponse>().future);
    final client = AppHttpClient(fake, timeout: Duration.zero);

    await expectLater(client.get(uri), throwsA(isA<NetworkException>()));
    expect(fake.sendCount, 1);
  });

  test('a socket error throws NetworkException', () async {
    final fake = _FakeClient(() => throw const SocketException('down'));
    final client = AppHttpClient(fake);

    await expectLater(client.get(uri), throwsA(isA<NetworkException>()));
    expect(fake.sendCount, 1);
  });

  test('a non-200 response is returned, not thrown', () async {
    final fake = _FakeClient(
      () async => http.StreamedResponse(Stream.value([]), 503),
    );
    final response = await AppHttpClient(fake).get(uri);

    expect(response.statusCode, 503);
    expect(fake.sendCount, 1);
  });
}
