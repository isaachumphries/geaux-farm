import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/env.dart';
import '../../../core/http.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'supabase_auth_repository.dart';

/// The Supabase-backed repository, or [UnconfiguredAuthRepository] when the
/// app was started without `env.json` (see [Env.hasSupabase]).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => Env.hasSupabase
      ? SupabaseAuthRepository(Supabase.instance.client)
      : const UnconfiguredAuthRepository(),
);

/// The signed-in user, or null (plan/09 § State management).
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authChanges(),
);

/// Signed out forever: nothing to sign in to. Every network call fails as
/// offline, so the sheet shows its offline error instead of crashing.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  static const _unavailable = NetworkException('Supabase is not configured');

  @override
  Stream<AuthUser?> authChanges() => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> sendEmailCode(String email) => Future.error(_unavailable);

  @override
  Future<AuthUser> verifyEmailCode(String email, String token) =>
      Future.error(_unavailable);

  @override
  Future<bool> usernameAvailable(String username) => Future.error(_unavailable);

  @override
  Future<void> createProfile(String username) => Future.error(_unavailable);

  @override
  Future<void> signOut() async {}
}
