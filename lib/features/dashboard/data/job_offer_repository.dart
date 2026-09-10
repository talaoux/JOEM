import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'package:joem/core/database/app_database.dart';

const List<String> _shortMonths = [
  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
  'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
];

/// Heure/date lisible relative à maintenant : "À l'instant", "Il y a 12
/// min", "Aujourd'hui à 14:32", "Hier à 09:10", ou "12 Juil à 16:05"
/// au-delà — partagée par `JobOffer.publishedLabel` et
/// `JobApplicationNotification.timeLabel`.
String _relativeTimeLabel(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  final time =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';

  final isSameDay = now.year == dateTime.year &&
      now.month == dateTime.month &&
      now.day == dateTime.day;
  if (isSameDay) return "Aujourd'hui à $time";

  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = yesterday.year == dateTime.year &&
      yesterday.month == dateTime.month &&
      yesterday.day == dateTime.day;
  if (isYesterday) return 'Hier à $time';

  return '${dateTime.day} ${_shortMonths[dateTime.month - 1]} à $time';
}

/// Une offre d'emploi réellement publiée par un recruteur (`job_offers`),
/// visible par tous les chercheurs d'emploi — pas une carte mockée.
class JobOffer {
  const JobOffer({
    required this.id,
    required this.employerUserId,
    required this.companyName,
    this.companyLogo,
    required this.title,
    required this.description,
    required this.location,
    required this.salary,
    required this.contractType,
    this.posterImage,
    required this.createdAt,
  });

  final int id;
  final int employerUserId;
  final String companyName;
  final Uint8List? companyLogo;
  final String title;
  final String description;
  final String location;
  final String salary;
  final String contractType;

  /// Affiche (image) jointe par le recruteur à la publication — optionnelle,
  /// affichée sous la description sur la carte façon post du dashboard
  /// candidat. `null` si le recruteur n'en a pas ajouté.
  final Uint8List? posterImage;
  final DateTime createdAt;

  /// Heure/date de publication lisible : "À l'instant", "Il y a 12 min",
  /// "Aujourd'hui à 14:32", "Hier à 09:10", ou "12 Juil à 16:05" au-delà.
  String get publishedLabel => _relativeTimeLabel(createdAt);
}

/// Une offre publiée, vue comme notification pour un chercheur d'emploi
/// précis — combine [offer] (partagée par tous) et [isRead] (propre à ce
/// candidat, `job_offer_notification_reads`). Il n'existe pas de ligne de
/// notification distincte : chaque offre publiée EST une notification pour
/// tout chercheur d'emploi qui ne l'a pas supprimée.
class JobOfferNotification {
  const JobOfferNotification({required this.offer, required this.isRead});

  final JobOffer offer;
  final bool isRead;

  String get title => 'Nouvelle offre : ${offer.title}';

  String get message =>
      '${offer.companyName} recrute pour un poste de ${offer.title}'
      '${offer.location.isNotEmpty ? ' à ${offer.location}' : ''}.';
}

/// Une candidature reçue (`job_applications`), vue comme notification pour
/// le recruteur propriétaire de l'offre — même principe que
/// [JobOfferNotification] côté candidat : pas de ligne de notification
/// distincte, chaque candidature EST une notification pour le recruteur
/// concerné (celui qui a publié l'offre visée).
class JobApplicationNotification {
  const JobApplicationNotification({
    required this.applicationId,
    required this.jobSeekerUserId,
    required this.offer,
    required this.candidateName,
    this.candidatePosition,
    required this.appliedAt,
    required this.isRead,
  });

  final int applicationId;

  /// Id du candidat ayant postulé — utilisé par
  /// `CandidateApplicationDetailScreen` pour compléter [candidateName]/
  /// [candidatePosition] avec le reste de son profil réel via
  /// `JobOfferRepository.fetchJobSeekerProfileSummary`.
  final String jobSeekerUserId;
  final JobOffer offer;
  final String candidateName;
  final String? candidatePosition;
  final DateTime appliedAt;
  final bool isRead;

  String get title => 'Nouvelle candidature reçue';

  String get message {
    final position = candidatePosition?.trim();
    final displayName = candidateName.trim().isNotEmpty ? candidateName.trim() : 'Un candidat';
    return (position != null && position.isNotEmpty)
        ? '$displayName ($position) a postulé pour ${offer.title}.'
        : '$displayName a postulé pour ${offer.title}.';
  }

  String get timeLabel => _relativeTimeLabel(appliedAt);
}

/// Une vue enregistrée sur une offre du recruteur (`job_offer_views`) —
/// affichée par la page "Vues totales" du "Tableau de bord" recruteur.
/// [viewerName] retombe sur "Un candidat" pour un compte de démo (aucune
/// ligne `job_seeker_profiles`).
class OfferView {
  const OfferView({
    required this.offerId,
    required this.offerTitle,
    required this.viewerName,
    this.viewerPosition,
    this.viewerPhoto,
    required this.viewedAt,
  });

  final int offerId;
  final String offerTitle;
  final String viewerName;
  final String? viewerPosition;
  final Uint8List? viewerPhoto;
  final DateTime viewedAt;

  String get timeLabel => _relativeTimeLabel(viewedAt);
}

/// Compléments du profil d'un candidat au-delà du nom/poste dupliqués sur
/// `job_applications` — affiché par `CandidateApplicationDetailScreen`
/// quand disponible. Reste `null` pour un compte de démo (id négatif,
/// aucune ligne dans `users`/`job_seeker_profiles` à lire).
class JobSeekerProfileSummary {
  const JobSeekerProfileSummary({
    required this.firstName,
    required this.lastName,
    this.email,
    this.photo,
    this.telephone,
    this.localisation,
    this.presentation,
    this.skills = const [],
    this.cvFileName,
  });

  /// Nom/prénom réels et à jour du candidat (`job_seeker_profiles`) —
  /// prioritaires sur `JobApplicationNotification.candidateName`, qui
  /// n'est qu'un instantané pris au moment de la candidature (et reste
  /// vide pour les candidatures enregistrées avant l'ajout de ce champ).
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();

  /// Email du compte du candidat (`users.email`) — affiché avec le
  /// téléphone et la localisation dans les coordonnées de
  /// `CandidateApplicationDetailScreen`. `null` pour un compte de démo.
  final String? email;

  final Uint8List? photo;
  final String? telephone;
  final String? localisation;
  final String? presentation;
  final List<String> skills;

  /// Nom du fichier CV attaché au profil (`null` si aucun) — les octets
  /// eux-mêmes ne sont volontairement pas chargés ici (voir
  /// `JobOfferRepository.fetchJobSeekerCv`, chargés à la demande
  /// uniquement, pour ne pas cumuler photo + CV dans le même appel de
  /// plateforme Android et risquer une `TransactionTooLargeException`).
  final String? cvFileName;
}

/// Le fichier CV réel d'un candidat (octets + nom), renvoyé par
/// [JobOfferRepository.fetchJobSeekerCv] — chargé isolément du reste du
/// profil (voir [JobSeekerProfileSummary.cvFileName]).
class JobSeekerCvFile {
  const JobSeekerCvFile({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  bool get isImage {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }
}

/// Accès à la persistance SQLite pour les offres d'emploi (`job_offers`,
/// voir `lib/core/database/app_database.dart`). Toute offre publiée par
/// un recruteur est visible par tous les chercheurs d'emploi via
/// [fetchAll] — pas de filtrage par métier recherché.
class JobOfferRepository {
  const JobOfferRepository();

  Future<JobOffer> publish({
    required int employerUserId,
    required String companyName,
    Uint8List? companyLogo,
    required String title,
    required String description,
    required String location,
    required String salary,
    required String contractType,
    Uint8List? posterImage,
  }) async {
    final db = await AppDatabase.instance.database;
    final createdAt = DateTime.now();

    final id = await db.insert('job_offers', {
      'employer_user_id': employerUserId,
      'company_name': companyName,
      'company_logo': companyLogo,
      'title': title,
      'description': description,
      'location': location,
      'salary': salary,
      'contract_type': contractType,
      'poster_image': posterImage,
      'created_at': createdAt.toIso8601String(),
    });

    return JobOffer(
      id: id,
      employerUserId: employerUserId,
      companyName: companyName,
      companyLogo: companyLogo,
      title: title,
      description: description,
      location: location,
      salary: salary,
      contractType: contractType,
      posterImage: posterImage,
      createdAt: createdAt,
    );
  }

  /// Toutes les offres publiées, tous recruteurs confondus, les plus
  /// récentes en premier — c'est ce que voit un chercheur d'emploi, quel
  /// que soit le métier qu'il recherche.
  Future<List<JobOffer>> fetchAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('job_offers', orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  /// Offres publiées visibles par un candidat précis : comme [fetchAll],
  /// mais sans celles qu'il a masquées de son propre fil via le "X" de la
  /// carte "Recommandées pour vous" (`job_offer_notification_reads.is_deleted`
  /// — même mécanisme que "Supprimer" dans `JobNotificationsScreen`, un
  /// masquage propre à ce candidat, l'offre reste visible par les autres).
  Future<List<JobOffer>> fetchAllForJobSeeker(String jobSeekerUserId) async {
    final offers = await fetchAll();
    final stateRows = await (await AppDatabase.instance.database).query(
      'job_offer_notification_reads',
      where: 'job_seeker_user_id = ? AND is_deleted = 1',
      whereArgs: [jobSeekerUserId],
    );
    final dismissedIds = stateRows.map((row) => row['job_offer_id'] as int).toSet();
    return offers.where((offer) => !dismissedIds.contains(offer.id)).toList();
  }

  /// Offres publiées par des recruteurs dont l'entreprise appartient à
  /// [category] (`employer_profiles.categorie`, choisie à l'inscription
  /// recruteur, `kJobCategories`) — c'est ce que voit un candidat qui tape
  /// sur une catégorie dans `JobCategoriesScreen`/la grille "Catégories
  /// populaires" du dashboard. Les comptes de démo (id négatif, aucune
  /// ligne `employer_profiles`) n'ont pas de catégorie et n'apparaissent
  /// donc dans aucun filtre, comme le reste de la recherche de comptes
  /// (voir `AccountSearchRepository`).
  Future<List<JobOffer>> fetchByCategory(String category) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT jo.* FROM job_offers jo
      INNER JOIN employer_profiles ep ON ep.user_id = jo.employer_user_id
      WHERE ep.categorie = ?
      ORDER BY jo.created_at DESC
      ''',
      [category],
    );
    return rows.map(_fromRow).toList();
  }

  /// [fetchByCategory], sans les offres que ce candidat a masquées de son
  /// propre fil (même filtrage que [fetchAllForJobSeeker]).
  Future<List<JobOffer>> fetchByCategoryForJobSeeker(
    String category,
    String jobSeekerUserId,
  ) async {
    final offers = await fetchByCategory(category);
    final stateRows = await (await AppDatabase.instance.database).query(
      'job_offer_notification_reads',
      where: 'job_seeker_user_id = ? AND is_deleted = 1',
      whereArgs: [jobSeekerUserId],
    );
    final dismissedIds = stateRows.map((row) => row['job_offer_id'] as int).toSet();
    return offers.where((offer) => !dismissedIds.contains(offer.id)).toList();
  }

  /// Offres publiées par un recruteur précis — "Mes offres" côté
  /// `EmployerDashboard`.
  Future<List<JobOffer>> fetchByEmployer(int employerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'job_offers',
      where: 'employer_user_id = ?',
      whereArgs: [employerUserId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Notifications d'un chercheur d'emploi précis : toute offre publiée,
  /// tous recruteurs confondus, qu'il n'a pas supprimée — les plus
  /// récentes en premier, avec son propre état lu/non lue.
  Future<List<JobOfferNotification>> fetchNotificationsForJobSeeker(
    String jobSeekerUserId,
  ) async {
    final db = await AppDatabase.instance.database;
    final offerRows = await db.query('job_offers', orderBy: 'created_at DESC');
    final stateRows = await db.query(
      'job_offer_notification_reads',
      where: 'job_seeker_user_id = ?',
      whereArgs: [jobSeekerUserId],
    );
    final stateByOfferId = {
      for (final row in stateRows) row['job_offer_id'] as int: row,
    };

    final notifications = <JobOfferNotification>[];
    for (final row in offerRows) {
      final offerId = row['id'] as int;
      final state = stateByOfferId[offerId];
      final isDeleted = (state?['is_deleted'] as int? ?? 0) == 1;
      if (isDeleted) continue;
      final isRead = (state?['is_read'] as int? ?? 0) == 1;
      notifications.add(JobOfferNotification(offer: _fromRow(row), isRead: isRead));
    }
    return notifications;
  }

  /// Nombre d'offres publiées qu'un chercheur d'emploi n'a ni lues ni
  /// supprimées — alimente la pastille de compteur (header + nav basse).
  Future<int> countUnreadNotificationsForJobSeeker(String jobSeekerUserId) async {
    final notifications = await fetchNotificationsForJobSeeker(jobSeekerUserId);
    return notifications.where((n) => !n.isRead).length;
  }

  Future<void> markNotificationRead(int jobOfferId, String jobSeekerUserId) {
    return _setNotificationState(jobOfferId, jobSeekerUserId, isRead: true);
  }

  Future<void> markNotificationUnread(int jobOfferId, String jobSeekerUserId) {
    return _setNotificationState(jobOfferId, jobSeekerUserId, isRead: false);
  }

  Future<void> deleteNotification(int jobOfferId, String jobSeekerUserId) {
    return _setNotificationState(jobOfferId, jobSeekerUserId, isDeleted: true);
  }

  /// Marque comme lues toutes les offres actuellement non lues (et non
  /// supprimées) de ce chercheur d'emploi — "Tout marquer comme lu".
  Future<void> markAllNotificationsRead(String jobSeekerUserId) async {
    final notifications = await fetchNotificationsForJobSeeker(jobSeekerUserId);
    for (final notification in notifications.where((n) => !n.isRead)) {
      await markNotificationRead(notification.offer.id, jobSeekerUserId);
    }
  }

  /// Enregistre la candidature d'un chercheur d'emploi à une offre —
  /// appelé quand il clique "Postuler". Idempotent : re-cliquer sur une
  /// offre déjà postulée ne crée pas de doublon (`UNIQUE(job_offer_id,
  /// job_seeker_user_id)` sur `job_applications`, violation ignorée).
  /// [candidateName]/[candidatePosition] sont dupliqués sur la ligne (pris
  /// depuis `AuthService.currentUser` par l'appelant) plutôt que rejoints
  /// depuis un profil candidat, pour que la notification recruteur reste
  /// lisible même pour un compte de démo (sans ligne `users`) — voir
  /// `AppDatabase`, migration v6 -> v7.
  Future<void> apply({
    required int jobOfferId,
    required String jobSeekerUserId,
    required String candidateName,
    String? candidatePosition,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'job_applications',
      {
        'job_offer_id': jobOfferId,
        'job_seeker_user_id': jobSeekerUserId,
        'candidate_name': candidateName,
        'candidate_position': candidatePosition,
        'applied_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Retire la candidature du candidat connecté pour cette offre — permet
  /// d'annuler un "Postuler" envoyé par erreur. Supprime aussi la
  /// notification associée côté recruteur (`job_application_notification_reads`,
  /// `ON DELETE CASCADE` sur `job_application_id`).
  Future<void> withdrawApplication({
    required int jobOfferId,
    required String jobSeekerUserId,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'job_applications',
      where: 'job_offer_id = ? AND job_seeker_user_id = ?',
      whereArgs: [jobOfferId, jobSeekerUserId],
    );
  }

  /// `true` si ce chercheur d'emploi a déjà postulé à cette offre —
  /// utilisé pour afficher "Candidature envoyée" (bouton désactivé) au
  /// lieu de "Postuler".
  Future<bool> hasApplied(int jobOfferId, String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'job_applications',
      where: 'job_offer_id = ? AND job_seeker_user_id = ?',
      whereArgs: [jobOfferId, jobSeekerUserId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Identifiants de toutes les offres auxquelles ce chercheur d'emploi a
  /// déjà postulé — une seule requête pour marquer d'un coup toutes les
  /// cartes "Candidature envoyée" dans une liste (dashboard, recherche...).
  Future<Set<int>> fetchAppliedOfferIds(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'job_applications',
      columns: ['job_offer_id'],
      where: 'job_seeker_user_id = ?',
      whereArgs: [jobSeekerUserId],
    );
    return rows.map((row) => row['job_offer_id'] as int).toSet();
  }

  /// Nombre total de candidatures envoyées par ce chercheur d'emploi,
  /// tous recruteurs confondus — alimente "X candidatures envoyées" sur
  /// son profil.
  Future<int> countApplicationsForJobSeeker(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM job_applications WHERE job_seeker_user_id = ?',
      [jobSeekerUserId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Nombre total de candidatures reçues, toutes offres confondues, pour
  /// un recruteur précis — alimente la carte statistique "Candidatures"
  /// de `EmployerDashboard`.
  Future<int> countApplicantsForEmployer(int employerUserId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count FROM job_applications ja
      INNER JOIN job_offers jo ON jo.id = ja.job_offer_id
      WHERE jo.employer_user_id = ?
      ''',
      [employerUserId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Toutes les candidatures reçues sur les offres de ce recruteur, les
  /// plus récentes en premier, avec son propre état lu/supprimé — c'est ce
  /// que voit `EmployerNotificationsScreen`. Chaque candidature n'étant
  /// jamais visible que par un seul recruteur (celui qui a publié
  /// l'offre), l'état lu/supprimé porte directement sur `job_application_id`
  /// (contrairement à `fetchNotificationsForJobSeeker`, où une même offre
  /// est partagée par tous les candidats).
  Future<List<JobApplicationNotification>> fetchApplicationNotificationsForEmployer(
    int employerUserId,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        ja.id AS application_id,
        ja.job_seeker_user_id AS job_seeker_user_id,
        ja.candidate_name AS candidate_name,
        ja.candidate_position AS candidate_position,
        ja.applied_at AS applied_at,
        jo.id AS offer_id,
        jo.employer_user_id AS employer_user_id,
        jo.company_name AS company_name,
        jo.company_logo AS company_logo,
        jo.title AS title,
        jo.description AS description,
        jo.location AS location,
        jo.salary AS salary,
        jo.contract_type AS contract_type,
        jo.poster_image AS poster_image,
        jo.created_at AS created_at
      FROM job_applications ja
      INNER JOIN job_offers jo ON jo.id = ja.job_offer_id
      WHERE jo.employer_user_id = ?
      ORDER BY ja.applied_at DESC
      ''',
      [employerUserId],
    );
    if (rows.isEmpty) return [];

    final applicationIds = rows.map((row) => row['application_id'] as int).toList();
    final placeholders = List.filled(applicationIds.length, '?').join(',');
    final stateRows = await db.query(
      'job_application_notification_reads',
      where: 'job_application_id IN ($placeholders)',
      whereArgs: applicationIds,
    );
    final stateByApplicationId = {
      for (final row in stateRows) row['job_application_id'] as int: row,
    };

    final notifications = <JobApplicationNotification>[];
    for (final row in rows) {
      final applicationId = row['application_id'] as int;
      final state = stateByApplicationId[applicationId];
      final isDeleted = (state?['is_deleted'] as int? ?? 0) == 1;
      if (isDeleted) continue;
      final isRead = (state?['is_read'] as int? ?? 0) == 1;
      notifications.add(JobApplicationNotification(
        applicationId: applicationId,
        jobSeekerUserId: row['job_seeker_user_id'] as String,
        offer: JobOffer(
          id: row['offer_id'] as int,
          employerUserId: row['employer_user_id'] as int,
          companyName: row['company_name'] as String,
          companyLogo: row['company_logo'] as Uint8List?,
          title: row['title'] as String,
          description: row['description'] as String? ?? '',
          location: row['location'] as String? ?? '',
          salary: row['salary'] as String? ?? '',
          contractType: row['contract_type'] as String? ?? '',
          posterImage: row['poster_image'] as Uint8List?,
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
        candidateName: row['candidate_name'] as String? ?? '',
        candidatePosition: row['candidate_position'] as String?,
        appliedAt: DateTime.parse(row['applied_at'] as String),
        isRead: isRead,
      ));
    }
    return notifications;
  }

  /// Nombre de candidatures reçues par ce recruteur qu'il n'a ni lues ni
  /// supprimées — alimente la pastille de compteur (header + nav basse)
  /// de `EmployerDashboard`.
  Future<int> countUnreadApplicationNotificationsForEmployer(int employerUserId) async {
    final notifications = await fetchApplicationNotificationsForEmployer(employerUserId);
    return notifications.where((n) => !n.isRead).length;
  }

  Future<void> markApplicationNotificationRead(int applicationId) {
    return _setApplicationNotificationState(applicationId, isRead: true);
  }

  Future<void> markApplicationNotificationUnread(int applicationId) {
    return _setApplicationNotificationState(applicationId, isRead: false);
  }

  Future<void> deleteApplicationNotification(int applicationId) {
    return _setApplicationNotificationState(applicationId, isDeleted: true);
  }

  /// Marque comme lues toutes les candidatures actuellement non lues (et
  /// non supprimées) reçues par ce recruteur — "Tout marquer comme lu".
  Future<void> markAllApplicationNotificationsRead(int employerUserId) async {
    final notifications = await fetchApplicationNotificationsForEmployer(employerUserId);
    for (final notification in notifications.where((n) => !n.isRead)) {
      await markApplicationNotificationRead(notification.applicationId);
    }
  }

  Future<void> _setApplicationNotificationState(
    int applicationId, {
    bool? isRead,
    bool? isDeleted,
  }) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query(
      'job_application_notification_reads',
      where: 'job_application_id = ?',
      whereArgs: [applicationId],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('job_application_notification_reads', {
        'job_application_id': applicationId,
        'is_read': (isRead ?? true) ? 1 : 0,
        'is_deleted': (isDeleted ?? false) ? 1 : 0,
      });
      return;
    }

    final updates = <String, Object?>{
      if (isRead != null) 'is_read': isRead ? 1 : 0,
      if (isDeleted != null) 'is_deleted': isDeleted ? 1 : 0,
    };
    await db.update(
      'job_application_notification_reads',
      updates,
      where: 'job_application_id = ?',
      whereArgs: [applicationId],
    );
  }

  Future<void> _setNotificationState(
    int jobOfferId,
    String jobSeekerUserId, {
    bool? isRead,
    bool? isDeleted,
  }) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query(
      'job_offer_notification_reads',
      where: 'job_offer_id = ? AND job_seeker_user_id = ?',
      whereArgs: [jobOfferId, jobSeekerUserId],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('job_offer_notification_reads', {
        'job_offer_id': jobOfferId,
        'job_seeker_user_id': jobSeekerUserId,
        'is_read': (isRead ?? true) ? 1 : 0,
        'is_deleted': (isDeleted ?? false) ? 1 : 0,
      });
      return;
    }

    final updates = <String, Object?>{
      if (isRead != null) 'is_read': isRead ? 1 : 0,
      if (isDeleted != null) 'is_deleted': isDeleted ? 1 : 0,
    };
    await db.update(
      'job_offer_notification_reads',
      updates,
      where: 'job_offer_id = ? AND job_seeker_user_id = ?',
      whereArgs: [jobOfferId, jobSeekerUserId],
    );
  }

  /// Complète le nom/poste déjà connus d'une candidature avec le reste du
  /// profil du candidat (téléphone, localisation, présentation,
  /// compétences) — `null` si ce candidat est un compte de démo (id
  /// négatif) ou si son profil n'a plus de ligne (compte supprimé).
  Future<JobSeekerProfileSummary?> fetchJobSeekerProfileSummary(
    String jobSeekerUserId,
  ) async {
    final userId = int.tryParse(jobSeekerUserId);
    if (userId == null || userId <= 0) return null;

    final db = await AppDatabase.instance.database;
    // `cv_bytes` volontairement exclu (voir `JobSeekerProfileSummary.cvFileName`
    // et `AuthService._buildUserFromRow` pour le même correctif côté connexion) :
    // combiné à `photo`, il peut dépasser la limite d'un appel de plateforme
    // Android (~1 Mo) et faire échouer cet écran silencieusement.
    final profileRows = await db.query(
      'job_seeker_profiles',
      columns: [
        'prenom', 'nom', 'photo', 'telephone', 'localisation', 'presentation', 'cv_file_name',
      ],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (profileRows.isEmpty) return null;
    final profile = profileRows.first;

    final skillRows = await db.query(
      'job_seeker_skills',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final userRows = await db.query(
      'users',
      columns: ['email'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final email = userRows.isNotEmpty ? userRows.first['email'] as String? : null;

    return JobSeekerProfileSummary(
      firstName: profile['prenom'] as String? ?? '',
      lastName: profile['nom'] as String? ?? '',
      email: email,
      photo: profile['photo'] as Uint8List?,
      telephone: profile['telephone'] as String?,
      localisation: profile['localisation'] as String?,
      presentation: profile['presentation'] as String?,
      skills: skillRows.map((row) => row['name'] as String).toList(),
      cvFileName: profile['cv_file_name'] as String?,
    );
  }

  /// Charge le fichier CV réel (octets) d'un candidat — appelé à la
  /// demande (bouton "Voir le CV") plutôt qu'avec le reste du profil, pour
  /// n'ouvrir ce fichier qu'au moment où le recruteur veut vraiment le
  /// voir. Le CV vit sur le disque (`cv_path`), pas en BLOB dans SQLite,
  /// donc lu via `dart:io` plutôt qu'en base — aucune limite de taille de
  /// ce type (voir `AppDatabase`, migration v10 -> v11). `null` si ce
  /// candidat n'a pas de CV, est un compte de démo, n'a plus de profil, ou
  /// si le fichier a disparu du disque entre-temps.
  Future<JobSeekerCvFile?> fetchJobSeekerCv(String jobSeekerUserId) async {
    final userId = int.tryParse(jobSeekerUserId);
    if (userId == null || userId <= 0) return null;

    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'job_seeker_profiles',
      columns: ['cv_path', 'cv_file_name'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final path = rows.first['cv_path'] as String?;
    final fileName = rows.first['cv_file_name'] as String?;
    if (path == null || fileName == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    return JobSeekerCvFile(bytes: await file.readAsBytes(), fileName: fileName);
  }

  /// Enregistre cette offre pour le candidat connecté ("..." -> "Enregistrer
  /// publication" sur la carte) — idempotent (`UNIQUE(job_offer_id,
  /// job_seeker_user_id)`, violation ignorée).
  Future<void> saveOffer(int jobOfferId, String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'job_offer_saves',
      {
        'job_offer_id': jobOfferId,
        'job_seeker_user_id': jobSeekerUserId,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Retire cette offre des publications enregistrées de ce candidat.
  Future<void> unsaveOffer(int jobOfferId, String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'job_offer_saves',
      where: 'job_offer_id = ? AND job_seeker_user_id = ?',
      whereArgs: [jobOfferId, jobSeekerUserId],
    );
  }

  /// Ids de toutes les offres que ce candidat a enregistrées — une seule
  /// requête pour marquer d'un coup toutes les cartes "Enregistré" dans une
  /// liste, comme [fetchAppliedOfferIds].
  Future<Set<int>> fetchSavedOfferIds(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'job_offer_saves',
      columns: ['job_offer_id'],
      where: 'job_seeker_user_id = ?',
      whereArgs: [jobSeekerUserId],
    );
    return rows.map((row) => row['job_offer_id'] as int).toSet();
  }

  /// Offres auxquelles ce chercheur d'emploi a postulé (`job_applications`
  /// jointe à `job_offers`), la candidature la plus récente en premier —
  /// page "Candidatures envoyées" ouverte depuis la stat du panneau latéral
  /// candidat (`ProfileSidePanel`).
  Future<List<JobOffer>> fetchAppliedOffers(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT jo.* FROM job_offers jo
      INNER JOIN job_applications ja ON ja.job_offer_id = jo.id
      WHERE ja.job_seeker_user_id = ?
      ORDER BY ja.applied_at DESC
      ''',
      [jobSeekerUserId],
    );
    return rows.map(_fromRow).toList();
  }

  /// Offres que ce chercheur d'emploi a mises en favori (`job_offer_saves`
  /// jointe à `job_offers`), la plus récemment enregistrée en premier —
  /// page "Favoris" ouverte depuis la stat du panneau latéral candidat.
  Future<List<JobOffer>> fetchSavedOffers(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT jo.* FROM job_offers jo
      INNER JOIN job_offer_saves jos ON jos.job_offer_id = jo.id
      WHERE jos.job_seeker_user_id = ?
      ORDER BY jos.saved_at DESC
      ''',
      [jobSeekerUserId],
    );
    return rows.map(_fromRow).toList();
  }

  /// Retire toutes les offres enregistrées de ce candidat — "Vider mes
  /// offres enregistrées" de `JobSeekerSettingsScreen`.
  Future<void> clearSavedOffers(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'job_offer_saves',
      where: 'job_seeker_user_id = ?',
      whereArgs: [jobSeekerUserId],
    );
  }

  /// Enregistre qu'un candidat a ouvert le détail de cette offre — au plus
  /// une vue par couple (offre, candidat) grâce à `UNIQUE`, un candidat qui
  /// rouvre la même offre ne regonfle pas le compteur. Alimente la carte
  /// "Vues totales" de `EmployerDashboard`. Ne compte pas les vues du
  /// recruteur sur sa propre offre (l'appelant filtre : seul un candidat
  /// connecté appelle cette méthode).
  Future<void> recordOfferView(int jobOfferId, String viewerUserId) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'job_offer_views',
      {
        'job_offer_id': jobOfferId,
        'viewer_user_id': viewerUserId,
        'viewed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Nombre total de vues (candidats distincts) sur toutes les offres de ce
  /// recruteur — carte statistique "Vues totales" de `EmployerDashboard`.
  Future<int> countOfferViewsForEmployer(int employerUserId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count FROM job_offer_views jov
      INNER JOIN job_offers jo ON jo.id = jov.job_offer_id
      WHERE jo.employer_user_id = ?
      ''',
      [employerUserId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Détail des vues sur les offres de ce recruteur (`job_offer_views`
  /// jointe à `job_offers` et, si le viewer est un compte inscrit, à
  /// `job_seeker_profiles`) — la vue la plus récente en premier. Alimente
  /// la page "Vues totales" ouverte depuis la carte du "Tableau de bord"
  /// et du panneau latéral recruteur.
  Future<List<OfferView>> fetchOfferViewsForEmployer(int employerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        jo.id AS offer_id,
        jo.title AS offer_title,
        jov.viewed_at AS viewed_at,
        jsp.prenom AS prenom,
        jsp.nom AS nom,
        jsp.titre_professionnel AS titre_professionnel,
        jsp.photo AS photo
      FROM job_offer_views jov
      INNER JOIN job_offers jo ON jo.id = jov.job_offer_id
      LEFT JOIN job_seeker_profiles jsp
        ON jsp.user_id = CAST(jov.viewer_user_id AS INTEGER)
      WHERE jo.employer_user_id = ?
      ORDER BY jov.viewed_at DESC
      ''',
      [employerUserId],
    );
    return rows.map((row) {
      final prenom = (row['prenom'] as String?)?.trim() ?? '';
      final nom = (row['nom'] as String?)?.trim() ?? '';
      final name = '$prenom $nom'.trim();
      return OfferView(
        offerId: row['offer_id'] as int,
        offerTitle: row['offer_title'] as String? ?? '',
        viewerName: name.isEmpty ? 'Un candidat' : name,
        viewerPosition: (row['titre_professionnel'] as String?)?.trim(),
        viewerPhoto: row['photo'] as Uint8List?,
        viewedAt:
            DateTime.tryParse(row['viewed_at'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  /// Nombre de candidatures reçues, offre par offre, pour ce recruteur —
  /// une seule requête pour afficher le compteur sur chaque carte de "Mes
  /// offres d'emploi" sans une requête par offre.
  Future<Map<int, int>> fetchApplicantCountsByOffer(int employerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT ja.job_offer_id AS offer_id, COUNT(*) AS count
      FROM job_applications ja
      INNER JOIN job_offers jo ON jo.id = ja.job_offer_id
      WHERE jo.employer_user_id = ?
      GROUP BY ja.job_offer_id
      ''',
      [employerUserId],
    );
    return {
      for (final row in rows) row['offer_id'] as int: row['count'] as int,
    };
  }

  /// Toutes les candidatures reçues sur une offre précise, les plus
  /// récentes en premier — c'est ce qu'affiche `OfferApplicantsScreen`
  /// quand le recruteur tape sur une offre de "Mes offres d'emploi".
  /// Contrairement à [fetchApplicationNotificationsForEmployer], n'exclut
  /// pas les candidatures marquées "supprimées" côté notifications : le
  /// recruteur veut voir tous les postulants d'une offre.
  Future<List<JobApplicationNotification>> fetchApplicationsForOffer(int jobOfferId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        ja.id AS application_id,
        ja.job_seeker_user_id AS job_seeker_user_id,
        ja.candidate_name AS candidate_name,
        ja.candidate_position AS candidate_position,
        ja.applied_at AS applied_at,
        jo.id AS offer_id,
        jo.employer_user_id AS employer_user_id,
        jo.company_name AS company_name,
        jo.company_logo AS company_logo,
        jo.title AS title,
        jo.description AS description,
        jo.location AS location,
        jo.salary AS salary,
        jo.contract_type AS contract_type,
        jo.poster_image AS poster_image,
        jo.created_at AS created_at
      FROM job_applications ja
      INNER JOIN job_offers jo ON jo.id = ja.job_offer_id
      WHERE ja.job_offer_id = ?
      ORDER BY ja.applied_at DESC
      ''',
      [jobOfferId],
    );
    if (rows.isEmpty) return [];

    final applicationIds = rows.map((row) => row['application_id'] as int).toList();
    final placeholders = List.filled(applicationIds.length, '?').join(',');
    final stateRows = await db.query(
      'job_application_notification_reads',
      where: 'job_application_id IN ($placeholders)',
      whereArgs: applicationIds,
    );
    final readByApplicationId = {
      for (final row in stateRows) row['job_application_id'] as int: (row['is_read'] as int? ?? 0) == 1,
    };

    return rows.map((row) {
      final applicationId = row['application_id'] as int;
      return JobApplicationNotification(
        applicationId: applicationId,
        jobSeekerUserId: row['job_seeker_user_id'] as String,
        offer: _fromRow({
          'id': row['offer_id'],
          'employer_user_id': row['employer_user_id'],
          'company_name': row['company_name'],
          'company_logo': row['company_logo'],
          'title': row['title'],
          'description': row['description'],
          'location': row['location'],
          'salary': row['salary'],
          'contract_type': row['contract_type'],
          'poster_image': row['poster_image'],
          'created_at': row['created_at'],
        }),
        candidateName: row['candidate_name'] as String? ?? '',
        candidatePosition: row['candidate_position'] as String?,
        appliedAt: DateTime.parse(row['applied_at'] as String),
        isRead: readByApplicationId[applicationId] ?? false,
      );
    }).toList();
  }

  /// Supprime définitivement une offre publiée par le recruteur — "Mes
  /// offres d'emploi", appui long ou menu "Supprimer". Les candidatures,
  /// enregistrements, états de notification et vues liés partent en cascade
  /// (`ON DELETE CASCADE`). Les entretiens déjà planifiés restent (aucune
  /// FK, `offer_title` dupliqué — voir `AppDatabase` migration v18 -> v19).
  Future<void> deleteOffer(int jobOfferId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('job_offers', where: 'id = ?', whereArgs: [jobOfferId]);
  }

  JobOffer _fromRow(Map<String, Object?> row) {
    return JobOffer(
      id: row['id'] as int,
      employerUserId: row['employer_user_id'] as int,
      companyName: row['company_name'] as String,
      companyLogo: row['company_logo'] as Uint8List?,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      location: row['location'] as String? ?? '',
      salary: row['salary'] as String? ?? '',
      contractType: row['contract_type'] as String? ?? '',
      posterImage: row['poster_image'] as Uint8List?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
