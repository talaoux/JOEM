import 'package:joem/core/database/app_database.dart';

const List<String> _shortMonths = [
  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
  'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
];

/// Modes d'entretien proposés à la planification (`ScheduleInterviewScreen`).
class InterviewMode {
  static const String presentiel = 'presentiel';
  static const String visio = 'visio';
}

/// Statuts d'un entretien.
class InterviewStatus {
  static const String scheduled = 'scheduled';
  static const String done = 'done';
  static const String cancelled = 'cancelled';
}

/// Un entretien réellement planifié par un recruteur pour un candidat qui a
/// postulé (`interviews`). Créé depuis `CandidateApplicationDetailScreen`
/// via `ScheduleInterviewScreen`, affiché sur `EmployerDashboard`
/// ("Entretiens du jour"/"Mes prochains entretiens" + carte statistique).
class Interview {
  const Interview({
    required this.id,
    required this.employerUserId,
    this.jobApplicationId,
    this.jobOfferId,
    required this.jobSeekerUserId,
    required this.candidateName,
    required this.offerTitle,
    required this.date,
    required this.time,
    this.location,
    required this.mode,
    this.notes,
    required this.status,
    required this.createdAt,
    this.seekerRead = false,
    this.revision = 0,
    DateTime? notifiedAt,
  }) : notifiedAt = notifiedAt ?? createdAt;

  final int id;
  final int employerUserId;
  final int? jobApplicationId;
  final int? jobOfferId;
  final String jobSeekerUserId;
  final String candidateName;
  final String offerTitle;

  /// Jour de l'entretien (heure à minuit) — combiné à [time] pour
  /// [scheduledDateTime].
  final DateTime date;

  /// Heure de l'entretien au format 'HH:mm'.
  final String time;

  /// Adresse (présentiel) ou lien/plateforme (visio) — peut être vide.
  final String? location;

  /// [InterviewMode.presentiel] ou [InterviewMode.visio].
  final String mode;
  final String? notes;

  /// [InterviewStatus.scheduled] / [InterviewStatus.done] /
  /// [InterviewStatus.cancelled].
  final String status;
  final DateTime createdAt;

  /// `true` si le candidat a déjà lu la notification "L'entreprise souhaite
  /// vous rencontrer" pour cet entretien (`interviews.seeker_read`).
  final bool seekerRead;

  /// Nombre de fois où le recruteur a modifié cet entretien après l'avoir
  /// planifié (`interviews.revision`). `0` = jamais modifié → notification
  /// "Proposition d'entretien" ; `> 0` → "Entretien modifié".
  final int revision;

  /// Horodatage de la dernière chose que le candidat doit savoir sur cet
  /// entretien : sa planification, ou sa dernière modification
  /// (`interviews.notified_at`). Sert à trier `JobNotificationsScreen` et à
  /// dater la notification.
  final DateTime notifiedAt;

  bool get isModified => revision > 0;

  bool get isVisio => mode == InterviewMode.visio;

  /// Date + heure combinées — utilisé pour trier et distinguer les
  /// entretiens à venir de ceux déjà passés.
  DateTime get scheduledDateTime {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// "15 Jan 2026".
  String get dateLabel => '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';

  /// Libellé de lieu affiché sur la carte : le lieu saisi, ou un texte
  /// générique selon le mode s'il est vide.
  String get locationLabel {
    final trimmed = location?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return isVisio ? 'Visioconférence' : 'Lieu à préciser';
  }
}

/// Accès à la persistance SQLite des entretiens (`interviews`, voir
/// `lib/core/database/app_database.dart`).
class InterviewRepository {
  const InterviewRepository();

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Interview> schedule({
    required int employerUserId,
    int? jobApplicationId,
    int? jobOfferId,
    required String jobSeekerUserId,
    required String candidateName,
    required String offerTitle,
    required DateTime date,
    required String time,
    String? location,
    required String mode,
    String? notes,
  }) async {
    final db = await AppDatabase.instance.database;
    final createdAt = DateTime.now();
    final dateKey = _dateKey(date);

    final id = await db.insert('interviews', {
      'employer_user_id': employerUserId,
      'job_application_id': jobApplicationId,
      'job_offer_id': jobOfferId,
      'job_seeker_user_id': jobSeekerUserId,
      'candidate_name': candidateName,
      'offer_title': offerTitle,
      'scheduled_date': dateKey,
      'scheduled_time': time,
      'location': location,
      'mode': mode,
      'notes': notes,
      'status': InterviewStatus.scheduled,
      'created_at': createdAt.toIso8601String(),
      'notified_at': createdAt.toIso8601String(),
      'revision': 0,
    });

    return Interview(
      id: id,
      employerUserId: employerUserId,
      jobApplicationId: jobApplicationId,
      jobOfferId: jobOfferId,
      jobSeekerUserId: jobSeekerUserId,
      candidateName: candidateName,
      offerTitle: offerTitle,
      date: DateTime(date.year, date.month, date.day),
      time: time,
      location: location,
      mode: mode,
      notes: notes,
      status: InterviewStatus.scheduled,
      createdAt: createdAt,
      notifiedAt: createdAt,
    );
  }

  /// Met à jour un entretien déjà planifié (re-planification depuis
  /// `ScheduleInterviewScreen` quand un entretien existe déjà pour la
  /// candidature). Incrémente `revision` et repositionne `notified_at` :
  /// la notification du candidat repasse en non-lue, change de libellé
  /// ("Entretien modifié") et remonte en tête de `JobNotificationsScreen`.
  Future<void> update({
    required int id,
    required DateTime date,
    required String time,
    String? location,
    required String mode,
    String? notes,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.rawUpdate(
      '''
      UPDATE interviews SET
        scheduled_date = ?,
        scheduled_time = ?,
        location = ?,
        mode = ?,
        notes = ?,
        status = ?,
        seeker_read = 0,
        seeker_deleted = 0,
        revision = revision + 1,
        notified_at = ?
      WHERE id = ?
      ''',
      [
        _dateKey(date),
        time,
        location,
        mode,
        notes,
        InterviewStatus.scheduled,
        DateTime.now().toIso8601String(),
        id,
      ],
    );
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await AppDatabase.instance.database;
    await db.update('interviews', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> cancel(int id) => updateStatus(id, InterviewStatus.cancelled);

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('interviews', where: 'id = ?', whereArgs: [id]);
  }

  /// L'entretien lié à une candidature précise (`null` si aucun) — utilisé
  /// par `CandidateApplicationDetailScreen` pour basculer "Planifier un
  /// entretien" en "Voir l'entretien planifié".
  Future<Interview?> fetchByApplication(int jobApplicationId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'interviews',
      where: 'job_application_id = ? AND status != ?',
      whereArgs: [jobApplicationId, InterviewStatus.cancelled],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Tous les entretiens (non annulés) d'un recruteur, du plus proche au
  /// plus lointain.
  Future<List<Interview>> fetchForEmployer(int employerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'interviews',
      where: 'employer_user_id = ? AND status != ?',
      whereArgs: [employerUserId, InterviewStatus.cancelled],
    );
    final interviews = rows.map(_fromRow).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return interviews;
  }

  /// Entretiens planifiés aujourd'hui pour ce recruteur (quelle que soit
  /// l'heure, passée ou à venir dans la journée), triés par heure.
  Future<List<Interview>> fetchTodayForEmployer(int employerUserId) async {
    final db = await AppDatabase.instance.database;
    final todayKey = _dateKey(DateTime.now());
    final rows = await db.query(
      'interviews',
      where: 'employer_user_id = ? AND status = ? AND scheduled_date = ?',
      whereArgs: [employerUserId, InterviewStatus.scheduled, todayKey],
    );
    final interviews = rows.map(_fromRow).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return interviews;
  }

  /// Entretiens à venir (dès maintenant, aujourd'hui inclus) pour ce
  /// recruteur, du plus proche au plus lointain.
  Future<List<Interview>> fetchUpcomingForEmployer(int employerUserId) async {
    final now = DateTime.now();
    final all = await fetchForEmployer(employerUserId);
    return all
        .where((i) =>
            i.status == InterviewStatus.scheduled &&
            i.scheduledDateTime.isAfter(now.subtract(const Duration(minutes: 1))))
        .toList();
  }

  /// Nombre d'entretiens à venir — carte statistique "Entretiens" de
  /// `EmployerDashboard`.
  Future<int> countUpcomingForEmployer(int employerUserId) async {
    final upcoming = await fetchUpcomingForEmployer(employerUserId);
    return upcoming.length;
  }

  Interview _fromRow(Map<String, Object?> row) {
    final dateParts = (row['scheduled_date'] as String).split('-');
    final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
    final month = dateParts.length > 1 ? int.tryParse(dateParts[1]) ?? 1 : 1;
    final day = dateParts.length > 2 ? int.tryParse(dateParts[2]) ?? 1 : 1;

    return Interview(
      id: row['id'] as int,
      employerUserId: row['employer_user_id'] as int,
      jobApplicationId: row['job_application_id'] as int?,
      jobOfferId: row['job_offer_id'] as int?,
      jobSeekerUserId: row['job_seeker_user_id'] as String,
      candidateName: row['candidate_name'] as String? ?? '',
      offerTitle: row['offer_title'] as String? ?? '',
      date: DateTime(year, month, day),
      time: row['scheduled_time'] as String? ?? '00:00',
      location: row['location'] as String?,
      mode: row['mode'] as String? ?? InterviewMode.presentiel,
      notes: row['notes'] as String?,
      status: row['status'] as String? ?? InterviewStatus.scheduled,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      seekerRead: (row['seeker_read'] as int? ?? 0) == 1,
      revision: row['revision'] as int? ?? 0,
      notifiedAt: DateTime.tryParse(row['notified_at'] as String? ?? ''),
    );
  }

  // ===== Notifications côté candidat =====
  // Chaque entretien planifié EST une notification pour le candidat
  // concerné ("L'entreprise souhaite vous rencontrer"). L'état lu/supprimé
  // vit sur la ligne `interviews` (`seeker_read`/`seeker_deleted`).

  /// Entretiens à notifier à ce candidat (non supprimés de son côté), le
  /// plus récemment planifié ou modifié en premier.
  Future<List<Interview>> fetchNotificationsForJobSeeker(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'interviews',
      where: 'job_seeker_user_id = ? AND seeker_deleted = 0 AND status != ?',
      whereArgs: [jobSeekerUserId, InterviewStatus.cancelled],
      orderBy: 'COALESCE(notified_at, created_at) DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Nombre d'entretiens dont le candidat n'a pas encore lu la notification
  /// — s'ajoute au compteur d'offres non lues sur la pastille du dashboard
  /// candidat (`JobSeekerDashboard._loadNotificationCount`).
  Future<int> countUnreadNotificationsForJobSeeker(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'interviews',
      columns: ['id'],
      where:
          'job_seeker_user_id = ? AND seeker_deleted = 0 AND seeker_read = 0 AND status != ?',
      whereArgs: [jobSeekerUserId, InterviewStatus.cancelled],
    );
    return rows.length;
  }

  /// Nombre total d'entretiens (non annulés, non supprimés côté candidat)
  /// concernant ce candidat — stat "Entretiens" du panneau latéral candidat
  /// (`ProfileSidePanel`). Même filtre que [fetchNotificationsForJobSeeker]
  /// pour que le compteur corresponde exactement à la liste ouverte au tap.
  Future<int> countForJobSeeker(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'interviews',
      columns: ['id'],
      where: 'job_seeker_user_id = ? AND seeker_deleted = 0 AND status != ?',
      whereArgs: [jobSeekerUserId, InterviewStatus.cancelled],
    );
    return rows.length;
  }

  Future<void> markSeekerNotificationRead(int id, {bool read = true}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'interviews',
      {'seeker_read': read ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSeekerNotification(int id) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'interviews',
      {'seeker_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllSeekerNotificationsRead(String jobSeekerUserId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'interviews',
      {'seeker_read': 1},
      where: 'job_seeker_user_id = ? AND seeker_deleted = 0',
      whereArgs: [jobSeekerUserId],
    );
  }
}
