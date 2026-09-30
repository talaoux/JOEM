import 'dart:typed_data';

import 'api_client.dart';

/// Routes de compte de l'API (`/auth/*`, `/profile`), contrat §2 et §11.
class AccountApi {
  const AccountApi(this.client);

  final ApiClient client;

  /// `POST /auth/register` — enregistre le jeton reçu. [fields] suit le
  /// contrat (rôle `candidate`/`employer`, noms de champs en snake_case).
  Future<void> register(Map<String, Object?> fields) async {
    final data = await client.post('/auth/register', body: fields) as Map<String, dynamic>;
    await client.saveToken(data['token'] as String);
  }

  /// `POST /auth/login` — lève [ApiException] (422) si les identifiants
  /// sont incorrects.
  Future<void> login(String email, String password) async {
    final data = await client.post('/auth/login', body: {'email': email, 'password': password}) as Map<String, dynamic>;
    await client.saveToken(data['token'] as String);
  }

  /// `POST /auth/google` — connexion par le jeton d'identité Google, vérifié
  /// par le serveur. Lève [ApiException] 404 si aucun compte JOEM ne
  /// correspond à ce compte Google (la connexion ne crée jamais de compte).
  Future<void> loginWithGoogle(String idToken) async {
    final data = await client.post('/auth/google', body: {'id_token': idToken}) as Map<String, dynamic>;
    await client.saveToken(data['token'] as String);
  }

  /// `POST /auth/forgot-password` — envoie un code à 6 chiffres par e-mail.
  /// Même réponse que le compte existe ou non.
  Future<void> requestPasswordResetCode(String email) =>
      client.post('/auth/forgot-password', body: {'email': email});

  /// `POST /auth/reset-password` — lève [ApiException] (422, champ `code`)
  /// si le code est faux ou expiré. Déconnecte tous les appareils.
  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      client.post('/auth/reset-password', body: {
        'email': email,
        'code': code,
        'password': newPassword,
        'password_confirmation': newPassword,
      });

  /// `GET /profile` : l'utilisateur, son profil et, pour un candidat, ses
  /// compétences, modes de travail et sections de portfolio.
  Future<Map<String, dynamic>> profile() async => await client.get('/profile') as Map<String, dynamic>;

  Future<void> updateProfile(Map<String, Object?> fields) => client.patch('/profile', body: fields);

  Future<void> uploadPhoto(Uint8List bytes) => client.upload('/profile/photo', bytes: bytes, filename: 'photo.jpg');

  Future<void> uploadCover(Uint8List bytes) => client.upload('/profile/cover', bytes: bytes, filename: 'banniere.jpg');

  Future<void> uploadCv(Uint8List bytes, String filename) => client.upload('/profile/cv', bytes: bytes, filename: filename);

  Future<void> deleteCv() => client.delete('/profile/cv');

  /// `PATCH /auth/password` — déconnecte les autres appareils.
  Future<void> changePassword({required String currentPassword, required String newPassword}) =>
      client.patch('/auth/password', body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      });

  /// `POST /auth/logout` puis oubli du jeton, même si le serveur est
  /// injoignable : se déconnecter doit toujours réussir sur le téléphone.
  Future<void> logout() async {
    try {
      await client.post('/auth/logout');
    } on ApiException {
      // Jeton déjà invalide ou serveur injoignable : rien à révoquer de plus.
    } finally {
      await client.clearToken();
    }
  }
}
