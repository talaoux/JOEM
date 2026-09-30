import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/utils/cv_storage.dart';

import 'api_client.dart';
import 'api_config.dart';

/// Copie locale (SQLite) du compte renvoyé par l'API.
///
/// Pendant la migration vers l'API, seuls les comptes vivent sur le
/// serveur : offres, candidatures, portfolio, etc. sont encore lus et
/// écrits dans `joem.db` par les repositories existants, qui retrouvent
/// l'utilisateur par son id. Le compte serveur est donc recopié dans
/// `users` **avec le même id** que sur le serveur, puis son profil.
///
/// Règle de conflit : quand un profil local existe déjà pour cet id, il
/// est conservé tel quel (sauf `replaceProfile`) — les modifications faites
/// sur ce téléphone ne sont pas encore envoyées au serveur, les écraser au
/// démarrage les ferait disparaître.
class LocalAccountMirror {
  const LocalAccountMirror();

  /// Valeur de `users.password_hash` d'un compte serveur : ne correspond à
  /// aucun hash, la connexion locale hors API échoue donc toujours.
  static const String serverAccountMarker = 'api';

  /// Recopie [user] (JSON de `GET /auth/me`) et renvoie son id local
  /// (= id serveur).
  ///
  /// [photoBytes], [coverPhotoBytes], [cvPath] et [cvFileName] : fichiers
  /// déjà présents sur ce téléphone (inscription). Sinon, et seulement à
  /// la création du profil local, la photo et la bannière sont
  /// téléchargées depuis leur `*_url`.
  Future<int> save(
    Map<String, dynamic> user, {
    ApiClient? client,
    bool replaceProfile = false,
    Uint8List? photoBytes,
    Uint8List? coverPhotoBytes,
    String? cvPath,
    String? cvFileName,
  }) async {
    final id = user['id'] as int;
    final email = user['email'] as String;
    final role = ApiRole.toLocal(user['role'] as String);
    final isJobSeeker = role == ApiRole.localJobSeeker;
    final profile = (isJobSeeker ? user['candidate_profile'] : user['employer_profile']) as Map<String, dynamic>?;
    final profileTable = isJobSeeker ? 'job_seeker_profiles' : 'employer_profiles';

    final db = await AppDatabase.instance.database;
    final hasLocalProfile = (await db.query(profileTable, columns: ['id'], where: 'user_id = ?', whereArgs: [id], limit: 1)).isNotEmpty;
    final writeProfile = profile != null && (replaceProfile || !hasLocalProfile);

    // Téléchargements hors transaction : une transaction SQLite ne doit pas
    // rester ouverte pendant un appel réseau.
    final projectImages = <int, Uint8List?>{};
    final certificationImages = <int, Uint8List?>{};
    if (writeProfile && client != null) {
      photoBytes ??= await _download(client, profile[isJobSeeker ? 'photo_url' : 'logo_url']);
      coverPhotoBytes ??= await _download(client, profile['cover_photo_url']);
      if (isJobSeeker) {
        if (cvPath == null && profile['cv_url'] is String) {
          final cvBytes = await _download(client, profile['cv_url']);
          cvFileName = profile['cv_file_name'] as String? ?? 'cv.pdf';
          if (cvBytes != null) cvPath = await saveCvFile(cvBytes, cvFileName);
        }
        for (final project in _rows(user['portfolio_projects'])) {
          projectImages[project['id'] as int] = await _download(client, project['image_url']);
        }
        for (final certification in _rows(user['certifications'])) {
          certificationImages[certification['id'] as int] = await _download(client, certification['image_url']);
        }
      }
    }

    await db.transaction((txn) async {
      // Un compte local sans rapport (créé avant le branchement API) qui
      // occupe cet id ou cet e-mail est retiré : les comptes locaux ne sont
      // pas migrés (contrat §2), et `users.email` est unique.
      await txn.delete('users', where: '(id = ? AND email != ?) OR (email = ? AND id != ?)', whereArgs: [id, email, email, id]);

      final existing = await txn.query('users', columns: ['id'], where: 'id = ?', whereArgs: [id], limit: 1);
      if (existing.isEmpty) {
        await txn.insert('users', {
          'id': id,
          'email': email,
          'password_hash': serverAccountMarker,
          'role': role,
          'created_at': user['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        // Jamais de `REPLACE` sur `users` : il supprimerait la ligne, et
        // avec elle (ON DELETE CASCADE) tout ce que ce compte a créé ici.
        await txn.update('users', {'email': email, 'role': role}, where: 'id = ?', whereArgs: [id]);
      }

      if (!writeProfile) return;

      final row = isJobSeeker
          ? _jobSeekerRow(profile, photoBytes, coverPhotoBytes, cvPath, cvFileName)
          : _employerRow(profile, photoBytes, coverPhotoBytes);
      final updated = await txn.update(profileTable, row, where: 'user_id = ?', whereArgs: [id]);
      if (updated == 0) {
        await txn.insert(profileTable, {'user_id': id, ...row}, conflictAlgorithm: ConflictAlgorithm.abort);
      }

      if (isJobSeeker) {
        await txn.delete('job_seeker_skills', where: 'user_id = ?', whereArgs: [id]);
        for (final skill in (user['skills'] as List? ?? const [])) {
          final map = skill as Map<String, dynamic>;
          await txn.insert('job_seeker_skills', {'user_id': id, 'name': map['name'], 'rating': map['rating']});
        }
        await txn.delete('job_seeker_work_modes', where: 'user_id = ?', whereArgs: [id]);
        for (final mode in (user['work_modes'] as List? ?? const [])) {
          await txn.insert('job_seeker_work_modes', {'user_id': id, 'work_mode': (mode as Map<String, dynamic>)['work_mode']});
        }
        await _replacePortfolio(txn, id, user, projectImages, certificationImages);
      }
    });

    return id;
  }

  /// Sections du portfolio, avec les ids du serveur : une suppression
  /// faite ensuite sur ce téléphone vise ainsi le bon élément côté API.
  Future<void> _replacePortfolio(
    Transaction txn,
    int userId,
    Map<String, dynamic> user,
    Map<int, Uint8List?> projectImages,
    Map<int, Uint8List?> certificationImages,
  ) async {
    Future<void> replace(String table, Object? rows, Map<String, Object?> Function(Map<String, dynamic> row) columns) async {
      await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
      for (final row in _rows(rows)) {
        await txn.insert(table, {'id': row['id'], 'user_id': userId, ...columns(row)}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await replace('job_seeker_experiences', user['experiences'], (row) => {
          'poste': row['poste'],
          'entreprise': row['entreprise'],
          'date_debut': row['date_debut'] ?? '',
          'date_fin': row['date_fin'],
          'en_cours': row['en_cours'] == true ? 1 : 0,
          'description': row['description'],
        });
    await replace('job_seeker_portfolio_projects', user['portfolio_projects'], (row) => {
          'title': row['title'],
          'description': row['description'],
          'link': row['link'],
          'image': projectImages[row['id']],
          'created_at': row['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'role': row['role'],
          'technologies': (row['technologies'] as List? ?? const []).join(','),
          'features': (row['features'] as List? ?? const []).join('\n'),
          'github_link': row['github_link'],
          'demo_link': row['demo_link'],
        });
    await replace('job_seeker_formations', user['formations'], (row) => {
          'etablissement': row['etablissement'],
          'filiere': row['filiere'],
          'date_debut': row['date_debut'] ?? '',
          'date_fin': row['date_fin'],
        });
    await replace('job_seeker_certifications', user['certifications'], (row) => {
          'name': row['name'],
          'organism': row['organism'],
          'date': row['date'],
          'image': certificationImages[row['id']],
          'verification_link': row['verification_link'],
        });
    await replace('job_seeker_professional_links', user['professional_links'], (row) => {
          'label': row['label'],
          'url': row['url'],
        });
  }

  static List<Map<String, dynamic>> _rows(Object? value) => value is List ? value.cast<Map<String, dynamic>>() : const [];

  Map<String, Object?> _jobSeekerRow(
    Map<String, dynamic> profile,
    Uint8List? photoBytes,
    Uint8List? coverPhotoBytes,
    String? cvPath,
    String? cvFileName,
  ) =>
      {
        'nom': profile['nom'] as String? ?? '',
        'prenom': profile['prenom'] as String? ?? '',
        'telephone': profile['telephone'],
        'localisation': profile['localisation'],
        'titre_professionnel': profile['titre_professionnel'] as String? ?? '',
        'presentation': profile['presentation'],
        'objectifs': profile['objectifs'],
        'tarif_journalier': profile['tarif_journalier'],
        'disponibilite': profile['disponibilite'],
        'portfolio_theme_color': profile['portfolio_theme_color'],
        'photo': photoBytes,
        'cover_photo': coverPhotoBytes,
        'cv_path': cvPath,
        'cv_file_name': cvPath == null ? null : cvFileName,
        'cv_picked': cvPath == null ? 0 : 1,
        ..._flags(profile, visibilityKey: 'profil_visible'),
      };

  Map<String, Object?> _employerRow(Map<String, dynamic> profile, Uint8List? logoBytes, Uint8List? coverPhotoBytes) => {
        'nom': profile['nom'] as String? ?? '',
        'prenom': profile['prenom'] as String? ?? '',
        'telephone': profile['telephone'],
        'localisation': profile['localisation'],
        'nom_entreprise': profile['nom_entreprise'] as String? ?? '',
        'description': profile['description'],
        'categorie': profile['categorie'],
        'logo': logoBytes,
        'cover_photo': coverPhotoBytes,
        ..._flags(profile, visibilityKey: 'entreprise_visible'),
      };

  /// Booléens JSON -> entiers SQLite, avec les mêmes valeurs par défaut que
  /// le schéma local.
  Map<String, int> _flags(Map<String, dynamic> profile, {required String visibilityKey}) {
    int flag(String key, bool fallback) => (profile[key] as bool? ?? fallback) ? 1 : 0;
    return {
      visibilityKey: flag(visibilityKey, true),
      'notifications_actives': flag('notifications_actives', true),
      'publicite_personnalisee': flag('publicite_personnalisee', true),
      'communications_marketing': flag('communications_marketing', false),
      'mode_nuit': flag('mode_nuit', false),
      'texte_agrandi': flag('texte_agrandi', false),
      'animations_reduites': flag('animations_reduites', false),
    };
  }

  Future<Uint8List?> _download(ApiClient client, Object? url) async =>
      url is String && url.isNotEmpty ? client.downloadBytes(url) : null;
}
