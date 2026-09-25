import 'dart:typed_data';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/utils/password_hasher.dart';
import 'package:joem/features/job_seeker_registration/data/job_seeker_repository.dart'
    show EmailAlreadyUsedException;

/// Toutes les données saisies dans le wizard "Inscription Recruteur",
/// prêtes à être persistées.
class RecruiterRegistrationData {
  const RecruiterRegistrationData({
    required this.email,
    required this.password,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.localisation,
    required this.nomEntreprise,
    required this.description,
    required this.logoBytes,
    required this.categorieEntreprise,
  });

  final String email;
  final String password;
  final String nom;
  final String prenom;
  final String telephone;
  final String localisation;
  final String nomEntreprise;
  final String description;
  final Uint8List? logoBytes;

  /// Catégorie d'entreprise choisie (parmi `kJobCategories`) — obligatoire
  /// dans le wizard, réutilisée côté candidat pour filtrer les offres par
  /// secteur (`JobOfferRepository.fetchByCategory`).
  final String categorieEntreprise;
}

class RecruiterRegistrationResult {
  const RecruiterRegistrationResult({required this.userId, required this.email});

  final int userId;
  final String email;
}

/// Accès à la persistance SQLite pour l'inscription "Recruteur" (voir
/// `lib/core/database/app_database.dart` pour le schéma des tables).
class RecruiterRepository {
  const RecruiterRepository();

  Future<RecruiterRegistrationResult> register(RecruiterRegistrationData data) async {
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
        'role': 'employer',
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.insert('employer_profiles', {
        'user_id': id,
        'nom': data.nom,
        'prenom': data.prenom,
        'telephone': data.telephone,
        'localisation': data.localisation,
        'nom_entreprise': data.nomEntreprise,
        'description': data.description,
        'logo': data.logoBytes,
        'categorie': data.categorieEntreprise,
      });

      return id;
    });

    return RecruiterRegistrationResult(userId: userId, email: data.email);
  }
}
