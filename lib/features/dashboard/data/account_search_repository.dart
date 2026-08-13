import 'dart:typed_data';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart' show JobExperience;

/// Type de recherche de compte — distingue les historiques recruteur
/// (recherche de candidats) et candidat (recherche d'entreprises) dans
/// `search_history`, un recruteur et un candidat pouvant partager le même
/// texte de recherche sans se marcher dessus.
class SearchAccountType {
  static const String candidate = 'candidate';
  static const String company = 'company';
}

/// Un candidat déjà inscrit (`job_seeker_profiles`), trouvé par
/// [AccountSearchRepository.searchJobSeekers] — recherche réelle parmi les
/// comptes créés via le wizard d'inscription chercheur d'emploi, jamais de
/// données mockées.
class CandidateSearchResult {
  const CandidateSearchResult({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.position,
    this.localisation,
    this.telephone,
    this.presentation,
    this.photo,
    this.skills = const [],
    this.experiences = const [],
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String? position;
  final String? localisation;
  final String? telephone;
  final String? presentation;
  final Uint8List? photo;
  final List<String> skills;

  /// Expériences professionnelles réellement saisies par ce candidat
  /// (`job_seeker_experiences`) — affichées en lecture seule sur
  /// `CandidateProfileViewScreen`, le profil qu'un recruteur consulte
  /// depuis `CandidateSearchScreen`.
  final List<JobExperience> experiences;

  String get fullName => '$firstName $lastName'.trim();
}

/// Une entreprise déjà inscrite (`employer_profiles`), trouvée par
/// [AccountSearchRepository.searchEmployers].
class CompanySearchResult {
  const CompanySearchResult({
    required this.userId,
    required this.companyName,
    this.contactName,
    this.localisation,
    this.telephone,
    this.description,
    this.logo,
  });

  final String userId;
  final String companyName;
  final String? contactName;
  final String? localisation;
  final String? telephone;
  final String? description;
  final Uint8List? logo;
}

/// Recherche de comptes déjà inscrits (`users` + `job_seeker_profiles`/
/// `employer_profiles`) — pas d'offres, pas de données mockées : un
/// recruteur ne trouve que des candidats réellement inscrits, un candidat
/// ne trouve que des entreprises réellement inscrites, aucune requête ne
/// renvoie de résultat sinon. Gère aussi l'historique de recherche réel
/// (`search_history`), propre à chaque utilisateur et type de recherche —
/// remplace les listes mockées précédemment codées en dur dans
/// `CandidateSearchScreen`/`JobSearchScreen`.
class AccountSearchRepository {
  const AccountSearchRepository();

  static const int _historyLimit = 8;

  Future<List<CandidateSearchResult>> searchJobSeekers(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    final db = await AppDatabase.instance.database;
    final like = '%${term.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT
        u.id AS user_id,
        jsp.prenom AS prenom,
        jsp.nom AS nom,
        jsp.titre_professionnel AS titre_professionnel,
        jsp.localisation AS localisation,
        jsp.telephone AS telephone,
        jsp.presentation AS presentation,
        jsp.photo AS photo
      FROM users u
      INNER JOIN job_seeker_profiles jsp ON jsp.user_id = u.id
      LEFT JOIN job_seeker_skills jss ON jss.user_id = u.id
      WHERE u.role = 'job_seeker'
        AND (
          LOWER(jsp.prenom) LIKE ? OR
          LOWER(jsp.nom) LIKE ? OR
          LOWER(jsp.titre_professionnel) LIKE ? OR
          LOWER(jsp.localisation) LIKE ? OR
          LOWER(jss.name) LIKE ?
        )
      ORDER BY jsp.prenom ASC
      ''',
      [like, like, like, like, like],
    );
    if (rows.isEmpty) return [];

    final userIds = rows.map((row) => row['user_id'] as int).toList();
    final placeholders = List.filled(userIds.length, '?').join(',');
    final skillRows = await db.query(
      'job_seeker_skills',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
    final skillsByUserId = <int, List<String>>{};
    for (final row in skillRows) {
      final userId = row['user_id'] as int;
      (skillsByUserId[userId] ??= []).add(row['name'] as String);
    }

    final experienceRows = await db.query(
      'job_seeker_experiences',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
    final experiencesByUserId = <int, List<JobExperience>>{};
    for (final row in experienceRows) {
      final userId = row['user_id'] as int;
      (experiencesByUserId[userId] ??= []).add(JobExperience(
        id: row['id'] as int,
        poste: row['poste'] as String,
        entreprise: row['entreprise'] as String,
        dateDebut: row['date_debut'] as String,
        dateFin: row['date_fin'] as String?,
        enCours: (row['en_cours'] as int? ?? 0) == 1,
        description: row['description'] as String?,
      ));
    }

    return rows.map((row) {
      final userId = row['user_id'] as int;
      return CandidateSearchResult(
        userId: userId.toString(),
        firstName: row['prenom'] as String? ?? '',
        lastName: row['nom'] as String? ?? '',
        position: row['titre_professionnel'] as String?,
        localisation: row['localisation'] as String?,
        telephone: row['telephone'] as String?,
        presentation: row['presentation'] as String?,
        photo: row['photo'] as Uint8List?,
        skills: skillsByUserId[userId] ?? const [],
        experiences: experiencesByUserId[userId] ?? const [],
      );
    }).toList();
  }

  Future<List<CompanySearchResult>> searchEmployers(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    final db = await AppDatabase.instance.database;
    final like = '%${term.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT
        u.id AS user_id,
        ep.nom_entreprise AS nom_entreprise,
        ep.nom AS nom,
        ep.prenom AS prenom,
        ep.localisation AS localisation,
        ep.telephone AS telephone,
        ep.description AS description,
        ep.logo AS logo
      FROM users u
      INNER JOIN employer_profiles ep ON ep.user_id = u.id
      WHERE u.role = 'employer'
        AND (
          LOWER(ep.nom_entreprise) LIKE ? OR
          LOWER(ep.localisation) LIKE ? OR
          LOWER(ep.description) LIKE ?
        )
      ORDER BY ep.nom_entreprise ASC
      ''',
      [like, like, like],
    );

    return rows.map((row) {
      final userId = row['user_id'] as int;
      final prenom = row['prenom'] as String? ?? '';
      final nom = row['nom'] as String? ?? '';
      final contactName = '$prenom $nom'.trim();
      return CompanySearchResult(
        userId: userId.toString(),
        companyName: row['nom_entreprise'] as String? ?? '',
        contactName: contactName.isEmpty ? null : contactName,
        localisation: row['localisation'] as String?,
        telephone: row['telephone'] as String?,
        description: row['description'] as String?,
        logo: row['logo'] as Uint8List?,
      );
    }).toList();
  }

  /// Historique de recherche réel de [userId] pour [searchType]
  /// (`SearchAccountType.candidate`/`company`), les plus récentes en
  /// premier.
  Future<List<String>> fetchHistory({
    required String userId,
    required String searchType,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'search_history',
      columns: ['query'],
      where: 'user_id = ? AND search_type = ?',
      whereArgs: [userId, searchType],
      orderBy: 'searched_at DESC',
      limit: _historyLimit,
    );
    return rows.map((row) => row['query'] as String).toList();
  }

  /// Enregistre une recherche réellement effectuée — une même recherche
  /// répétée remonte simplement en tête de liste (l'ancienne ligne est
  /// supprimée puis réinsérée avec un nouvel horodatage) plutôt que de
  /// créer un doublon.
  Future<void> recordSearch({
    required String userId,
    required String searchType,
    required String query,
  }) async {
    final term = query.trim();
    if (term.isEmpty) return;

    final db = await AppDatabase.instance.database;
    await db.delete(
      'search_history',
      where: 'user_id = ? AND search_type = ? AND query = ?',
      whereArgs: [userId, searchType, term],
    );
    await db.insert('search_history', {
      'user_id': userId,
      'search_type': searchType,
      'query': term,
      'searched_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeHistoryEntry({
    required String userId,
    required String searchType,
    required String query,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'search_history',
      where: 'user_id = ? AND search_type = ? AND query = ?',
      whereArgs: [userId, searchType, query],
    );
  }
}
