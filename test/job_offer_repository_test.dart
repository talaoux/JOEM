import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_test_repo');
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

  group('JobOfferRepository - Publication', () {
    test('publie une offre avec succès', () async {
      final repo = const JobOfferRepository();
      
      final offer = await repo.publish(
        employerUserId: 1,
        companyName: 'Tech Mada',
        title: 'Développeur Flutter',
        description: 'Développement d\'applications mobiles',
        location: 'Antananarivo',
        salary: '500000-800000 MGA',
        contractType: 'CDI',
        categories: ['Informatique'],
      );
      
      expect(offer.id, greaterThan(0));
      expect(offer.companyName, 'Tech Mada');
      expect(offer.title, 'Développeur Flutter');
      expect(offer.contractType, 'CDI');
    });

    test('publie une offre avec logo et image', () async {
      final repo = const JobOfferRepository();
      
      final logoData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final posterData = Uint8List.fromList([6, 7, 8, 9, 10]);
      
      final offer = await repo.publish(
        employerUserId: 2,
        companyName: 'Startup Mada',
        companyLogo: logoData,
        title: 'UX Designer',
        description: 'Design d\'interfaces utilisateur',
        location: 'Tana',
        salary: '400000-600000 MGA',
        contractType: 'CDD',
        posterImage: posterData,
        categories: ['Design'],
      );
      
      expect(offer.companyLogo, logoData);
      expect(offer.posterImage, posterData);
    });

    test('publie une offre avec plusieurs catégories', () async {
      final repo = const JobOfferRepository();
      
      final offer = await repo.publish(
        employerUserId: 3,
        companyName: 'Agence Web',
        title: 'Développeur Full Stack',
        description: 'Développement web complet',
        location: 'Antananarivo',
        salary: '600000-900000 MGA',
        contractType: 'CDI',
        categories: ['Informatique', 'Marketing'],
      );
      
      final categories = await repo.fetchCategoriesForOffer(offer.id);
      expect(categories.length, 2);
      expect(categories, contains('Informatique'));
      expect(categories, contains('Marketing'));
    });

    test('publie une offre dans "Autres" avec secteur personnalisé', () async {
      final repo = const JobOfferRepository();
      
      final offer = await repo.publish(
        employerUserId: 4,
        companyName: 'Entreprise Spéciale',
        title: 'Métier Rare',
        description: 'Description du métier',
        location: 'Fianarantsoa',
        salary: 'À négocier',
        contractType: 'CDI',
        categories: ['Autres'],
        otherSector: 'Secteur personnalisé',
      );
      
      expect(offer.otherSector, 'Secteur personnalisé');
    });
  });

  group('JobOfferRepository - Récupération', () {
    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const JobOfferRepository();
      
      // Créer des offres de test
      await repo.publish(
        employerUserId: 1,
        companyName: 'Company A',
        title: 'Job 1',
        description: 'Description 1',
        location: 'Tana',
        salary: '500000',
        contractType: 'CDI',
        categories: ['Informatique'],
      );
      
      await repo.publish(
        employerUserId: 2,
        companyName: 'Company B',
        title: 'Job 2',
        description: 'Description 2',
        location: 'Antsirabe',
        salary: '400000',
        contractType: 'CDD',
        categories: ['Marketing'],
      );
      
      await repo.publish(
        employerUserId: 1,
        companyName: 'Company A',
        title: 'Job 3',
        description: 'Description 3',
        location: 'Toamasina',
        salary: '600000',
        contractType: 'CDI',
        categories: ['Informatique', 'Design'],
      );
    });

    test('récupère toutes les offres', () async {
      final repo = const JobOfferRepository();
      final offers = await repo.fetchAll();
      
      expect(offers.length, 3);
      expect(offers.first.companyName, 'Company A');
      expect(offers.first.title, 'Job 3'); // Plus récente en premier
    });

    test('récupère les offres par recruteur', () async {
      final repo = const JobOfferRepository();
      final offers = await repo.fetchByEmployer(1);
      
      expect(offers.length, 2);
      expect(offers.every((o) => o.employerUserId == 1), true);
    });

    test('récupère les offres par catégorie', () async {
      final repo = const JobOfferRepository();
      final offers = await repo.fetchByCategory('Informatique');
      
      expect(offers.length, 2);
    });

    test('récupère les catégories d\'une offre', () async {
      final repo = const JobOfferRepository();
      final offers = await repo.fetchByEmployer(1);
      final multiCategoryOffer = offers.firstWhere((o) => o.title == 'Job 3');
      
      final categories = await repo.fetchCategoriesForOffer(multiCategoryOffer.id);
      expect(categories.length, 2);
    });
  });

  group('JobOfferRepository - Candidatures', () {
    late JobOffer testOffer;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const JobOfferRepository();
      
      testOffer = await repo.publish(
        employerUserId: 1,
        companyName: 'Test Company',
        title: 'Test Job',
        description: 'Test Description',
        location: 'Tana',
        salary: '500000',
        contractType: 'CDI',
        categories: ['Informatique'],
      );
    });

    test('un candidat postule à une offre', () async {
      final repo = const JobOfferRepository();
      
      await repo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: 'candidate1',
        candidateName: 'Jean Dupont',
        candidatePosition: 'Développeur',
      );
      
      final hasApplied = await repo.hasApplied(testOffer.id, 'candidate1');
      expect(hasApplied, true);
    });

    test('postuler deux fois ne crée pas de doublon', () async {
      final repo = const JobOfferRepository();
      
      await repo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: 'candidate2',
        candidateName: 'Marie Curie',
        candidatePosition: 'Scientifique',
      );
      
      await repo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: 'candidate2',
        candidateName: 'Marie Curie',
        candidatePosition: 'Scientifique',
      );
      
      // Vérifier qu'il n'y a qu'une seule candidature
      final db = await AppDatabase.instance.database;
      final applications = await db.query(
        'job_applications',
        where: 'job_offer_id = ? AND job_seeker_user_id = ?',
        whereArgs: [testOffer.id, 'candidate2'],
      );
      expect(applications.length, 1);
    });

    test('un candidat retire sa candidature', () async {
      final repo = const JobOfferRepository();
      
      await repo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: 'candidate3',
        candidateName: 'Pierre Martin',
        candidatePosition: 'Designer',
      );
      
      final withdrawn = await repo.withdrawApplication(
        jobOfferId: testOffer.id,
        jobSeekerUserId: 'candidate3',
      );
      
      expect(withdrawn, true);
      
      final hasApplied = await repo.hasApplied(testOffer.id, 'candidate3');
      expect(hasApplied, false);
    });

    test('ne peut pas retirer une candidature acceptée', () async {
      final repo = const JobOfferRepository();
      
      await repo.apply(
        jobOfferId: testOffer.id,
        jobSeekerUserId: 'candidate4',
        candidateName: 'Sophie Bernard',
        candidatePosition: 'Manager',
      );
      
      // Accepter la candidature
      final db = await AppDatabase.instance.database;
      final applications = await db.query(
        'job_applications',
        where: 'job_offer_id = ? AND job_seeker_user_id = ?',
        whereArgs: [testOffer.id, 'candidate4'],
      );
      final applicationId = applications.first['id'] as int;
      
      await repo.acceptApplication(applicationId);
      
      // Tenter de retirer
      final withdrawn = await repo.withdrawApplication(
        jobOfferId: testOffer.id,
        jobSeekerUserId: 'candidate4',
      );
      
      expect(withdrawn, false);
    });
  });

  group('JobOfferRepository - Notifications', () {
    late JobOffer testOffer;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const JobOfferRepository();
      
      testOffer = await repo.publish(
        employerUserId: 1,
        companyName: 'Test Company',
        title: 'Test Job',
        description: 'Test Description',
        location: 'Tana',
        salary: '500000',
        contractType: 'CDI',
        categories: ['Informatique'],
      );
    });

    test('récupère les notifications pour un candidat', () async {
      final repo = const JobOfferRepository();
      
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      
      expect(notifications.length, 1);
      expect(notifications.first.offer.id, testOffer.id);
      expect(notifications.first.isRead, false);
    });

    test('marque une notification comme lue', () async {
      final repo = const JobOfferRepository();
      
      await repo.markNotificationRead(testOffer.id, 'candidate1');
      
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      expect(notifications.first.isRead, true);
    });

    test('compte les notifications non lues', () async {
      final repo = const JobOfferRepository();
      
      final count = await repo.countUnreadNotificationsForJobSeeker('candidate1');
      expect(count, 1);
      
      await repo.markNotificationRead(testOffer.id, 'candidate1');
      
      final countAfter = await repo.countUnreadNotificationsForJobSeeker('candidate1');
      expect(countAfter, 0);
    });

    test('supprime une notification', () async {
      final repo = const JobOfferRepository();
      
      await repo.deleteNotification(testOffer.id, 'candidate1');
      
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      expect(notifications.length, 0);
    });

    test('marque toutes les notifications comme lues', () async {
      final repo = const JobOfferRepository();
      
      // Créer une deuxième offre
      final offer2 = await repo.publish(
        employerUserId: 2,
        companyName: 'Company 2',
        title: 'Job 2',
        description: 'Desc 2',
        location: 'Tana',
        salary: '400000',
        contractType: 'CDD',
        categories: ['Marketing'],
      );
      
      await repo.markAllNotificationsRead('candidate1');
      
      final notifications = await repo.fetchNotificationsForJobSeeker('candidate1');
      expect(notifications.every((n) => n.isRead), true);
    });
  });

  group('JobOfferRepository - Modification', () {
    late JobOffer testOffer;

    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final repo = const JobOfferRepository();
      
      testOffer = await repo.publish(
        employerUserId: 1,
        companyName: 'Test Company',
        title: 'Test Job',
        description: 'Test Description',
        location: 'Tana',
        salary: '500000',
        contractType: 'CDI',
        categories: ['Informatique'],
      );
    });

    test('modifie une offre existante', () async {
      final repo = const JobOfferRepository();
      
      final updated = await repo.updateOffer(
        offer: testOffer,
        title: 'Updated Job',
        description: 'Updated Description',
        location: 'Antsirabe',
        salary: '600000',
        contractType: 'CDD',
        categories: ['Marketing'],
      );
      
      expect(updated.title, 'Updated Job');
      expect(updated.description, 'Updated Description');
      expect(updated.location, 'Antsirabe');
      expect(updated.salary, '600000');
      expect(updated.contractType, 'CDD');
      expect(updated.id, testOffer.id); // ID inchangé
    });

    test('les catégories sont remplacées lors de la modification', () async {
      final repo = const JobOfferRepository();
      
      await repo.updateOffer(
        offer: testOffer,
        title: 'Test Job',
        description: 'Test Description',
        location: 'Tana',
        salary: '500000',
        contractType: 'CDI',
        categories: ['Design', 'Marketing'],
      );
      
      final categories = await repo.fetchCategoriesForOffer(testOffer.id);
      expect(categories.length, 2);
      expect(categories, contains('Design'));
      expect(categories, contains('Marketing'));
      expect(categories, isNot(contains('Informatique')));
    });
  });
}
