import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/supabase_auth_repository.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

// plan/07 § Auth through authStateProvider over SupabaseAuthRepository, with
// Supabase faked at the HTTP layer. Tokens carry fixed expiry dates so no
// test reads the clock.

typedef _Handler = FutureOr<http.Response> Function(http.Request request);

/// Routes `METHOD /path` to a handler; anything unrouted is a 500.
class _Backend {
  _Backend({this.autoRefreshToken = false});

  final bool autoRefreshToken;
  final routes = <String, _Handler>{};
  final requests = <String>[];

  late final SupabaseClient client = SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    // Implicit flow: PKCE needs the platform storage supabase_flutter adds.
    authOptions: AuthClientOptions(
      autoRefreshToken: autoRefreshToken,
      authFlowType: AuthFlowType.implicit,
    ),
    httpClient: MockClient((request) async {
      final route = '${request.method} ${request.url.path}';
      requests.add(route);
      final handler = routes[route];
      final response = handler == null
          ? http.Response('{"message":"unhandled"}', 500)
          : await handler(request);
      return http.Response(
        response.body,
        response.statusCode,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
  );

  void profile(String? username) => routes['GET /rest/v1/profiles'] = (_) =>
      _json(
        username == null
            ? []
            : [
                {'username': username},
              ],
      );

  void offline(String route) =>
      routes[route] = (_) => throw const SocketException('offline');
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

/// A session for user `u1` whose access token expires at [expiresAt].
Map<String, dynamic> _session(DateTime expiresAt) {
  String part(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = expiresAt.millisecondsSinceEpoch ~/ 1000;
  return {
    'access_token':
        '${part({'alg': 'HS256'})}.${part({'sub': 'u1', 'exp': exp})}.sig',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': exp,
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
}

final _valid = _session(DateTime.utc(2100));
final _expired = _session(DateTime.utc(2020));

const _newUser = AuthUser(id: 'u1', email: 'isaac@example.com');
const _isaac = AuthUser(
  id: 'u1',
  email: 'isaac@example.com',
  username: 'isaac',
);

/// A container over [backend] that records every authStateProvider value.
({ProviderContainer container, List<AsyncValue<AuthUser?>> states}) _watch(
  _Backend backend,
) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        SupabaseAuthRepository(backend.client),
      ),
    ],
  );
  addTearDown(container.dispose);
  final states = <AsyncValue<AuthUser?>>[];
  container.listen(
    authStateProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );
  return (container: container, states: states);
}

/// Lets queued HTTP responses and stream events land.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

/// What supabase_flutter does at startup: restore the stored session, or
/// announce that there is none.
Future<void> _coldStart(_Backend backend, Map<String, dynamic>? stored) async {
  if (stored == null) {
    // ignore: invalid_use_of_internal_member
    backend.client.auth.notifyAllSubscribers(AuthChangeEvent.initialSession);
  } else {
    await backend.client.auth.setInitialSession(jsonEncode(stored));
  }
}

/// What GoTrue does when a token refresh gets no answer: the failure goes
/// onto onAuthStateChange as an error. The session stays.
void _failRefresh(_Backend backend) =>
    // ignore: invalid_use_of_internal_member
    backend.client.auth.notifyException(
      AuthRetryableFetchException(message: 'SocketException: offline'),
    );

void main() {
  test('signed out -> code sent -> verified without a profile -> username '
      'saved -> signed out (07 § Auth)', () async {
    final backend = _Backend();
    final s = _watch(backend);
    final repo = s.container.read(authRepositoryProvider);
    String? stored;
    backend.routes['POST /auth/v1/otp'] = (_) => _json({});
    backend.routes['POST /auth/v1/verify'] = (_) => _json(_valid);
    backend.routes['GET /rest/v1/profiles'] = (_) => _json(
      stored == null
          ? []
          : [
              {'username': stored},
            ],
    );
    backend.routes['POST /rest/v1/profiles'] = (_) {
      stored = 'isaac';
      return http.Response('', 201);
    };
    backend.routes['POST /auth/v1/logout'] = (_) => http.Response('', 204);

    await _coldStart(backend, null);
    await _settle();
    expect(
      s.container.read(authStateProvider),
      const AsyncData<AuthUser?>(null),
    );

    await repo.sendEmailCode('isaac@example.com');
    await _settle();
    expect(
      s.container.read(authStateProvider).value,
      isNull,
      reason: 'a sent code is not a sign-in',
    );

    final verified = await repo.verifyEmailCode('isaac@example.com', '481926');
    await _settle();
    expect(verified, _newUser);
    expect(
      s.container.read(authStateProvider).value,
      _newUser,
      reason: 'no profiles row yet: the sheet asks for a username',
    );

    await repo.createProfile('isaac');
    await _settle();
    expect(s.container.read(authStateProvider).value, _isaac);

    await repo.signOut();
    await _settle();
    expect(s.container.read(authStateProvider).value, isNull);
    expect(
      [for (final v in s.states.where((v) => v.hasValue)) v.value],
      [null, _newUser, _isaac, null],
    );
  });

  test('a returning user with a profiles row skips the username '
      'step (07 § Auth)', () async {
    final backend = _Backend()..profile('isaac');
    backend.routes['POST /auth/v1/verify'] = (_) => _json(_valid);
    final s = _watch(backend);
    await _coldStart(backend, null);
    await _settle();

    await s.container
        .read(authRepositoryProvider)
        .verifyEmailCode('isaac@example.com', '481926');
    await _settle();

    expect(s.container.read(authStateProvider).value, _isaac);
    expect(
      s.states.where((v) => v.hasValue).map((v) => v.value),
      isNot(contains(_newUser)),
      reason: 'never shown as a first sign-in on the way',
    );
  });

  group('cold start with a stored session (07 § Auth: session persisted)', () {
    test(
      'online: the stored user and their username, no code needed',
      () async {
        final backend = _Backend()..profile('isaac');
        final s = _watch(backend);

        await _coldStart(backend, _valid);
        await _settle();

        expect(s.container.read(authStateProvider).value, _isaac);
        expect(backend.requests, isNot(contains('POST /auth/v1/verify')));
      },
    );

    test('offline profile lookup is a NetworkException, not "no profile '
        'yet" and not signed out (09 § Errors)', () async {
      final backend = _Backend()..offline('GET /rest/v1/profiles');
      final s = _watch(backend);

      await _coldStart(backend, _valid);
      await _settle();

      final state = s.container.read(authStateProvider);
      expect(state.hasError, isTrue, reason: '$state');
      expect(state.error, isA<NetworkException>());
      expect(
        s.states.where((v) => v.hasValue && v.value != null),
        isEmpty,
        reason: 'a user without a username would be sent to pick one again',
      );
      expect(
        backend.requests.where((r) => r == 'GET /rest/v1/profiles'),
        hasLength(1),
        reason: 'no automatic retries (09 § Errors)',
      );
    });

    test('back online, the next auth event loads the profile', () async {
      final backend = _Backend()..offline('GET /rest/v1/profiles');
      final s = _watch(backend);
      await _coldStart(backend, _valid);
      await _settle();
      expect(s.container.read(authStateProvider).hasError, isTrue);

      backend
        ..profile('isaac')
        ..routes['POST /auth/v1/token'] = (_) => _json(_valid);
      await backend.client.auth.refreshSession();
      await _settle();

      expect(
        s.container.read(authStateProvider),
        const AsyncData<AuthUser?>(_isaac),
      );
    });

    test('an offline token refresh reaches authStateProvider as an error, not '
        'an uncaught zone error (09 § Errors)', () async {
      final backend = _Backend(autoRefreshToken: true)
        ..offline('GET /rest/v1/profiles')
        ..offline('POST /auth/v1/token');
      addTearDown(backend.client.dispose);
      final s = _watch(backend);

      // supabase_flutter restores the stored session, then refreshes it.
      await _coldStart(backend, _expired);
      await expectLater(
        backend.client.auth.recoverSession(jsonEncode(_expired)),
        throwsA(isA<AuthRetryableFetchException>()),
      );
      await _settle();

      final state = s.container.read(authStateProvider);
      expect(state.hasError, isTrue, reason: '$state');
      expect(state.error, isA<NetworkException>());
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  group('a token refresh that gets no answer (09 § Errors)', () {
    test('is a NetworkException on authStateProvider', () async {
      final backend = _Backend()..profile('isaac');
      final s = _watch(backend);
      await _coldStart(backend, _valid);
      await _settle();
      expect(s.container.read(authStateProvider).value, _isaac);

      _failRefresh(backend);
      await _settle();

      final state = s.container.read(authStateProvider);
      expect(state.hasError, isTrue, reason: '$state');
      expect(state.error, isA<NetworkException>());
    });

    test('is followed by the signed-in user once a refresh works', () async {
      final backend = _Backend()..profile('isaac');
      final s = _watch(backend);
      await _coldStart(backend, _valid);
      await _settle();
      _failRefresh(backend);
      await _settle();
      expect(s.container.read(authStateProvider).hasError, isTrue);

      backend.routes['POST /auth/v1/token'] = (_) => _json(_valid);
      await backend.client.auth.refreshSession();
      await _settle();

      expect(
        s.container.read(authStateProvider),
        const AsyncData<AuthUser?>(_isaac),
      );
    });

    test('is replayed to a listener that arrives later, as an error', () async {
      final backend = _Backend()..profile('isaac');
      await _coldStart(backend, _valid);
      _failRefresh(backend);

      final later = _watch(backend);
      await _settle();

      final state = later.container.read(authStateProvider);
      expect(state.hasError, isTrue, reason: '$state');
      expect(state.error, isA<NetworkException>());
    });

    test('after sign-out is stale: signed out for every listener, not an '
        'error', () async {
      final backend = _Backend()..profile('isaac');
      backend.routes['POST /auth/v1/logout'] = (_) => http.Response('', 204);
      final first = _watch(backend);
      await _coldStart(backend, _valid);
      await _settle();
      await first.container.read(authRepositoryProvider).signOut();
      await _settle();

      _failRefresh(backend);
      await _settle();
      expect(
        first.container.read(authStateProvider),
        const AsyncData<AuthUser?>(null),
      );
      expect(first.states.where((v) => v.hasError), isEmpty);

      final later = _watch(backend);
      await _settle();
      expect(
        later.container.read(authStateProvider),
        const AsyncData<AuthUser?>(null),
        reason: 'the replayed failure must not leave a listener loading',
      );
    });
  });

  group('sign-out while a request is in flight', () {
    test('a profile lookup that fails after sign-out leaves the user '
        'signed out, not in error', () async {
      final backend = _Backend();
      final reached = Completer<void>();
      final reply = Completer<http.Response>();
      backend.routes['GET /rest/v1/profiles'] = (_) {
        reached.complete();
        return reply.future;
      };
      backend.routes['POST /auth/v1/logout'] = (_) => http.Response('', 204);
      final s = _watch(backend);

      await _coldStart(backend, _valid);
      await reached.future;
      await s.container.read(authRepositoryProvider).signOut();
      await _settle();
      reply.completeError(const SocketException('offline'));
      await _settle();

      expect(
        s.container.read(authStateProvider),
        const AsyncData<AuthUser?>(null),
      );
      expect(s.states.where((v) => v.hasError), isEmpty);
    });

    test('a slow failed lookup cannot overwrite a newer one that '
        'succeeded', () async {
      final backend = _Backend();
      final first = Completer<http.Response>();
      var lookups = 0;
      backend.routes['GET /rest/v1/profiles'] = (_) {
        lookups++;
        return lookups == 1
            ? first.future
            : _json([
                {'username': 'isaac'},
              ]);
      };
      backend.routes['POST /auth/v1/token'] = (_) => _json(_valid);
      final s = _watch(backend);

      await _coldStart(backend, _valid);
      await _settle();
      await backend.client.auth.refreshSession();
      await _settle();
      expect(s.container.read(authStateProvider).value, _isaac);

      first.completeError(const SocketException('offline'));
      await _settle();

      expect(
        s.container.read(authStateProvider),
        const AsyncData<AuthUser?>(_isaac),
      );
    });
  });
}
