/// The signed-in community user, without any backend types.
///
/// [username] is null until the user has a `profiles` row (07 § Auth:
/// first sign-in picks a username).
class AuthUser {
  const AuthUser({required this.id, required this.email, this.username});

  final String id;
  final String email;
  final String? username;

  bool get hasProfile => username != null;

  AuthUser withUsername(String username) =>
      AuthUser(id: id, email: email, username: username);

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.username == username;

  @override
  int get hashCode => Object.hash(id, email, username);

  @override
  String toString() => 'AuthUser($id, $email, $username)';
}
