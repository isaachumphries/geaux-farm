import 'dart:async';

import 'package:geaux_farm/features/community/domain/auth_repository.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';

/// In-memory [AuthRepository]. [calls] records every method call in order.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.verifiedHasProfile = false});

  final calls = <String>[];
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? user;

  /// Thrown by the matching method when set.
  Object? sendError;
  Object? verifyError;
  Object? availableError;
  Object? createError;

  /// Held open until completed, to observe the in-flight state.
  Completer<void>? sendGate;

  bool available = true;

  /// What [verifyEmailCode] signs in as, unless the user has a profile.
  String verifiedEmail = 'isaac@example.com';
  bool verifiedHasProfile;

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> authChanges() {
    late final StreamController<AuthUser?> controller;
    StreamSubscription<AuthUser?>? sub;
    controller = StreamController<AuthUser?>(
      onListen: () {
        controller.add(user);
        sub = _changes.stream.listen(controller.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  void _set(AuthUser? next) {
    user = next;
    _changes.add(next);
  }

  @override
  Future<void> sendEmailCode(String email) async {
    calls.add('sendEmailCode($email)');
    await sendGate?.future;
    if (sendError != null) throw sendError!;
  }

  @override
  Future<AuthUser> verifyEmailCode(String email, String token) async {
    calls.add('verifyEmailCode($email, $token)');
    if (verifyError != null) throw verifyError!;
    final signedIn = AuthUser(
      id: 'u1',
      email: email,
      username: verifiedHasProfile ? 'isaac' : null,
    );
    _set(signedIn);
    return signedIn;
  }

  @override
  Future<bool> usernameAvailable(String username) async {
    calls.add('usernameAvailable($username)');
    if (availableError != null) throw availableError!;
    return available;
  }

  @override
  Future<void> createProfile(String username) async {
    calls.add('createProfile($username)');
    if (createError != null) throw createError!;
    _set(user!.withUsername(username));
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _set(null);
  }
}
