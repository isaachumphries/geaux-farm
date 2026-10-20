import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/http.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// [AuthRepository] over Supabase email OTP and the `profiles` table.
/// Session persistence is supabase_flutter's; there is no token store here.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  final _profileCreated = StreamController<void>.broadcast();
  AuthUser? _current;

  GoTrueClient get _auth => _client.auth;

  /// The user from the last sign-in or [authChanges] emission. Reading the
  /// profile row is asynchronous, so this is null until the first one.
  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<AuthUser?> authChanges() {
    late final StreamController<AuthUser?> controller;
    StreamSubscription<void>? authSub;
    StreamSubscription<void>? profileSub;
    var generation = 0;

    Future<void> emit() async {
      final mine = ++generation;
      try {
        final user = await _resolve(_auth.currentUser);
        if (mine == generation && !controller.isClosed) {
          _current = user;
          controller.add(user);
        }
      } on Object catch (e, st) {
        if (mine == generation && !controller.isClosed) {
          controller.addError(e, st);
        }
      }
    }

    controller = StreamController<AuthUser?>(
      onListen: () {
        authSub = _auth.onAuthStateChange.listen((_) => emit());
        profileSub = _profileCreated.stream.listen((_) => emit());
      },
      onCancel: () async {
        await authSub?.cancel();
        await profileSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> sendEmailCode(String email) => _guard(() async {
    try {
      await _auth.signInWithOtp(email: email);
    } on AuthApiException catch (e) {
      if (_isRateLimit(e)) throw const RateLimitedException();
      if (e.code == 'validation_failed' || e.code == 'email_address_invalid') {
        throw const InvalidEmailException();
      }
      rethrow;
    }
  });

  @override
  Future<AuthUser> verifyEmailCode(String email, String token) =>
      _guard(() async {
        final AuthResponse response;
        try {
          response = await _auth.verifyOTP(
            type: OtpType.email,
            email: email,
            token: token,
          );
        } on AuthApiException catch (e) {
          if (_isRateLimit(e)) throw const RateLimitedException();
          throw const InvalidCodeException();
        }
        final user = await _resolve(response.user);
        if (user == null) throw const InvalidCodeException();
        if (_auth.currentUser?.id != user.id) {
          throw const AuthRequiredException();
        }
        _current = user;
        return user;
      });

  @override
  Future<bool> usernameAvailable(String username) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle()
        .retry(enabled: false);
    return row == null;
  });

  @override
  Future<void> createProfile(String username) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthRequiredException();
    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'username': username,
      });
    } on PostgrestException catch (e) {
      // 23505 = unique_violation on profiles.username.
      if (e.code == '23505') throw const UsernameTakenException();
      rethrow;
    }
    if (_auth.currentUser?.id != user.id) {
      throw const AuthRequiredException();
    }
    _current = AuthUser(
      id: user.id,
      email: user.email ?? '',
      username: username,
    );
    _profileCreated.add(null);
  });

  @override
  Future<void> signOut() => _guard(() async {
    await _auth.signOut();
    _current = null;
  });

  // Reads here use .retry(enabled: false): plan/09 § Errors says no
  // automatic retries, and supabase_flutter's default 1+2+4 s backoff would
  // leave the sheet spinning for seven seconds when offline.

  Future<AuthUser?> _resolve(User? user) async {
    if (user == null) return null;
    final row = await _guard(
      () => _client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle()
          .retry(enabled: false),
    );
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      username: row?['username'] as String?,
    );
  }

  static bool _isRateLimit(AuthApiException e) =>
      e.statusCode == '429' ||
      e.code == 'over_email_send_rate_limit' ||
      e.code == 'over_request_rate_limit';

  /// Turns "the request never got an answer" into [NetworkException].
  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthRetryableFetchException catch (e) {
      throw NetworkException(e.message);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('Timed out');
    }
  }
}
