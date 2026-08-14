import 'package:google_sign_in/google_sign_in.dart';

import '../constants/google_config.dart';

/// Fine enrobage de `GoogleSignIn.instance` (API v7, basée sur Android
/// Credential Manager) — un seul point d'appel pour le login et
/// l'inscription, qui partagent le même flux d'authentification.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: kGoogleServerClientId);
    _initialized = true;
  }

  /// Ouvre le sélecteur de compte Google. Renvoie `null` si l'utilisateur
  /// annule (`GoogleSignInExceptionCode.canceled`) ; laisse remonter
  /// [GoogleSignInException] pour toute autre erreur (le plus souvent une
  /// configuration Google Cloud incomplète — voir `kGoogleServerClientId`).
  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}