import 'dart:typed_data';

import 'package:joem/core/database/app_database.dart';
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
  });

  final String email;
  final String password;
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

  Future<JobSeekerRegistrationResult> register(JobSeekerRegistrationData data) async {
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
        'password_hash': hashPassword(data.password),
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
}