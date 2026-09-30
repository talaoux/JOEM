import 'dart:typed_data';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/server_registration.dart';
import 'package:joem/core/utils/password_hasher.dart';

/// Levée quand l'email choisi à l'étape "Compte" est déjà utilisé par un
/// autre compte (contrainte UNIQUE de la table `users`).
class EmailAlreadyUsedException implements Exception {
  const EmailAlreadyUsedException();
}

/// Une compétence saisie à l'étape "Profil professionnel".
typedef SkillInput = ({String name, int rating});

/// Toutes les données saisies dans le wizard "Inscription Chercheur
/// d'emploi", prêtes à être persistées.
class JobSeekerRegistrationData {
  const JobSeekerRegistrationData({
    required this.email,
    required this.password,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.localisation,
    required this.titreProfessionnel,
    required this.presentation,
    required this.photoBytes,
    required this.skills,
    this.cvPath,
    this.cvFileName,
    required this.tarifJournalier,
    required this.disponibilite,
    required this.workModes,
    this.googleIdToken,
  });

  final String email;
  final String password;

  /// Jeton d'identité Google quand le compte est créé via "Continuer avec
  /// Google" : le serveur en tire l'e-mail vérifié, et [password] n'est pas
  /// envoyé (mode serveur uniquement).
  final String? googleIdToken;
  final String nom;
  final String prenom;
  final String telephone;
  final String localisation;
  final String titreProfessionnel;
  final String presentation;
  final Uint8List? photoBytes;
  final List<SkillInput> skills;
  final String? cvPath;
  final String? cvFileName;
  final String tarifJournalier;
  final String? disponibilite;
  final List<String> workModes;
}

class JobSeekerRegistrationResult {
  const JobSeekerRegistrationResult({required this.userId, required this.email});

  final int userId;
  final String email;
}

/// Accès à la persistance SQLite pour l'inscription "Chercheur d'emploi"
/// (voir `lib/core/database/app_database.dart` pour le schéma des tables).
class JobSeekerRepository {
  const JobSeekerRepository();

  /// Avec `API_BASE_URL`, le compte est créé sur le serveur (voir
  /// [registerOnServer]) : un refus du serveur remonte en [ApiException].
  Future<JobSeekerRegistrationResult> register(JobSeekerRegistrationData data) async {
    final api = ApiClient.shared;
    if (api != null) return _registerOnServer(api, data);

    final db = await AppDatabase.instance.database;

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [data.email],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const EmailAlreadyUsedException();
    }

    final userId = await db.transaction((txn) async {
      final id = await txn.insert('users', {
        'email': data.email,
        'password_hash': await hashPassword(data.password),
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.insert('job_seeker_profiles', {
        'user_id': id,
        'nom': data.nom,
        'prenom': data.prenom,
        'telephone': data.telephone,
        'localisation': data.localisation,
        'titre_professionnel': data.titreProfessionnel,
        'presentation': data.presentation,
        'photo': data.photoBytes,
        'cv_picked': data.cvPath != null ? 1 : 0,
        'cv_path': data.cvPath,
        'cv_file_name': data.cvFileName,
        'tarif_journalier': data.tarifJournalier,
        'disponibilite': data.disponibilite,
      });

      for (final skill in data.skills) {
        await txn.insert('job_seeker_skills', {
          'user_id': id,
          'name': skill.name,
          'rating': skill.rating,
        });
      }

      for (final mode in data.workModes) {
        await txn.insert('job_seeker_work_modes', {
          'user_id': id,
          'work_mode': mode,
        });
      }

      return id;
    });

    return JobSeekerRegistrationResult(userId: userId, email: data.email);
  }

  Future<JobSeekerRegistrationResult> _registerOnServer(ApiClient api, JobSeekerRegistrationData data) async {
    final userId = await registerOnServer(
      api,
      fields: {
        'role': 'candidate',
        'email': data.email,
        if (data.googleIdToken != null)
          'google_id_token': data.googleIdToken
        else ...{
          'password': data.password,
          // Le wizard a déjà vérifié la confirmation à l'étape "Compte".
          'password_confirmation': data.password,
        },
        'nom': data.nom,
        'prenom': data.prenom,
        'telephone': blankToNull(data.telephone),
        'localisation': blankToNull(data.localisation),
        'titre_professionnel': data.titreProfessionnel,
        'presentation': blankToNull(data.presentation),
      },
      profileFields: {
        'tarif_journalier': blankToNull(data.tarifJournalier),
        'disponibilite': blankToNull(data.disponibilite),
        // L'API note de 1 à 5 (contrat §9) ; une compétence sans étoile compte pour 1.
        'skills': [
          for (final skill in data.skills) {'name': skill.name, 'rating': skill.rating.clamp(1, 5)},
        ],
        'work_modes': data.workModes.toSet().toList(),
      },
      photoBytes: data.photoBytes,
      cvPath: data.cvPath,
      cvFileName: data.cvFileName,
    );

    return JobSeekerRegistrationResult(userId: userId, email: data.email);
  }
}