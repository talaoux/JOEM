import 'user_role.dart';

/// Compte authentifié renvoyé par [MockAuthService].
class AuthUser {
  const AuthUser({
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String email;
  final String displayName;
  final UserRole role;
}