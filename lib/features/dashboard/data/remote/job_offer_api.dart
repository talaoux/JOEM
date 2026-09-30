
import 'package:flutter/foundation.dart';

import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/portfolio_json.dart';
import 'package:joem/core/network/remote_images.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';

/// [JobOfferRepository] quand l'application parle à l'API : mêmes méthodes,
/// mêmes modèles, mais les offres, candidatures, favoris, vues et
/// notifications sont partagés par tous les téléphones.
///
/// Les ids d'utilisateur passés par les écrans sont ignorés : le serveur
/// sait qui appelle grâce au jeton.
class JobOfferApi {
  const JobOfferApi(this.client);

  final ApiClient client;

  // --- Offres -------------------------------------------------------------

  Future<JobOffer> publish({
    required String title,
    required String description,
    required String location,
    required String salary,
    required String contractType,
    Uint8List? posterImage,
    List<String> categories = const [],
    String? otherSector,
  }) async {
    var json = await client.post('/jobs', body: {
      ..._offerFields(title, description, location, salary, contractType, otherSector),
      'categories': categories.toSet().toList(),
    }) as Map<String, dynamic>;
    if (posterImage != null) {
      json = await client.upload('/jobs/${json['id']}/poster', bytes: posterImage, filename: 'affiche.jpg') as Map<String, dynamic>;
    }
    return offerFromJson(json);
  }

  Future<JobOffer> updateOffer({
    required JobOffer offer,
    required String title,
    required String description,
    required String location,
    required String salary,
    required String contractType,
    Uint8List? posterImage,
    required List<String> categories,
    String? otherSector,
  }) async {
    var json = await client.patch('/jobs/${offer.id}', body: {
      ..._offerFields(title, description, location, salary, contractType, otherSector),
      'categories': categories.toSet().toList(),
    }) as Map<String, dynamic>;

    if (!listEquals(posterImage, offer.posterImage)) {
      json = posterImage == null
          ? await client.delete('/jobs/${offer.id}/poster') as Map<String, dynamic>
          : await client.upload('/jobs/${offer.id}/poster', bytes: posterImage, filename: 'affiche.jpg') as Map<String, dynamic>;
    }
    return offerFromJson(json);
  }

  Future<void> deleteOffer(int jobOfferId) => client.delete('/jobs/$jobOfferId');

  Future<List<JobOffer>> fetchAll({String? category, bool hideDismissed = false}) async {
    final rows = await client.getAllPages('/jobs', query: {
      'per_page': '50',
      'category': ?category,
      if (hideDismissed) 'hide_dismissed': '1',
    });
    return offersFromJson(rows);
  }

  Future<List<JobOffer>> fetchByEmployer() async => offersFromJson(await _employerOffers());

  Future<List<String>> fetchCategoriesForOffer(int jobOfferId) async {
    final json = await client.get('/jobs/$jobOfferId') as Map<String, dynamic>;
    return _categoryNames(json);
  }

  Future<Map<int, List<String>>> fetchCategoriesByOffer() async => {
        for (final row in await _employerOffers())
          if (_categoryNames(row).isNotEmpty) row['id'] as int: _categoryNames(row),
      };

  Future<Map<int, int>> fetchApplicantCountsByOffer() async => {
        for (final row in await _employerOffers())
          if ((row['applications_count'] as int? ?? 0) > 0) row['id'] as int: row['applications_count'] as int,
      };

  /// `GET /jobs/{id}` avec le jeton d'un candidat enregistre sa vue.
  Future<void> recordOfferView(int jobOfferId) => client.get('/jobs/$jobOfferId');

  Future<List<OfferView>> fetchOfferViewsForEmployer() async {
    final rows = jsonList(await client.get('/employer/job-views'));
    return Future.wait(rows.map((row) async {
      final profile = row['candidate_profile'] as Map<String, dynamic>?;
      final name = '${profile?['prenom'] ?? ''} ${profile?['nom'] ?? ''}'.trim();
      return OfferView(
        offerId: row['job_offer_id'] as int,
        offerTitle: row['offer_title'] as String? ?? '',
        viewerName: name.isEmpty ? 'Un candidat' : name,
        viewerPosition: (profile?['titre_professionnel'] as String?)?.trim(),
        viewerPhoto: await RemoteImages.load(profile?['photo_url']),
        viewedAt: parseApiDateTime(row['viewed_at']),
      );
    }));
  }

  // --- Candidatures (candidat) --------------------------------------------

  /// Idempotent comme en local : une deuxième candidature (409) est ignorée.
  Future<void> apply(int jobOfferId) async {
    try {
      await client.post('/jobs/$jobOfferId/applications');
    } on ApiException catch (error) {
      if (error.statusCode != 409) rethrow;
    }
  }

  /// `false` si le recruteur a déjà décidé (409) ou si rien n'est à retirer.
  Future<bool> withdrawApplication(int jobOfferId) async {
    final application = (await _myApplications()).where((row) => row['job_offer_id'] == jobOfferId).firstOrNull;
    if (application == null) return false;
    try {
      await client.delete('/applications/${application['id']}');
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 409) return false;
      rethrow;
    }
  }

  Future<({String status, String? decisionMessage})?> fetchApplicationStatus(int jobOfferId) async {
    final application = (await _myApplications()).where((row) => row['job_offer_id'] == jobOfferId).firstOrNull;
    if (application == null) return null;
    return (status: application['status'] as String, decisionMessage: application['decision_message'] as String?);
  }

  Future<Map<int, String>> fetchApplicationStatusesByOffer() async => {
        for (final row in await _myApplications()) row['job_offer_id'] as int: row['status'] as String,
      };

  Future<Set<int>> fetchAppliedOfferIds() async => {for (final row in await _myApplications()) row['job_offer_id'] as int};

  Future<List<JobOffer>> fetchAppliedOffers() async =>
      offersFromJson([for (final row in await _myApplications()) row['offer'] as Map<String, dynamic>]);

  Future<int> countApplicationsForJobSeeker() async => await _stat('applications_count');

  // --- Candidatures (recruteur) -------------------------------------------

  Future<void> decide(int applicationId, String status, String? message) =>
      client.patch('/applications/$applicationId/decision', body: {'status': status, 'decision_message': message});

  Future<int> countApplicantsForEmployer() async => await _stat('applications_count');

  Future<List<JobApplicationNotification>> fetchApplicationsForOffer(int jobOfferId) async =>
      Future.wait(jsonList(await client.get('/jobs/$jobOfferId/applications')).map(applicationFromJson));

  Future<JobSeekerProfileSummary?> fetchJobSeekerProfileSummary(String jobSeekerUserId) async {
    final json = await _candidate(jobSeekerUserId);
    if (json == null) return null;
    final profile = json['candidate_profile'] as Map<String, dynamic>;
    return JobSeekerProfileSummary(
      firstName: profile['prenom'] as String? ?? '',
      lastName: profile['nom'] as String? ?? '',
      email: json['email'] as String?,
      photo: await RemoteImages.load(profile['photo_url']),
      telephone: profile['telephone'] as String?,
      localisation: profile['localisation'] as String?,
      presentation: profile['presentation'] as String?,
      skills: [for (final skill in jsonList(json['skills'])) skill['name'] as String],
      cvFileName: profile['cv_file_name'] as String?,
    );
  }

  Future<JobSeekerCvFile?> fetchJobSeekerCv(String jobSeekerUserId) async {
    final json = await _candidate(jobSeekerUserId);
    final profile = json?['candidate_profile'] as Map<String, dynamic>?;
    final url = profile?['cv_url'] as String?;
    if (url == null) return null;
    final bytes = await client.downloadBytes(url);
    if (bytes == null) return null;
    return JobSeekerCvFile(bytes: bytes, fileName: profile!['cv_file_name'] as String? ?? 'cv.pdf');
  }

  // --- Favoris ------------------------------------------------------------

  Future<void> saveOffer(int jobOfferId) => client.post('/jobs/$jobOfferId/save');

  Future<void> unsaveOffer(int jobOfferId) => client.delete('/jobs/$jobOfferId/save');

  Future<Set<int>> fetchSavedOfferIds() async => {for (final row in await client.getAllPages('/saved-jobs')) row['id'] as int};

  Future<List<JobOffer>> fetchSavedOffers() async => offersFromJson(await client.getAllPages('/saved-jobs'));

  Future<void> clearSavedOffers() => client.delete('/saved-jobs');

  Future<int> countOfferViewsForEmployer() async => await _stat('job_views_count');

  // --- Notifications ------------------------------------------------------

  /// `GET /notifications` : une seule réponse, partagée par la liste et les
  /// pastilles grâce au cache court d'`ApiClient`.
  Future<Map<String, dynamic>> _notifications() async => await client.get('/notifications') as Map<String, dynamic>;

  /// Les compteurs (pastilles) ne lisent que le JSON : construire les
  /// modèles téléchargerait le logo et l'affiche de chaque offre.
  Future<int> countUnreadOfferNotifications() async =>
      jsonList((await _notifications())['jobs']).where((row) => row['is_read'] != true).length;

  Future<int> countUnreadDecisionNotifications() async => jsonList((await _notifications())['applications'])
      .where((row) => row['seeker_deleted'] != true && row['seeker_read'] != true)
      .length;

  Future<int> countUnreadApplicationNotificationsForEmployer() async => jsonList((await _notifications())['applications'])
      .where((row) => (row['notification_read'] as Map<String, dynamic>?)?['is_read'] != true)
      .length;

  Future<List<JobOfferNotification>> fetchOfferNotifications() async {
    final data = await _notifications();
    final rows = jsonList(data['jobs']);
    return Future.wait(rows.map((row) async => JobOfferNotification(offer: await offerFromJson(row), isRead: row['is_read'] as bool? ?? false)));
  }

  Future<void> setOfferNotificationRead(int jobOfferId, {required bool isRead}) =>
      client.patch('/notifications/jobs/$jobOfferId/read', body: {'is_read': isRead});

  Future<void> deleteOfferNotification(int jobOfferId) => client.delete('/notifications/jobs/$jobOfferId');

  Future<List<ApplicationDecisionNotification>> fetchDecisionNotifications() async {
    final data = await _notifications();
    final rows = jsonList(data['applications']).where((row) => row['seeker_deleted'] != true);
    return Future.wait(rows.map((row) async => ApplicationDecisionNotification(
          applicationId: row['id'] as int,
          offer: await offerFromJson(row['offer'] as Map<String, dynamic>),
          status: row['status'] as String,
          decisionMessage: row['decision_message'] as String?,
          decidedAt: parseApiDateTime(row['decided_at']),
          isRead: row['seeker_read'] as bool? ?? false,
        )));
  }

  Future<void> setDecisionNotificationRead(int applicationId, {required bool isRead}) =>
      client.patch('/notifications/decisions/$applicationId/read', body: {'is_read': isRead});

  Future<void> deleteDecisionNotification(int applicationId) => client.delete('/notifications/decisions/$applicationId');

  Future<List<JobApplicationNotification>> fetchApplicationNotificationsForEmployer() async {
    final data = await _notifications();
    return Future.wait(jsonList(data['applications']).map(applicationFromJson));
  }

  Future<void> setApplicationNotificationRead(int applicationId, {required bool isRead}) =>
      client.patch('/notifications/applications/$applicationId/read', body: {'is_read': isRead});

  Future<void> deleteApplicationNotification(int applicationId) => client.delete('/notifications/applications/$applicationId');

  /// `PATCH /notifications/read-all` : tout ce que l'appelant voit (offres,
  /// décisions et entretiens pour un candidat ; candidatures reçues pour un
  /// recruteur) en une seule requête.
  Future<void> markAllNotificationsRead() => client.patch('/notifications/read-all');

  // --- Conversions JSON -> modèles ----------------------------------------

  static Future<JobOffer> offerFromJson(Map<String, dynamic> json) async {
    final images = await Future.wait([RemoteImages.load(json['company_logo_url']), RemoteImages.load(json['poster_image_url'])]);
    return JobOffer(
      id: json['id'] as int,
      employerUserId: json['employer_user_id'] as int,
      companyName: json['company_name'] as String? ?? '',
      companyLogo: images[0],
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      salary: json['salary'] as String? ?? '',
      contractType: json['contract_type'] as String? ?? '',
      posterImage: images[1],
      createdAt: parseApiDateTime(json['created_at']),
      otherSector: json['other_sector'] as String?,
    );
  }

  static Future<List<JobOffer>> offersFromJson(List<Map<String, dynamic>> rows) => Future.wait(rows.map(offerFromJson));

  static Future<JobApplicationNotification> applicationFromJson(Map<String, dynamic> json) async {
    final profile = (json['candidate'] as Map<String, dynamic>?)?['candidate_profile'] as Map<String, dynamic>?;
    final currentName = '${profile?['prenom'] ?? ''} ${profile?['nom'] ?? ''}'.trim();
    return JobApplicationNotification(
      applicationId: json['id'] as int,
      jobSeekerUserId: (json['job_seeker_user_id'] as int).toString(),
      offer: await offerFromJson(json['offer'] as Map<String, dynamic>),
      candidateName: currentName.isNotEmpty ? currentName : json['candidate_name'] as String? ?? '',
      candidatePosition: profile?['titre_professionnel'] as String? ?? json['candidate_position'] as String?,
      appliedAt: parseApiDateTime(json['created_at']),
      isRead: (json['notification_read'] as Map<String, dynamic>?)?['is_read'] as bool? ?? false,
      status: json['status'] as String? ?? ApplicationStatus.pending,
      decisionMessage: json['decision_message'] as String?,
      decidedAt: parseOptionalApiDateTime(json['decided_at']),
    );
  }

  // --- Aides --------------------------------------------------------------

  Map<String, Object?> _offerFields(String title, String description, String location, String salary, String contractType, String? otherSector) => {
        'title': title,
        'description': description,
        'location': location,
        'salary': salary,
        'contract_type': contractType,
        'other_sector': otherSector,
      };

  Future<List<Map<String, dynamic>>> _employerOffers() => client.getAllPages('/employer/jobs');

  Future<List<Map<String, dynamic>>> _myApplications() => client.getAllPages('/applications');

  Future<int> _stat(String key) async => ((await client.get('/stats')) as Map<String, dynamic>)[key] as int? ?? 0;

  /// Profil d'un candidat vu par le recruteur, `null` s'il n'est plus
  /// accessible (compte supprimé, profil masqué sans candidature).
  Future<Map<String, dynamic>?> _candidate(String userId) async {
    try {
      return await client.get('/candidates/$userId') as Map<String, dynamic>;
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  static List<String> _categoryNames(Map<String, dynamic> json) =>
      [for (final category in jsonList(json['categories'])) category['name'] as String];
}
