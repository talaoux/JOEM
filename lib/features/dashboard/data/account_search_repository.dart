import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart'
    show Certification, Formation, JobExperience, PortfolioProject, ProfessionalLink, User;

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
    this.portfolioProjects = const [],
    this.objectifs,
    this.formations = const [],
    this.certifications = const [],
    this.professionalLinks = const [],
    this.portfolioThemeColor,
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

  /// Clé du `PortfolioHeroTheme` choisi par ce candidat pour son Portfolio
  /// (`job_seeker_profiles.portfolio_theme_color`) — `null` = thème violet
  /// par défaut. Permet à `CandidateFullPortfolioScreen` d'afficher le même
  /// dégradé "hero" côté recruteur que celui choisi par le candidat.
  final String? portfolioThemeColor;

  /// Expériences professionnelles réellement saisies par ce candidat
  /// (`job_seeker_experiences`) — affichées en lecture seule sur
  /// `CandidateProfileViewScreen`, le profil qu'un recruteur consulte
  /// depuis `CandidateSearchScreen`.
  final List<JobExperience> experiences;

  /// Réalisations réellement ajoutées par ce candidat depuis
  /// `PortfolioProjectsScreen` (`job_seeker_portfolio_projects`) — affichées
  /// en lecture seule sur `CandidateProfileViewScreen`.
  final List<PortfolioProject> portfolioProjects;

  /// Bloc "Mes objectifs" (`job_seeker_profiles.objectifs`), affiché en
  /// lecture seule sur `CandidateProfileViewScreen`.
  final String? objectifs;

  /// Formations réellement ajoutées par ce candidat (`job_seeker_formations`)
  /// — affichées en lecture seule sur `CandidateProfileViewScreen`.
  final List<Formation> formations;

  /// Certifications réellement ajoutées par ce candidat
  /// (`job_seeker_certifications`) — affichées en lecture seule sur
  /// `CandidateProfileViewScreen`.
  final List<Certification> certifications;

  /// Liens professionnels réellement ajoutés par ce candidat
  /// (`job_seeker_professional_links`) — affichés en lecture seule sur
  /// `CandidateProfileViewScreen`.
  final List<ProfessionalLink> professionalLinks;

  String get fullName => '$firstName $lastName'.trim();

  /// Construit le même modèle qu'une recherche recruteur, mais à partir du
  /// [User] actuellement connecté — permet au candidat de prévisualiser son
  /// propre portfolio exactement comme un recruteur le verrait
  /// (`CandidateFullPortfolioScreen` depuis `PortfolioScreen`), sans requête
  /// supplémentaire puisque [User] porte déjà toutes ces données.
  factory CandidateSearchResult.fromUser(User user) {
    return CandidateSearchResult(
      userId: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      position: user.position,
      localisation: user.localisation,
      telephone: user.telephone,
      presentation: user.presentation,
      photo: user.photoBytes,
      skills: user.skills,
      experiences: user.experiences,
      portfolioProjects: user.portfolioProjects,
      objectifs: user.objectifs,
      formations: user.formations,
      certifications: user.certifications,
      professionalLinks: user.professionalLinks,
      portfolioThemeColor: user.portfolioThemeColor,
    );
  }
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

/// Un recruteur ayant consulté le profil du candidat connecté
/// (`job_seeker_profile_views` jointe à `employer_profiles`) — alimente la
/// page "Vues du profil" ouverte depuis la stat du panneau latéral
/// candidat. [company] est `null` pour un compte de démonstration (aucune
/// ligne `employer_profiles`), la ligne s'affiche alors en générique et
/// non cliquable.
class ProfileViewer {
  const ProfileViewer({required this.viewedAt, this.company});

  final DateTime viewedAt;
  final CompanySearchResult? company;
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

    final like = '%${term.toLowerCase()}%';
    return _fetchJobSeekers(
      whereClause: '''
        AND (
          LOWER(jsp.prenom) LIKE ? OR
          LOWER(jsp.nom) LIKE ? OR
          LOWER(jsp.titre_professionnel) LIKE ? OR
          LOWER(jsp.localisation) LIKE ? OR
          LOWER(jss.name) LIKE ?
        )
      ''',
      whereArgs: [like, like, like, like, like],
    );
  }

  /// Tous les candidats réellement inscrits et dont le profil est visible
  /// (`job_seeker_profiles.profil_visible = 1`) — sans filtre de texte.
  /// Alimente "Candidats suggérés" de `EmployerDashboard`, qui affiche
  /// désormais l'ensemble des inscrits (les plus pertinents pour les offres
  /// du recruteur en tête, voir `EmployerDashboard._loadSuggestedCandidates`).
  Future<List<CandidateSearchResult>> fetchAllJobSeekers() {
    return _fetchJobSeekers(whereClause: '', whereArgs: const []);
  }

  /// Profil complet (portfolio compris) d'un candidat précis — utilisé par
  /// `CandidateApplicationDetailScreen` pour montrer au recruteur le
  /// portfolio de quelqu'un qui a postulé à l'une de ses offres. Ignore
  /// volontairement `profil_visible` : masquer son profil de la recherche
  /// n'empêche pas le recruteur à qui l'on a soi-même envoyé sa candidature
  /// de le consulter. `null` si aucun compte réel ne correspond (comptes de
  /// démo, id négatif sans ligne `users`).
  Future<CandidateSearchResult?> fetchJobSeekerById(String userId) async {
    final id = int.tryParse(userId);
    if (id == null) return null;
    final results = await _fetchJobSeekers(
      whereClause: 'AND u.id = ?',
      whereArgs: [id],
      onlyVisible: false,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<List<CandidateSearchResult>> _fetchJobSeekers({
    required String whereClause,
    required List<Object?> whereArgs,
    bool onlyVisible = true,
  }) async {
    final db = await AppDatabase.instance.database;
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
        jsp.objectifs AS objectifs,
        jsp.portfolio_theme_color AS portfolio_theme_color,
        jsp.photo AS photo
      FROM users u
      INNER JOIN job_seeker_profiles jsp ON jsp.user_id = u.id
      LEFT JOIN job_seeker_skills jss ON jss.user_id = u.id
      WHERE u.role = 'job_seeker'
        ${onlyVisible ? 'AND jsp.profil_visible = 1' : ''}
        $whereClause
      ORDER BY jsp.prenom ASC
      ''',
      whereArgs,
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

    final portfolioRows = await db.query(
      'job_seeker_portfolio_projects',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
      orderBy: 'created_at DESC',
    );
    final portfolioByUserId = <int, List<PortfolioProject>>{};
    for (final row in portfolioRows) {
      final userId = row['user_id'] as int;
      (portfolioByUserId[userId] ??= []).add(PortfolioProject.fromRow(row));
    }

    final formationRows = await db.query(
      'job_seeker_formations',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
    final formationsByUserId = <int, List<Formation>>{};
    for (final row in formationRows) {
      final userId = row['user_id'] as int;
      (formationsByUserId[userId] ??= []).add(Formation.fromRow(row));
    }

    final certificationRows = await db.query(
      'job_seeker_certifications',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
    final certificationsByUserId = <int, List<Certification>>{};
    for (final row in certificationRows) {
      final userId = row['user_id'] as int;
      (certificationsByUserId[userId] ??= []).add(Certification.fromRow(row));
    }

    final linkRows = await db.query(
      'job_seeker_professional_links',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
    final linksByUserId = <int, List<ProfessionalLink>>{};
    for (final row in linkRows) {
      final userId = row['user_id'] as int;
      (linksByUserId[userId] ??= []).add(ProfessionalLink.fromRow(row));
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
        objectifs: row['objectifs'] as String?,
        portfolioThemeColor: row['portfolio_theme_color'] as String?,
        photo: row['photo'] as Uint8List?,
        skills: skillsByUserId[userId] ?? const [],
        experiences: experiencesByUserId[userId] ?? const [],
        portfolioProjects: portfolioByUserId[userId] ?? const [],
        formations: formationsByUserId[userId] ?? const [],
        certifications: certificationsByUserId[userId] ?? const [],
        professionalLinks: linksByUserId[userId] ?? const [],
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
        AND ep.entreprise_visible = 1
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

  /// Efface tout l'historique de recherche de [userId] pour [searchType] —
  /// utilisé par "Effacer l'historique de recherche" de
  /// `JobSeekerSettingsScreen`/`EmployerSettingsScreen`.
  Future<void> clearHistory({
    required String userId,
    required String searchType,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'search_history',
      where: 'user_id = ? AND search_type = ?',
      whereArgs: [userId, searchType],
    );
  }

  /// Enregistre qu'un recruteur ([viewerUserId]) a ouvert le profil du
  /// candidat [profileUserId] (`CandidateProfileViewScreen`) — au plus une
  /// vue par couple (profil, recruteur) grâce à `UNIQUE`, un recruteur qui
  /// rouvre le même profil ne regonfle pas le compteur. Alimente le
  /// compteur "N vues du profil" de `JobProfileScreen`. À n'appeler que
  /// lorsqu'un recruteur consulte le profil d'un *autre* utilisateur
  /// (l'appelant filtre : jamais ses propres vues).
  Future<void> recordProfileView({
    required String profileUserId,
    required String viewerUserId,
  }) async {
    if (profileUserId == viewerUserId) return;
    final db = await AppDatabase.instance.database;
    await db.insert(
      'job_seeker_profile_views',
      {
        'profile_user_id': profileUserId,
        'viewer_user_id': viewerUserId,
        'viewed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Nombre de recruteurs distincts ayant consulté le profil de
  /// [profileUserId] — compteur "N vues du profil" de `JobProfileScreen` et
  /// stat "Vues du profil" du panneau latéral candidat.
  Future<int> countProfileViews(String profileUserId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM job_seeker_profile_views WHERE profile_user_id = ?',
      [profileUserId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Recruteurs ayant consulté le profil de [profileUserId], la vue la plus
  /// récente en premier — page "Vues du profil" du panneau latéral candidat.
  Future<List<ProfileViewer>> fetchProfileViewers(String profileUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT v.viewer_user_id AS viewer_user_id,
             v.viewed_at AS viewed_at,
             ep.nom_entreprise AS nom_entreprise,
             ep.nom AS nom,
             ep.prenom AS prenom,
             ep.localisation AS localisation,
             ep.telephone AS telephone,
             ep.description AS description,
             ep.logo AS logo
      FROM job_seeker_profile_views v
      LEFT JOIN employer_profiles ep
        ON ep.user_id = CAST(v.viewer_user_id AS INTEGER)
      WHERE v.profile_user_id = ?
      ORDER BY v.viewed_at DESC
      ''',
      [profileUserId],
    );

    return rows.map((row) {
      final viewedAt =
          DateTime.tryParse(row['viewed_at'] as String? ?? '') ?? DateTime.now();
      final companyName = (row['nom_entreprise'] as String?)?.trim() ?? '';
      if (companyName.isEmpty) {
        return ProfileViewer(viewedAt: viewedAt);
      }
      final contactName =
          '${(row['prenom'] as String?)?.trim() ?? ''} ${(row['nom'] as String?)?.trim() ?? ''}'
              .trim();
      return ProfileViewer(
        viewedAt: viewedAt,
        company: CompanySearchResult(
          userId: (row['viewer_user_id'] as String?) ?? '',
          companyName: companyName,
          contactName: contactName.isEmpty ? null : contactName,
          localisation: (row['localisation'] as String?)?.trim(),
          telephone: (row['telephone'] as String?)?.trim(),
          description: (row['description'] as String?)?.trim(),
          logo: row['logo'] as Uint8List?,
        ),
      );
    }).toList();
  }
}
