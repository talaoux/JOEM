import 'dart:io';

import 'package:flutter/foundation.dart';

import 'account_api.dart';
import 'api_client.dart';
import 'local_account_mirror.dart';

/// Inscription sur le serveur, commune aux deux wizards.
///
/// 1. `POST /auth/register` : si le serveur refuse (e-mail déjà pris, mot
///    de passe trop court…), [ApiException] remonte et rien n'est créé.
/// 2. Compléments (`PATCH /profile`, photo, CV) : le compte existe déjà,
///    un échec ici ne doit pas faire croire à l'utilisateur que
///    l'inscription a échoué — il est journalisé, et le complément reste
///    dans la copie locale.
/// 3. Recopie du compte dans SQLite, avec l'id serveur, via
///    [LocalAccountMirror] ; renvoie cet id.
Future<int> registerOnServer(
  ApiClient api, {
  required Map<String, Object?> fields,
  Map<String, Object?> profileFields = const {},
  Uint8List? photoBytes,
  String? cvPath,
  String? cvFileName,
}) async {
  final account = AccountApi(api);
  await account.register(fields);

  if (profileFields.isNotEmpty) {
    await _bestEffort('profil', () => account.updateProfile(profileFields));
  }
  if (photoBytes != null) {
    await _bestEffort('photo', () => account.uploadPhoto(photoBytes));
  }
  if (cvPath != null) {
    await _bestEffort('CV', () async {
      final bytes = await File(cvPath).readAsBytes();
      await account.uploadCv(bytes, cvFileName ?? cvPath.split(Platform.pathSeparator).last);
    });
  }

  return const LocalAccountMirror().save(
    await account.profile(),
    client: api,
    replaceProfile: true,
    photoBytes: photoBytes,
    cvPath: cvPath,
    cvFileName: cvFileName,
  );
}

/// Texte saisi vide -> `null` : l'API distingue « non renseigné » d'une
/// chaîne vide.
String? blankToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

Future<void> _bestEffort(String label, Future<void> Function() action) async {
  try {
    await action();
  } on Exception catch (error) {
    debugPrint('Inscription serveur : envoi du $label échoué, conservé en local ($error).');
  }
}
