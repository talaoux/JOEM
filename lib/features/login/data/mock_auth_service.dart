import 'package:joem/features/login/domain/auth_user.dart';
import 'package:joem/features/login/domain/user_role.dart';

import 'auth_exception.dart';

class _TestAccount {
  const _TestAccount({
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
  });

  final String email;
  final String password;
  final String displayName;
  final UserRole role;
}

/// Faux backend d'authentification : pas d'appel réseau, juste une liste
/// de comptes de test en dur. Suffit à brancher un vrai écran de connexion
/// (validation + redirection par rôle) tant qu'aucune API n'existe.
class MockAuthService {
  const MockAuthService();

  static const _accounts = [
    _TestAccount(
      email: 'employeur@gmail.com',
      password: 'employeur123',
      displayName: 'Employeur Test',
      role: UserRole.employer,
    ),
  ];

  /// Simule un aller-retour réseau puis valide email + mot de passe.
  /// Lève [AuthException] si les identifiants ne correspondent à aucun
  /// compte de test.
  Future<AuthUser> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();
    _TestAccount? account;
    for (final candidate in _accounts) {
      if (candidate.email == normalizedEmail) {
        account = candidate;
        break;
      }
    }

    if (account == null || account.password != password) {
      throw const AuthException('Email ou mot de passe incorrect.');
    }

    return AuthUser(email: account.email, displayName: account.displayName, role: account.role);
  }
}