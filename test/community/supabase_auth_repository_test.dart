import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/data/supabase_auth_repository.dart';
import 'package:geaux_farm/features/community/domain/auth_repository.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

/// A SupabaseClient whose HTTP layer is [handler]: no network.
class _Backend {
  final requests = <http.Request>[];
  final handlers = <String, FutureOr<http.Response> Function(http.Request)>{};

  late final SupabaseClient client = SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    // Implicit flow: PKCE needs the platform storage supabase_flutter adds.
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
    httpClient: MockClient((request) async {
      requests.add(request);
      final handler = handlers['${request.method} ${request.url.path}'];
      if (handler == null) {
        return http.Response('{"message":"unhandled"}', 500);
      }
      final response = await handler(request);
      return http.Response(
        response.body,
        response.statusCode,
        headers: response.headers,
        request: request,
      );
    }),
  );

  Map<String, dynamic> lastBody(String route) {
    final request = requests.lastWhere(
      (r) => '${r.method} ${r.url.path}' == route,
    );
    return jsonDecode(request.body) as Map<String, dynamic>;
  }
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

String _jwt() {
  String part(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = DateTime.now().add(const Duration(hours: 1));
  return '${part({'alg': 'HS256'})}.'
      '${part({'sub': 'u1', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.sig';
}

Map<String, dynamic> _session() => {
  'access_token': _jwt(),
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'refresh',
  'user': {
    'id': 'u1',
    'aud': 'authenticated',
    'email': 'isaac@example.com',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-10-07T00:00:00Z',
  },
};

void main() {
  late _Backend backend;
  late SupabaseAuthRepository repo;

  setUp(() {
    backend = _Backend();
    repo = SupabaseAuthRepository(backend.client);
  });

  /// Sign in through the repository with no profile row (or with [username]).
  Future<AuthUser> signIn({String? username}) {
    backend.handlers['POST /auth/v1/verify'] = (_) => _json(_session());
    backend.handlers['GET /rest/v1/profiles'] = (_) => _json(
      username == null
          ? []
          : [
              {'username': username},
            ],
    );
    return repo.verifyEmailCode('isaac@example.com', '481926');
  }

  group('sendEmailCode', () {
    test('posts the email to the OTP endpoint', () async {
      backend.handlers['POST /auth/v1/otp'] = (_) => _json({});
      await repo.sendEmailCode('isaac@example.com');
      expect(
        backend.lastBody('POST /auth/v1/otp')['email'],
        'isaac@example.com',
      );
    });

    test('a 429 is RateLimitedException', () async {
      backend.handlers['POST /auth/v1/otp'] = (_) => _json({
        'code': 429,
        'error_code': 'over_email_send_rate_limit',
        'msg': 'email rate limit exceeded',
      }, 429);
      await expectLater(
        repo.sendEmailCode('isaac@example.com'),
        throwsA(isA<RateLimitedException>()),
      );
    });

    test('a rejected address is InvalidEmailException', () async {
      backend.handlers['POST /auth/v1/otp'] = (_) => _json({
        'code': 422,
        'error_code': 'validation_failed',
        'msg': 'Unable to validate email address: invalid format',
      }, 422);
      await expectLater(
        repo.sendEmailCode('nope'),
        throwsA(isA<InvalidEmailException>()),
      );
    });

    test('a socket failure is NetworkException', () async {
      backend.handlers['POST /auth/v1/otp'] = (_) =>
          throw const SocketException('offline');
      await expectLater(
        repo.sendEmailCode('isaac@example.com'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('verifyEmailCode', () {
    test(
      'verifies as an email OTP and returns a user with no profile yet',
      () async {
        final user = await signIn();

        final body = backend.lastBody('POST /auth/v1/verify');
        expect(body['type'], 'email');
        expect(body['email'], 'isaac@example.com');
        expect(body['token'], '481926');
        expect(user, const AuthUser(id: 'u1', email: 'isaac@example.com'));
        expect(user.hasProfile, isFalse);
        expect(repo.currentUser, user);
      },
    );

    test('returns the username when a profiles row exists', () async {
      final user = await signIn(username: 'isaac');
      expect(user.username, 'isaac');
      expect(user.hasProfile, isTrue);
    });

    test('a wrong or expired code is InvalidCodeException', () async {
      backend.handlers['POST /auth/v1/verify'] = (_) => _json({
        'code': 403,
        'error_code': 'otp_expired',
        'msg': 'Token has expired or is invalid',
      }, 403);
      await expectLater(
        repo.verifyEmailCode('isaac@example.com', '000000'),
        throwsA(isA<InvalidCodeException>()),
      );
      expect(repo.currentUser, isNull);
    });

    test('a 429 is RateLimitedException, not a wrong code', () async {
      backend.handlers['POST /auth/v1/verify'] = (_) => _json({
        'code': 429,
        'error_code': 'over_request_rate_limit',
        'msg': 'Too many requests',
      }, 429);
      await expectLater(
        repo.verifyEmailCode('isaac@example.com', '000000'),
        throwsA(isA<RateLimitedException>()),
      );
    });

    test('a server error is NetworkException', () async {
      backend.handlers['POST /auth/v1/verify'] = (_) =>
          http.Response('bad gateway', 502);
      await expectLater(
        repo.verifyEmailCode('isaac@example.com', '000000'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('usernameAvailable', () {
    test('is true when no profile has the name, false when one does', () async {
      backend.handlers['GET /rest/v1/profiles'] = (_) => _json([]);
      expect(await repo.usernameAvailable('isaac'), isTrue);
      expect(backend.requests.last.url.queryParameters['username'], 'eq.isaac');

      backend.handlers['GET /rest/v1/profiles'] = (_) => _json([
        {'id': 'u9'},
      ]);
      expect(await repo.usernameAvailable('isaac'), isFalse);
    });

    test('offline is NetworkException', () async {
      backend.handlers['GET /rest/v1/profiles'] = (_) =>
          throw http.ClientException('offline');
      await expectLater(
        repo.usernameAvailable('isaac'),
        throwsA(isA<NetworkException>()),
      );
      expect(backend.requests, hasLength(1), reason: 'no automatic retries');
    });

    test('a timeout is NetworkException', () async {
      backend.handlers['GET /rest/v1/profiles'] = (_) =>
          throw TimeoutException('slow');
      await expectLater(
        repo.usernameAvailable('isaac'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('createProfile', () {
    test('inserts the signed-in user id with the username', () async {
      await signIn();
      backend.handlers['POST /rest/v1/profiles'] = (_) =>
          http.Response('', 201);

      await repo.createProfile('isaac');

      expect(backend.lastBody('POST /rest/v1/profiles'), {
        'id': 'u1',
        'username': 'isaac',
      });
      expect(repo.currentUser?.username, 'isaac');
    });

    test('a unique violation is UsernameTakenException', () async {
      await signIn();
      backend.handlers['POST /rest/v1/profiles'] = (_) => _json({
        'code': '23505',
        'message': 'duplicate key value violates unique constraint',
      }, 409);
      await expectLater(
        repo.createProfile('isaac'),
        throwsA(isA<UsernameTakenException>()),
      );
      expect(repo.currentUser?.username, isNull);
    });

    test('signed out is AuthRequiredException', () async {
      await expectLater(
        repo.createProfile('isaac'),
        throwsA(isA<AuthRequiredException>()),
      );
      expect(backend.requests, isEmpty);
    });
  });

  group('authChanges', () {
    test('a pending profile insert cannot restore a signed-out user', () async {
      await signIn();
      final reached = Completer<void>();
      final response = Completer<http.Response>();
      backend.handlers['POST /rest/v1/profiles'] = (_) {
        reached.complete();
        return response.future;
      };
      backend.handlers['POST /auth/v1/logout'] = (_) => http.Response('', 204);
      final pending = repo.createProfile('isaac');
      await reached.future;
      await repo.signOut();
      final rejected = expectLater(
        pending,
        throwsA(isA<AuthRequiredException>()),
      );
      response.complete(http.Response('', 201));
      await rejected;

      expect(repo.currentUser, isNull);
    });

    test(
      'OTP profile resolution cannot complete sign-in after sign-out',
      () async {
        backend.handlers['POST /auth/v1/verify'] = (_) => _json(_session());
        final reached = Completer<void>();
        final response = Completer<http.Response>();
        backend.handlers['GET /rest/v1/profiles'] = (_) {
          reached.complete();
          return response.future;
        };
        backend.handlers['POST /auth/v1/logout'] = (_) =>
            http.Response('', 204);
        final pending = repo.verifyEmailCode('isaac@example.com', '481926');
        await reached.future;
        await repo.signOut();
        final rejected = expectLater(
          pending,
          throwsA(isA<AuthRequiredException>()),
        );
        response.complete(
          _json([
            {'username': 'isaac'},
          ]),
        );
        await rejected;

        expect(repo.currentUser, isNull);
      },
    );

    test('sign-out wins over an in-flight profile read', () async {
      await signIn(username: 'isaac');
      final reached = Completer<void>();
      final response = Completer<http.Response>();
      backend.handlers['GET /rest/v1/profiles'] = (_) {
        if (!reached.isCompleted) reached.complete();
        return response.future;
      };
      backend.handlers['POST /auth/v1/logout'] = (_) => http.Response('', 204);
      final seen = <AuthUser?>[];
      final signedOut = Completer<void>();
      final sub = repo.authChanges().listen((user) {
        seen.add(user);
        if (user == null && !signedOut.isCompleted) signedOut.complete();
      });
      addTearDown(sub.cancel);
      await reached.future;
      await repo.signOut();
      await signedOut.future;
      response.complete(
        _json([
          {'username': 'isaac'},
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repo.currentUser, isNull);
      expect(seen, [null]);
    });

    test('emits the user after verify, the new username after '
        'createProfile, and null after sign-out', () async {
      final seen = <AuthUser?>[];
      String? stored;
      final sub = repo.authChanges().listen(seen.add);
      addTearDown(sub.cancel);
      Future<void> settle() =>
          Future<void>.delayed(const Duration(milliseconds: 50));
      backend.handlers['POST /auth/v1/logout'] = (_) => http.Response('', 204);
      backend.handlers['POST /rest/v1/profiles'] = (_) {
        stored = 'isaac';
        return http.Response('', 201);
      };

      await settle();
      await signIn();
      backend.handlers['GET /rest/v1/profiles'] = (_) => _json(
        stored == null
            ? []
            : [
                {'username': stored},
              ],
      );
      await settle();
      await repo.createProfile('isaac');
      await settle();
      await repo.signOut();
      await settle();

      expect(seen.last, isNull);
      expect(
        seen.whereType<AuthUser>().map((u) => u.username).toList(),
        containsAllInOrder([null, 'isaac']),
      );
      expect(repo.currentUser, isNull);
    });
  });
}
