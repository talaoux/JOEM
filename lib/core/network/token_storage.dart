import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage du jeton Sanctum renvoyé par `POST /auth/login` et
/// `POST /auth/register` (contrat §2).
abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

/// Jeton chiffré par le système (Keystore Android, Keychain iOS) — jamais
/// dans SQLite ni dans les préférences en clair.
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();

  static const _key = 'joem_api_token';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// Stockage en mémoire, pour les tests (aucun canal de plateforme).
class MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}
