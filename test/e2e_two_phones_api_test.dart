import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/remote_images.dart';
import 'package:joem/core/network/token_storage.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/dashboard/data/account_search_repository.dart';
import 'package:joem/features/dashboard/data/interview_repository.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';
import 'package:joem/features/job_seeker_registration/data/job_seeker_repository.dart';
import 'package:joem/features/recruiter_registration/data/recruiter_repository.dart';

/// Parcours complet à deux téléphones contre la VRAIE API Laravel.
///
/// Ignoré sans serveur. Pour le lancer :
///
/// ```text
/// flutter test test/e2e_two_phones_api_test.dart --dart-define=E2E_API_BASE_URL=http://127.0.0.1:8010/api
/// ```
///
/// Chaque « téléphone » a sa propre base locale et son propre jeton ; ils
/// ne partagent que le serveur, comme dans la réalité.
const _baseUrl = String.fromEnvironment('E2E_API_BASE_URL');

/// PNG 1x1 valide : le serveur vérifie le contenu réel des images.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final suffix = DateTime.now().millisecondsSinceEpoch;
  final recruiterEmail = 'rh.$suffix@vohitra.test';
  final candidateEmail = 'miora.$suffix@example.test';
  const password = 'MotDePasse123';

  const offers = JobOfferRepository();
  const interviews = InterviewRepository();
  const search = AccountSearchRepository();

  setUpAll(() async {
    // TestWidgetsFlutterBinding remplace le client HTTP par un faux qui
    // répond 400 à tout : ce test doit, lui, joindre le vrai serveur.
    HttpOverrides.global = null;
    tempDir = Directory.systemTemp.createTempSync('joem_e2e_two_phones');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    ApiClient.shared = null;
    await AppDatabase.instance.resetDatabase();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Prend l'autre téléphone : base locale vide, aucun jeton, rien en cache.
  Future<void> pickUpPhone() async {
    if (AuthService().currentUser != null) await AuthService().logout();
    await AppDatabase.instance.resetDatabase();
    RemoteImages.clear();
    ApiClient.shared = ApiClient(baseUrl: _baseUrl, tokenStorage: MemoryTokenStorage());
  }

  test('a recruiter and a candidate share offers, applications, interviews and profiles', () async {
    // --- Téléphone A : le recruteur s'inscrit et publie ---------------------
    await pickUpPhone();
    await const RecruiterRepository().register(RecruiterRegistrationData(
      email: recruiterEmail,
      password: password,
      nom: 'Randria',
      prenom: 'Tiana',
      telephone: '0341234567',
      localisation: 'Antananarivo',
      nomEntreprise: 'Vohitra Tech',
      description: 'Studio numérique',
      logoBytes: _png,
      categorieEntreprise: 'Informatique',
    ));
    expect(await AuthService().login(recruiterEmail, password), isTrue);
    final recruiterId = int.parse(AuthService().currentUser!.id);

    final published = await offers.publish(
      employerUserId: recruiterId,
      companyName: 'Vohitra Tech',
      title: 'Développeuse Flutter',
      description: 'Application mobile JOEM.',
      location: 'Antananarivo',
      salary: '2 000 000 Ar',
      contractType: 'CDI',
      posterImage: _png,
      categories: ['Informatique'],
    );
    expect(published.posterImage, isNotNull);
    expect(published.companyLogo, isNotNull, reason: 'le logo du recruteur accompagne l\'offre');

    // --- Téléphone B : la candidate s'inscrit et voit l'offre --------------
    await pickUpPhone();
    await const JobSeekerRepository().register(JobSeekerRegistrationData(
      email: candidateEmail,
      password: password,
      nom: 'Rakoto',
      prenom: 'Miora',
      telephone: '0329876543',
      localisation: 'Antananarivo',
      titreProfessionnel: 'Développeuse Flutter',
      presentation: 'Passionnée de mobile.',
      photoBytes: _png,
      skills: [(name: 'Flutter', rating: 5)],
      tarifJournalier: '150 000 Ar',
      disponibilite: null,
      workModes: ['teletravail'],
    ));
    expect(await AuthService().login(candidateEmail, password), isTrue);
    final candidateId = AuthService().currentUser!.id;

    final feed = await offers.fetchAllForJobSeeker(candidateId);
    final seen = feed.firstWhere((offer) => offer.id == published.id);
    expect(seen.title, 'Développeuse Flutter');
    expect(seen.companyName, 'Vohitra Tech');
    expect(seen.posterImage, isNotNull);
    expect(await offers.fetchCategoriesForOffer(published.id), ['Informatique']);
    expect((await offers.fetchByCategory('Informatique')).map((o) => o.id), contains(published.id));

    final offerNotifications = await offers.fetchNotificationsForJobSeeker(candidateId);
    expect(offerNotifications.where((n) => n.offer.id == published.id && !n.isRead), hasLength(1),
        reason: 'une offre publiée après l\'inscription est une notification non lue');

    await offers.recordOfferView(published.id, candidateId);
    await offers.apply(jobOfferId: published.id, jobSeekerUserId: candidateId, candidateName: 'Miora Rakoto');
    await offers.apply(jobOfferId: published.id, jobSeekerUserId: candidateId, candidateName: 'Miora Rakoto');
    expect(await offers.hasApplied(published.id, candidateId), isTrue);
    expect((await offers.fetchApplicationStatus(published.id, candidateId))?.status, ApplicationStatus.pending);

    await offers.saveOffer(published.id, candidateId);
    expect(await offers.fetchSavedOfferIds(candidateId), {published.id});

    await AuthService().addExperience(poste: 'Stagiaire mobile', entreprise: 'Orange', dateDebut: 'Janvier 2024');
    await AuthService().addProfessionalLink(label: 'GitHub', url: 'github.com/miora');
    expect(AuthService().currentUser!.professionalLinks.single.url, 'https://github.com/miora');

    // --- Téléphone A : le recruteur reçoit la candidature ------------------
    await pickUpPhone();
    expect(await AuthService().login(recruiterEmail, password), isTrue);

    final received = await offers.fetchApplicationNotificationsForEmployer(recruiterId);
    final application = received.single;
    expect(application.candidateName, 'Miora Rakoto');
    expect(application.candidatePosition, 'Développeuse Flutter');
    expect(application.isRead, isFalse);
    expect(await offers.countUnreadApplicationNotificationsForEmployer(recruiterId), 1);
    expect(await offers.countOfferViewsForEmployer(recruiterId), 1);
    expect((await offers.fetchOfferViewsForEmployer(recruiterId)).single.viewerName, 'Miora Rakoto');
    expect(await offers.fetchApplicantCountsByOffer(recruiterId), {published.id: 1});

    final summary = await offers.fetchJobSeekerProfileSummary(application.jobSeekerUserId);
    expect(summary!.email, candidateEmail, reason: 'la candidate a postulé chez ce recruteur');
    expect(summary.skills, ['Flutter']);
    expect(summary.photo, isNotNull);

    final found = await search.searchJobSeekers('Miora');
    expect(found.single.experiences.single.poste, 'Stagiaire mobile');
    expect(found.single.professionalLinks.single.url, 'https://github.com/miora');

    await offers.markApplicationNotificationRead(application.applicationId);
    await offers.acceptApplication(application.applicationId, message: 'Bienvenue !');
    final interview = await interviews.schedule(
      employerUserId: recruiterId,
      jobApplicationId: application.applicationId,
      jobOfferId: published.id,
      jobSeekerUserId: application.jobSeekerUserId,
      candidateName: application.candidateName,
      offerTitle: published.title,
      date: DateTime.now().add(const Duration(days: 3)),
      time: '10:30',
      mode: InterviewMode.visio,
      location: 'Google Meet',
    );
    expect(interview.time, '10:30');
    expect((await interviews.fetchUpcomingForEmployer(recruiterId)).map((i) => i.id), [interview.id]);
    expect((await interviews.fetchByApplication(application.applicationId))?.id, interview.id);

    await offers.updateOffer(
      offer: published,
      title: 'Développeuse Flutter senior',
      description: published.description,
      location: published.location,
      salary: published.salary,
      contractType: published.contractType,
      posterImage: published.posterImage,
      categories: ['Informatique'],
    );

    // --- Téléphone B : la candidate voit la décision et l'entretien --------
    await pickUpPhone();
    expect(await AuthService().login(candidateEmail, password), isTrue);
    expect(AuthService().currentUser!.experiences.single.poste, 'Stagiaire mobile',
        reason: 'le portfolio suit le compte sur un autre téléphone');

    final decision = (await offers.fetchDecisionNotificationsForJobSeeker(candidateId)).single;
    expect(decision.isAccepted, isTrue);
    expect(decision.decisionMessage, 'Bienvenue !');
    expect(await offers.countUnreadDecisionNotificationsForJobSeeker(candidateId), 1);

    final interviewNotifications = await interviews.fetchNotificationsForJobSeeker(candidateId);
    expect(interviewNotifications.single.offerTitle, 'Développeuse Flutter senior');
    expect(interviewNotifications.single.companyName, 'Vohitra Tech', reason: "la candidate sait qui propose l'entretien");
    expect(interviewNotifications.single.companyLogo, isNotNull);
    expect(await interviews.countUnreadNotificationsForJobSeeker(candidateId), 1);
    await interviews.markSeekerNotificationRead(interview.id);
    expect(await interviews.countUnreadNotificationsForJobSeeker(candidateId), 0);

    expect((await offers.fetchAll()).firstWhere((o) => o.id == published.id).title, 'Développeuse Flutter senior');
    expect(await offers.withdrawApplication(jobOfferId: published.id, jobSeekerUserId: candidateId), isFalse,
        reason: 'une candidature acceptée ne se retire plus');
    expect((await offers.fetchSavedOffers(candidateId)).single.id, published.id);

    await search.recordSearch(userId: candidateId, searchType: SearchAccountType.company, query: 'Vohitra');
    expect(await search.fetchHistory(userId: candidateId, searchType: SearchAccountType.company), ['Vohitra']);
    expect((await search.searchEmployers('Vohitra')).single.contactName, 'Tiana Randria');
  }, timeout: const Timeout(Duration(minutes: 3)), skip: _baseUrl.isEmpty ? 'Lancer avec --dart-define=E2E_API_BASE_URL=... et un serveur joem_api démarré.' : false);
}
