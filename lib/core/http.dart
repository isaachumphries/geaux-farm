import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// A request that never got a usable answer: timeout, socket error, or a
/// client failure. The only exception [AppHttpClient] throws itself.
class NetworkException implements Exception {
  const NetworkException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NetworkException: $message';
}

/// The climate profile could not be built. Thrown by the climate
/// repository (#25), never by [AppHttpClient].
class ClimateUnavailableException implements Exception {
  const ClimateUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'ClimateUnavailableException: $message';
}

/// The action needs a signed-in user. Thrown by the community
/// repositories, never by [AppHttpClient].
class AuthRequiredException implements Exception {
  const AuthRequiredException([this.message = 'Sign-in required']);

  final String message;

  @override
  String toString() => 'AuthRequiredException: $message';
}

/// Shared HTTP wrapper (plan/09 § Errors): every request times out after
/// [timeout] and is sent exactly once. Retrying is presentation's job.
class AppHttpClient {
  AppHttpClient(this._client, {this.timeout = defaultTimeout});

  static const defaultTimeout = Duration(seconds: 15);

  final http.Client _client;
  final Duration timeout;

  /// Sends one GET. Any status code is returned to the caller; only a
  /// timeout or connection failure throws, as [NetworkException].
  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await _client.get(uri, headers: headers).timeout(timeout);
    } on TimeoutException {
      throw NetworkException('Request timed out: ${uri.host}');
    } on SocketException catch (e) {
      throw NetworkException('Socket error: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Client error: ${e.message}');
    }
  }
}
