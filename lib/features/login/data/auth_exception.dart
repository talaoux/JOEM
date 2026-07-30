/// Erreur d'authentification renvoyée par [MockAuthService] (identifiants
/// invalides). Le message est déjà prêt à être affiché à l'utilisateur.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}