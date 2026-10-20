import 'auth_user.dart';

/// Email-OTP sign-in plus the user's `profiles` row (plan/07 § Auth).
///
/// Implementations throw the typed exceptions below, and
/// `NetworkException` (core/http.dart) when the request never got an
/// answer. Presentation maps them to error states.
abstract interface class AuthRepository {
  /// The current user, then every change: sign-in, sign-out, and a
  /// profile being created. Emits null while signed out.
  Stream<AuthUser?> authChanges();

  AuthUser? get currentUser;

  /// Emails a 6-digit code to [email]. The caller trims and lowercases it.
  Future<void> sendEmailCode(String email);

  /// Signs in with the code and returns the user, with [AuthUser.username]
  /// null when they have no `profiles` row yet.
  Future<AuthUser> verifyEmailCode(String email, String token);

  Future<bool> usernameAvailable(String username);

  /// Inserts the signed-in user's `profiles` row. Throws
  /// [UsernameTakenException] when the name was taken in the meantime.
  Future<void> createProfile(String username);

  Future<void> signOut();
}

/// The code is wrong or expired.
class InvalidCodeException implements Exception {
  const InvalidCodeException();

  @override
  String toString() => 'InvalidCodeException';
}

/// The backend rejected the email address.
class InvalidEmailException implements Exception {
  const InvalidEmailException();

  @override
  String toString() => 'InvalidEmailException';
}

/// Too many codes requested or verified; Supabase's built-in email is
/// heavily rate-limited (plan/07 § Auth).
class RateLimitedException implements Exception {
  const RateLimitedException();

  @override
  String toString() => 'RateLimitedException';
}

/// The username belongs to another profile.
class UsernameTakenException implements Exception {
  const UsernameTakenException();

  @override
  String toString() => 'UsernameTakenException';
}
