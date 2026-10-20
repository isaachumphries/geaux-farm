/// Username rule from plan/07 § Auth; the `profiles.username` check
/// constraint in 0001_init.sql is the same regex.
final RegExp usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

const int usernameMinLength = 3;
const int usernameMaxLength = 20;

bool isValidUsername(String username) => usernamePattern.hasMatch(username);
