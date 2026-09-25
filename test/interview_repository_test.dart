import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/interview_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_test_interview');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    await AppDatabase.instance.resetDatabase();
  });

  tearDownAll(() async {
    await AppDatabase.instance.resetDatabase();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('InterviewRepository - Planification', () {
    test('planifie un entretien avec succès', () async {
      final repo = const InterviewRepository();
      
      final interview = await repo.schedule(
        employerUserId: 1,
        jobApplicationId: 100,
        jobOfferId: 10,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Jean Dupont',
        offerTitle: 'Développeur Flutter',
        date: DateTime(2024, 2, 15),
        time: '14:30',
        location: 'Bureau Antananarivo',
        mode: InterviewMode.presentiel,
        notes: 'Apporter CV et portfolio',
      );
      
      expect(interview.id, greaterThan(0));
      expect(interview.candidateName, 'Jean Dupont');
      expect(interview.offerTitle, 'Développeur Flutter');
      expect(interview.date, DateTime(2024, 2, 15));
      expect(interview.time, '14:30');
      expect(interview.location, 'Bureau Antananarivo');
      expect(interview.mode, InterviewMode.presentiel);
      expect(interview.status, InterviewStatus.scheduled);
      expect(interview.revision, 0);
    });

    test('planifie un entretien en visio', () async {
      final repo = const InterviewRepository();
      
      final interview = await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Marie Curie',
        offerTitle: 'Data Scientist',
        mode: InterviewMode.visio,
        location: 'https://zoom.us/j/123456',
      );
      
      expect(interview.mode, InterviewMode.visio);
      expect(interview.location, 'https://zoom.us/j/123456');
    });

    test('planifie un entretien avec date à définir', () async {
      final repo = const InterviewRepository();
      
      final interview = await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Pierre Martin',
        offerTitle: 'Manager',
        mode: InterviewMode.presentiel,
      );
      
      expect(interview.date, isNull);
      expect(interview.time, isNull);
      expect(interview.isDateToBeDefined, true);
    });
  });

  group('InterviewRepository - Modification', () {
    late Interview testInterview;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const InterviewRepository();
      
      testInterview = await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Test Candidate',
        offerTitle: 'Test Offer',
        date: DateTime(2024, 2, 15),
        time: '14:30',
        location: 'Ancien lieu',
        mode: InterviewMode.presentiel,
      );
    });

    test('modifie un entretien existant', () async {
      final repo = const InterviewRepository();
      
      await repo.update(
        id: testInterview.id,
        date: DateTime(2024, 3, 20),
        time: '10:00',
        location: 'Nouveau lieu',
        mode: InterviewMode.visio,
        notes: 'Nouveau notes',
      );
      
      final updated = await repo.fetchByApplication(100);
      expect(updated, isNull); // Pas de candidature liée
      
      // Récupérer par employer
      final interviews = await repo.fetchForEmployer(1);
      final updatedInterview = interviews.firstWhere((i) => i.id == testInterview.id);
      
      expect(updatedInterview.date, DateTime(2024, 3, 20));
      expect(updatedInterview.time, '10:00');
      expect(updatedInterview.location, 'Nouveau lieu');
      expect(updatedInterview.mode, InterviewMode.visio);
      expect(updatedInterview.notes, 'Nouveau notes');
      expect(updatedInterview.revision, 1); // Incrémenté
      expect(updatedInterview.isModified, true);
    });

    test('la modification remet seeker_read à 0', () async {
      final repo = const InterviewRepository();
      
      // Marquer comme lu
      await repo.markSeekerNotificationRead(testInterview.id);
      
      // Modifier
      await repo.update(
        id: testInterview.id,
        date: DateTime(2024, 4, 1),
        time: '15:00',
        mode: InterviewMode.presentiel,
      );
      
      final interviews = await repo.fetchForEmployer(1);
      final updated = interviews.firstWhere((i) => i.id == testInterview.id);
      
      expect(updated.seekerRead, false);
    });
  });

  group('InterviewRepository - Statut', () {
    late Interview testInterview;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const InterviewRepository();
      
      testInterview = await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Test Candidate',
        offerTitle: 'Test Offer',
        date: DateTime(2024, 2, 15),
        time: '14:30',
        mode: InterviewMode.presentiel,
      );
    });

    test('annule un entretien', () async {
      final repo = const InterviewRepository();
      
      await repo.cancel(testInterview.id);
      
      final interviews = await repo.fetchForEmployer(1);
      expect(interviews.where((i) => i.id == testInterview.id), isEmpty);
    });

    test('marque un entretien comme terminé', () async {
      final repo = const InterviewRepository();
      
      await repo.updateStatus(testInterview.id, InterviewStatus.done);
      
      final interviews = await repo.fetchForEmployer(1);
      final updated = interviews.firstWhere((i) => i.id == testInterview.id);
      
      expect(updated.status, InterviewStatus.done);
    });

    test('supprime un entretien', () async {
      final repo = const InterviewRepository();
      
      await repo.delete(testInterview.id);
      
      final interviews = await repo.fetchForEmployer(1);
      expect(interviews.where((i) => i.id == testInterview.id), isEmpty);
    });
  });

  group('InterviewRepository - Récupération', () {
    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const InterviewRepository();
      
      // Créer plusieurs entretiens
      await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Jean',
        offerTitle: 'Job 1',
        date: DateTime(2024, 3, 1),
        time: '09:00',
        mode: InterviewMode.presentiel,
      );
      
      await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate2',
        candidateName: 'Marie',
        offerTitle: 'Job 2',
        date: DateTime(2024, 3, 5),
        time: '14:00',
        mode: InterviewMode.visio,
      );
      
      await repo.schedule(
        employerUserId: 2,
        jobSeekerUserId: 'candidate3',
        candidateName: 'Pierre',
        offerTitle: 'Job 3',
        date: DateTime(2024, 3, 10),
        time: '10:30',
        mode: InterviewMode.presentiel,
      );
    });

    test('récupère tous les entretiens d\'un recruteur', () async {
      final repo = const InterviewRepository();
      final interviews = await repo.fetchForEmployer(1);
      
      expect(interviews.length, 2);
      expect(interviews.every((i) => i.employerUserId == 1), true);
    });

    test('récupère les entretiens du jour', () async {
      final repo = const InterviewRepository();
      
      // Créer un entretien pour aujourd'hui
      await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate4',
        candidateName: 'Aujourd\'hui',
        offerTitle: 'Job Today',
        date: DateTime.now(),
        time: '16:00',
        mode: InterviewMode.presentiel,
      );
      
      final todayInterviews = await repo.fetchTodayForEmployer(1);
      expect(todayInterviews.length, 1);
      expect(todayInterviews.first.candidateName, 'Aujourd\'hui');
    });

    test('récupère les entretiens à venir', () async {
      final repo = const InterviewRepository();
      
      // Entretien passé
      await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate5',
        candidateName: 'Passé',
        offerTitle: 'Job Past',
        date: DateTime(2020, 1, 1),
        time: '09:00',
        mode: InterviewMode.presentiel,
      );
      
      final upcoming = await repo.fetchUpcomingForEmployer(1);
      expect(upcoming.every((i) => i.scheduledDateTime == null || i.scheduledDateTime!.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))), true);
    });

    test('compte les entretiens à venir', () async {
      final repo = const InterviewRepository();
      final count = await repo.countUpcomingForEmployer(1);
      expect(count, greaterThan(0));
    });
  });

  group('InterviewRepository - Notifications candidat', () {
    late Interview testInterview;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const InterviewRepository();
      
      testInterview = await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Test Candidate',
        offerTitle: 'Test Offer',
        date: DateTime(2024, 2, 15),
        time: '14:30',
        mode: InterviewMode.presentiel,
      );
    });

    test('récupère les notifications pour un candidat', () async {
      final repo = const InterviewRepository();
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      
      expect(notifications.length, 1);
      expect(notifications.first.id, testInterview.id);
      expect(notifications.first.seekerRead, false);
    });

    test('marque une notification comme lue', () async {
      final repo = const InterviewRepository();
      
      await repo.markSeekerNotificationRead(testInterview.id);
      
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      expect(notifications.first.seekerRead, true);
    });

    test('compte les notifications non lues', () async {
      final repo = const InterviewRepository();
      
      final count = await repo.countUnreadNotificationsForJobSeeker('candidate1');
      expect(count, 1);
      
      await repo.markSeekerNotificationRead(testInterview.id);
      
      final countAfter = await repo.countUnreadNotificationsForJobSeeker('candidate1');
      expect(countAfter, 0);
    });

    test('supprime une notification', () async {
      final repo = const InterviewRepository();
      
      await repo.deleteSeekerNotification(testInterview.id);
      
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      expect(notifications.length, 0);
    });

    test('marque toutes les notifications comme lues', () async {
      final repo = const InterviewRepository();
      
      // Créer un deuxième entretien
      await repo.schedule(
        employerUserId: 1,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Second',
        offerTitle: 'Second Offer',
        date: DateTime(2024, 3, 1),
        time: '10:00',
        mode: InterviewMode.presentiel,
      );
      
      await repo.markAllSeekerNotificationsRead('candidate1');
      
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      expect(notifications.every((n) => n.seekerRead), true);
    });

    test('compte tous les entretiens non supprimés', () async {
      final repo = const InterviewRepository();
      
      final count = await repo.countForJobSeeker('candidate1');
      expect(count, greaterThan(0));
      
      await repo.deleteSeekerNotification(testInterview.id);
      
      final countAfter = await repo.countForJobSeeker('candidate1');
      expect(countAfter, lessThan(count));
    });
  });

  group('InterviewRepository - Utilitaires', () {
    test('compareBySchedule trie correctement', () async {
      final repo = const InterviewRepository();
      
      final interview1 = Interview(
        id: 1,
        employerUserId: 1,
        jobSeekerUserId: 'c1',
        candidateName: 'A',
        offerTitle: 'Job',
        date: DateTime(2024, 3, 10),
        time: '10:00',
        mode: InterviewMode.presentiel,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      final interview2 = Interview(
        id: 2,
        employerUserId: 1,
        jobSeekerUserId: 'c2',
        candidateName: 'B',
        offerTitle: 'Job',
        date: DateTime(2024, 3, 5),
        time: '14:00',
        mode: InterviewMode.presentiel,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      final interview3 = Interview(
        id: 3,
        employerUserId: 1,
        jobSeekerUserId: 'c3',
        candidateName: 'C',
        offerTitle: 'Job',
        date: null, // Date à définir
        mode: InterviewMode.presentiel,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      final sorted = [interview1, interview2, interview3]..sort(Interview.compareBySchedule);
      
      expect(sorted[0].id, 2); // 5 mars (plus proche)
      expect(sorted[1].id, 1); // 10 mars
      expect(sorted[2].id, 3); // Date à définir (dernier)
    });

    test('les getters d\'étiquette fonctionnent', () async {
      final repo = const InterviewRepository();
      
      final withDate = Interview(
        id: 1,
        employerUserId: 1,
        jobSeekerUserId: 'c1',
        candidateName: 'A',
        offerTitle: 'Job',
        date: DateTime(2024, 2, 15),
        time: '14:30',
        mode: InterviewMode.presentiel,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      expect(withDate.dateLabel, '15 Fév 2024');
      expect(withDate.timeLabel, '14:30');
      expect(withDate.whenLabel, '15 Fév 2024 · 14:30');
      expect(withDate.isDateToBeDefined, false);
      
      final withoutDate = Interview(
        id: 2,
        employerUserId: 1,
        jobSeekerUserId: 'c2',
        candidateName: 'B',
        offerTitle: 'Job',
        mode: InterviewMode.presentiel,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      expect(withoutDate.dateLabel, 'Date à définir');
      expect(withoutDate.timeLabel, 'Heure à définir');
      expect(withoutDate.whenLabel, 'Date à définir');
      expect(withoutDate.isDateToBeDefined, true);
    });

    test('locationLabel retourne le lieu ou un texte par défaut', () async {
      final repo = const InterviewRepository();
      
      final withLocation = Interview(
        id: 1,
        employerUserId: 1,
        jobSeekerUserId: 'c1',
        candidateName: 'A',
        offerTitle: 'Job',
        location: 'Bureau Central',
        mode: InterviewMode.presentiel,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      expect(withLocation.locationLabel, 'Bureau Central');
      
      final withoutLocationPresentiel = Interview(
        id: 2,
        employerUserId: 1,
        jobSeekerUserId: 'c2',
        candidateName: 'B',
        offerTitle: 'Job',
        mode: InterviewMode.presentiel,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      expect(withoutLocationPresentiel.locationLabel, 'Lieu à préciser');
      
      final withoutLocationVisio = Interview(
        id: 3,
        employerUserId: 1,
        jobSeekerUserId: 'c3',
        candidateName: 'C',
        offerTitle: 'Job',
        mode: InterviewMode.visio,
        status: InterviewStatus.scheduled,
        createdAt: DateTime.now(),
      );
      
      expect(withoutLocationVisio.locationLabel, 'Visioconférence');
    });
  });
}
