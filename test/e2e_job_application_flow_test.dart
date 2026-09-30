import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';
import 'package:joem/features/job_seeker_registration/data/job_seeker_repository.dart';
import 'package:joem/features/recruiter_registration/data/recruiter_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_e2e_application');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await AppDatabase.instance.resetDatabase();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Application flow', () {
    late JobOffer offer;
    late String candidateId;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      await const RecruiterRepository().register(
        const RecruiterRegistrationData(
          email: 'recruiter@test.com',
          password: 'Test123!',
          nom: 'Name',
          prenom: 'Recruiter',
          telephone: '0340000000',
          localisation: 'Antananarivo',
          nomEntreprise: 'Test Company',
          description: 'Test employer',
          logoBytes: null,
          categorieEntreprise: 'Informatique',
        ),
      );

      final recruiterAuth = AuthService();
      expect(
        await recruiterAuth.login('recruiter@test.com', 'Test123!'),
        isTrue,
      );
      offer = await const JobOfferRepository().publish(
        employerUserId: int.parse(recruiterAuth.currentUser!.id),
        companyName: 'Test Company',
        title: 'Flutter Developer',
        description: 'Développeur mobile',
        location: 'Antananarivo',
        salary: '800000 MGA',
        contractType: 'CDI',
        categories: ['Informatique'],
      );
      await recruiterAuth.logout();

      candidateId = (await _registerCandidate(
        'candidate@test.com',
        'Candidate',
        'User',
      )).toString();
    });

    test('candidate applies and recruiter accepts the application', () async {
      final authService = AuthService();
      const repository = JobOfferRepository();

      expect(await authService.login('candidate@test.com', 'Test123!'), isTrue);
      await repository.apply(
        jobOfferId: offer.id,
        jobSeekerUserId: candidateId,
        candidateName: 'Candidate User',
        candidatePosition: 'Flutter Developer',
      );
      expect(await repository.hasApplied(offer.id, candidateId), isTrue);
      await authService.logout();

      expect(await authService.login('recruiter@test.com', 'Test123!'), isTrue);
      final applications = await repository
          .fetchApplicationNotificationsForEmployer(
            int.parse(authService.currentUser!.id),
          );
      expect(applications, hasLength(1));
      await repository.acceptApplication(
        applications.single.applicationId,
        message: 'Bienvenue !',
      );
      await authService.logout();

      expect(await authService.login('candidate@test.com', 'Test123!'), isTrue);
      final decisions = await repository.fetchDecisionNotificationsForJobSeeker(
        candidateId,
      );
      expect(decisions.single.isAccepted, isTrue);
      expect(decisions.single.decisionMessage, 'Bienvenue !');
      await authService.logout();
    });

    test('candidate can withdraw a pending application', () async {
      final authService = AuthService();
      const repository = JobOfferRepository();

      expect(await authService.login('candidate@test.com', 'Test123!'), isTrue);
      await repository.apply(
        jobOfferId: offer.id,
        jobSeekerUserId: candidateId,
        candidateName: 'Candidate User',
      );

      expect(
        await repository.withdrawApplication(
          jobOfferId: offer.id,
          jobSeekerUserId: candidateId,
        ),
        isTrue,
      );
      expect(await repository.hasApplied(offer.id, candidateId), isFalse);
      await authService.logout();
    });

    test('candidate cannot withdraw after acceptance', () async {
      final authService = AuthService();
      const repository = JobOfferRepository();

      await authService.login('candidate@test.com', 'Test123!');
      await repository.apply(
        jobOfferId: offer.id,
        jobSeekerUserId: candidateId,
        candidateName: 'Candidate User',
      );
      await authService.logout();

      await authService.login('recruiter@test.com', 'Test123!');
      final applications = await repository
          .fetchApplicationNotificationsForEmployer(
            int.parse(authService.currentUser!.id),
          );
      await repository.acceptApplication(applications.single.applicationId);
      await authService.logout();

      await authService.login('candidate@test.com', 'Test123!');
      expect(
        await repository.withdrawApplication(
          jobOfferId: offer.id,
          jobSeekerUserId: candidateId,
        ),
        isFalse,
      );
      await authService.logout();
    });

    test('rejected decision notifies candidate and can be restored', () async {
      final authService = AuthService();
      const repository = JobOfferRepository();

      await authService.login('candidate@test.com', 'Test123!');
      await repository.apply(
        jobOfferId: offer.id,
        jobSeekerUserId: candidateId,
        candidateName: 'Candidate User',
      );
      await authService.logout();

      await authService.login('recruiter@test.com', 'Test123!');
      final applications = await repository
          .fetchApplicationNotificationsForEmployer(
            int.parse(authService.currentUser!.id),
          );
      await repository.rejectApplication(
        applications.single.applicationId,
        message: 'Autre profil retenu',
      );
      await repository.restoreApplication(applications.single.applicationId);
      await authService.logout();

      await authService.login('candidate@test.com', 'Test123!');
      expect(
        await repository.fetchDecisionNotificationsForJobSeeker(candidateId),
        isEmpty,
      );
      await authService.logout();
    });

    test('multiple candidates can apply to the same offer', () async {
      const repository = JobOfferRepository();
      final secondCandidateId = (await _registerCandidate(
        'second@test.com',
        'Second',
        'Candidate',
      )).toString();
      final thirdCandidateId = (await _registerCandidate(
        'third@test.com',
        'Third',
        'Candidate',
      )).toString();

      await repository.apply(
        jobOfferId: offer.id,
        jobSeekerUserId: candidateId,
        candidateName: 'Candidate User',
      );
      await repository.apply(
        jobOfferId: offer.id,
        jobSeekerUserId: secondCandidateId,
        candidateName: 'Second Candidate',
      );
      await repository.apply(
        jobOfferId: offer.id,
        jobSeekerUserId: thirdCandidateId,
        candidateName: 'Third Candidate',
      );

      expect(
        await repository.fetchApplicationsForOffer(offer.id),
        hasLength(3),
      );
    });
  });
}

Future<int> _registerCandidate(
  String email,
  String firstName,
  String lastName,
) async {
  final result = await const JobSeekerRepository().register(
    JobSeekerRegistrationData(
      email: email,
      password: 'Test123!',
      nom: lastName,
      prenom: firstName,
      telephone: '0341234567',
      localisation: 'Antananarivo',
      titreProfessionnel: 'Flutter Developer',
      presentation: 'Test candidate',
      photoBytes: null,
      skills: const [(name: 'Flutter', rating: 4), (name: 'Dart', rating: 4)],
      tarifJournalier: '',
      disponibilite: null,
      workModes: const [],
    ),
  );
  return result.userId;
}
