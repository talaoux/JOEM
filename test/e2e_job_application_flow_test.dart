import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';

/// Test E2E du flux de candidature complet
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_e2e_application');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    await AppDatabase.instance.resetDatabase();
  });

  tearDownAll(() async {
    await AppDatabase.instance.resetDatabase();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('E2E - Flux de Candidature', () {
    late JobOffer testOffer;
    late String candidateUserId;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final authService = AuthService();
      final offerRepo = const JobOfferRepository();
      
      // Créer un recruteur et publier une offre
      await authService.registerEmployer(
        email: 'recruiter@test.com',
        password: 'Test123!',
        firstName: 'Recruiter',
        lastName: 'Name',
        companyName: 'Test Company',
        category: 'Informatique',
      );
      
      final recruiterId = authService.currentUser!.id;
      await authService.logout();
      
      testOffer = await offerRepo.publish(
        employerUserId: int.parse(recruiterId),
        companyName: 'Test Company',
        title: 'Développeur Flutter Senior',
        description: 'Nous recherchons un développeur Flutter expérimenté',
        location: 'Antananarivo',
        salary: '800000-1200000 MGA',
        contractType: 'CDI',
        categories: ['Informatique'],
      );
      
      // Créer un candidat
      await authService.registerJobSeeker(
        email: 'candidate@test.com',
        password: 'Test123!',
        firstName: 'Candidate',
        lastName: 'User',
        professionalTitle: 'Développeur Flutter',
        skills: ['Flutter', 'Dart', 'Firebase'],
      );
      
      candidateUserId = authService.currentUser!.id;
      await authService.logout();
    });

    testWidgets('flux complet: publication -> candidature -> décision', (tester) async {
      final authService = AuthService();
      final offerRepo = const JobOfferRepository();
      
      // 1. Candidat postule
      await authService.login('candidate@test.com', 'Test123!');
      
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
        candidateName: 'Candidate User',
        candidatePosition: 'Développeur Flutter',
      );
      
      final hasApplied = await offerRepo.hasApplied(testOffer.id, candidateUserId);
      expect(hasApplied, true);
      
      await authService.logout();
      
      // 2. Recruteur voit la candidature
      await authService.login('recruiter@test.com', 'Test123!');
      
      final notifications = await offerRepo.fetchApplicationNotificationsForEmployer(
        int.parse(authService.currentUser!.id),
      );
      
      expect(notifications.length, 1);
      expect(notifications.first.candidateName, 'Candidate User');
      
      // 3. Recruteur accepte la candidature
      await offerRepo.acceptApplication(notifications.first.applicationId, message: 'Bienvenue !');
      
      await authService.logout();
      
      // 4. Candidat voit la décision
      await authService.login('candidate@test.com', 'Test123!');
      
      final decisionNotifications = await offerRepo.fetchDecisionNotificationsForJobSeeker(candidateUserId);
      expect(decisionNotifications.length, 1);
      expect(decisionNotifications.first.isAccepted, true);
      expect(decisionNotifications.first.decisionMessage, 'Bienvenue !');
    });

    testWidgets('candidat peut retirer sa candidature avant décision', (tester) async {
      final authService = AuthService();
      final offerRepo = const JobOfferRepository();
      
      await authService.login('candidate@test.com', 'Test123!');
      
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
        candidateName: 'Candidate User',
        candidatePosition: 'Développeur Flutter',
      );
      
      final withdrawn = await offerRepo.withdrawApplication(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
      );
      
      expect(withdrawn, true);
      
      final hasApplied = await offerRepo.hasApplied(testOffer.id, candidateUserId);
      expect(hasApplied, false);
    });

    testWidgets('candidat ne peut pas retirer après acceptation', (tester) async {
      final authService = AuthService();
      final offerRepo = const JobOfferRepository();
      
      // Candidat postule
      await authService.login('candidate@test.com', 'Test123!');
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
        candidateName: 'Candidate User',
        candidatePosition: 'Développeur Flutter',
      );
      await authService.logout();
      
      // Recruteur accepte
      await authService.login('recruiter@test.com', 'Test123!');
      final notifications = await offerRepo.fetchApplicationNotificationsForEmployer(
        int.parse(authService.currentUser!.id),
      );
      await offerRepo.acceptApplication(notifications.first.applicationId);
      await authService.logout();
      
      // Candidat tente de retirer
      await authService.login('candidate@test.com', 'Test123!');
      final withdrawn = await offerRepo.withdrawApplication(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
      );
      
      expect(withdrawn, false);
    });

    testWidgets('recruteur peut rejeter une candidature', (tester) async {
      final authService = AuthService();
      final offerRepo = const JobOfferRepository();
      
      // Candidat postule
      await authService.login('candidate@test.com', 'Test123!');
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
        candidateName: 'Candidate User',
        candidatePosition: 'Développeur Flutter',
      );
      await authService.logout();
      
      // Recruteur rejette
      await authService.login('recruiter@test.com', 'Test123!');
      final notifications = await offerRepo.fetchApplicationNotificationsForEmployer(
        int.parse(authService.currentUser!.id),
      );
      await offerRepo.rejectApplication(
        notifications.first.applicationId,
        message: 'Profil ne correspond pas',
      );
      await authService.logout();
      
      // Candidat voit le rejet
      await authService.login('candidate@test.com', 'Test123!');
      final decisionNotifications = await offerRepo.fetchDecisionNotificationsForJobSeeker(candidateUserId);
      expect(decisionNotifications.length, 1);
      expect(decisionNotifications.first.isRejected, true);
      expect(decisionNotifications.first.decisionMessage, 'Profil ne correspond pas');
    });

    testWidgets('recruteur peut annuler une décision', (tester) async {
      final authService = AuthService();
      final offerRepo = const JobOfferRepository();
      
      // Candidat postule
      await authService.login('candidate@test.com', 'Test123!');
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
        candidateName: 'Candidate User',
        candidatePosition: 'Développeur Flutter',
      );
      await authService.logout();
      
      // Recruteur rejette
      await authService.login('recruiter@test.com', 'Test123!');
      final notifications = await offerRepo.fetchApplicationNotificationsForEmployer(
        int.parse(authService.currentUser!.id),
      );
      await offerRepo.rejectApplication(notifications.first.applicationId);
      
      // Annuler la décision
      await offerRepo.restoreApplication(notifications.first.applicationId);
      await authService.logout();
      
      // Candidat ne voit plus la décision
      await authService.login('candidate@test.com', 'Test123!');
      final decisionNotifications = await offerRepo.fetchDecisionNotificationsForJobSeeker(candidateUserId);
      expect(decisionNotifications.length, 0);
    });

    testWidgets('plusieurs candidats postulent à la même offre', (tester) async {
      final authService = AuthService();
      final offerRepo = const JobOfferRepository();
      
      // Créer des candidats supplémentaires
      await authService.registerJobSeeker(
        email: 'candidate2@test.com',
        password: 'Test123!',
        firstName: 'Second',
        lastName: 'Candidate',
        professionalTitle: 'Designer',
        skills: ['Figma'],
      );
      final candidate2Id = authService.currentUser!.id;
      await authService.logout();
      
      await authService.registerJobSeeker(
        email: 'candidate3@test.com',
        password: 'Test123!',
        firstName: 'Third',
        lastName: 'Candidate',
        professionalTitle: 'Manager',
        skills: ['Management'],
      );
      final candidate3Id = authService.currentUser!.id;
      await authService.logout();
      
      // Tous postulent
      await authService.login('candidate@test.com', 'Test123!');
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidateUserId,
        candidateName: 'Candidate User',
        candidatePosition: 'Développeur Flutter',
      );
      await authService.logout();
      
      await authService.login('candidate2@test.com', 'Test123!');
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidate2Id,
        candidateName: 'Second Candidate',
        candidatePosition: 'Designer',
      );
      await authService.logout();
      
      await authService.login('candidate3@test.com', 'Test123!');
      await offerRepo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: candidate3Id,
        candidateName: 'Third Candidate',
        candidatePosition: 'Manager',
      );
      await authService.logout();
      
      // Recruteur voit toutes les candidatures
      await authService.login('recruiter@test.com', 'Test123!');
      final notifications = await offerRepo.fetchApplicationNotificationsForEmployer(
        int.parse(authService.currentUser!.id),
      );
      
      expect(notifications.length, 3);
    });
  });
}
