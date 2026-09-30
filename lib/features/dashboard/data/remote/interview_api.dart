import 'dart:typed_data';

import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/portfolio_json.dart';
import 'package:joem/core/network/remote_images.dart';
import 'package:joem/features/dashboard/data/interview_repository.dart';

/// [InterviewRepository] quand l'application parle à l'API : le recruteur
/// planifie depuis son téléphone, le candidat reçoit la notification sur
/// le sien. Les filtres (aujourd'hui, à venir, non lus) restent ceux du
/// dépôt local, appliqués à la liste renvoyée par `GET /interviews` (celle
/// de l'appelant, selon son rôle).
class InterviewApi {
  const InterviewApi(this.client);

  final ApiClient client;

  Future<Interview> schedule({
    required int? jobApplicationId,
    DateTime? date,
    String? time,
    String? location,
    required String mode,
    String? notes,
  }) async {
    // Le serveur rattache l'entretien à une candidature : c'est elle qui
    // désigne le candidat et l'offre.
    if (jobApplicationId == null) throw StateError('Un entretien se planifie depuis une candidature.');
    final json = await client.post('/applications/$jobApplicationId/interviews', body: _scheduleFields(date, time, location, mode, notes));
    return interviewFromJson(json as Map<String, dynamic>);
  }

  Future<void> reschedule(int id, {DateTime? date, String? time, String? location, required String mode, String? notes}) =>
      client.patch('/interviews/$id', body: _scheduleFields(date, time, location, mode, notes));

  Future<void> updateStatus(int id, String status) => client.patch('/interviews/$id', body: {'status': status});

  Future<void> delete(int id) => client.delete('/interviews/$id');

  /// Les entretiens de l'appelant : ceux qu'il a planifiés (recruteur), ou
  /// ceux qui le concernent (candidat), annulés et supprimés compris.
  Future<List<Interview>> fetchMine() async => Future.wait((await client.getAllPages('/interviews')).map(interviewWithCompanyFromJson));

  /// Notifications d'entretien du candidat : ni annulées ni supprimées de
  /// son côté, la plus récemment planifiée ou modifiée en premier.
  Future<List<Interview>> fetchSeekerNotifications() async {
    final rows = await _seekerNotificationRows();
    return (await Future.wait(rows.map(interviewWithCompanyFromJson)))..sort((a, b) => b.notifiedAt.compareTo(a.notifiedAt));
  }

  /// Compteurs sans télécharger le logo de chaque entreprise.
  Future<int> countSeekerNotifications({bool unreadOnly = false}) async =>
      (await _seekerNotificationRows()).where((row) => !unreadOnly || row['seeker_read'] != true).length;

  Future<Iterable<Map<String, dynamic>>> _seekerNotificationRows() async => (await client.getAllPages('/interviews'))
      .where((row) => row['seeker_deleted'] != true && row['status'] != InterviewStatus.cancelled);

  Future<void> setSeekerRead(int id, {required bool isRead}) =>
      client.patch('/notifications/interviews/$id/read', body: {'is_read': isRead});

  Future<void> deleteSeekerNotification(int id) => client.delete('/notifications/interviews/$id');

  /// [interviewFromJson] avec le logo de l'entreprise, téléchargé
  /// (`GET /interviews` fournit `company_name` et `company_logo_url`).
  static Future<Interview> interviewWithCompanyFromJson(Map<String, dynamic> json) async =>
      interviewFromJson(json, companyLogo: await RemoteImages.load(json['company_logo_url']));

  static Interview interviewFromJson(Map<String, dynamic> json, {Uint8List? companyLogo}) {
    final rawDate = json['scheduled_date'] as String?;
    final date = rawDate == null ? null : DateTime.tryParse(rawDate);
    return Interview(
      id: json['id'] as int,
      employerUserId: json['employer_user_id'] as int,
      jobApplicationId: json['job_application_id'] as int?,
      jobOfferId: json['job_offer_id'] as int?,
      jobSeekerUserId: (json['job_seeker_user_id'] as int).toString(),
      candidateName: json['candidate_name'] as String? ?? '',
      offerTitle: json['offer_title'] as String? ?? '',
      date: date == null ? null : DateTime(date.year, date.month, date.day),
      time: date == null ? null : json['scheduled_time'] as String?,
      location: json['location'] as String?,
      mode: json['mode'] as String? ?? InterviewMode.presentiel,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? InterviewStatus.scheduled,
      createdAt: parseApiDateTime(json['created_at']),
      seekerRead: json['seeker_read'] as bool? ?? false,
      revision: json['revision'] as int? ?? 0,
      notifiedAt: parseOptionalApiDateTime(json['notified_at']),
      companyName: json['company_name'] as String?,
      companyLogo: companyLogo,
    );
  }

  static Map<String, Object?> _scheduleFields(DateTime? date, String? time, String? location, String mode, String? notes) => {
        'scheduled_date': date == null
            ? null
            : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'scheduled_time': date == null || (time?.trim().isEmpty ?? true) ? null : time!.trim(),
        'location': location,
        'mode': mode,
        'notes': notes,
      };
}
