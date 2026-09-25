import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/dashboard/data/account_search_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_test_search');
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

  group('AccountSearchRepository - Recherche de candidats', () {
    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      
      // Créer des utilisateurs et profils de test
      final db = await AppDatabase.instance.database;
      
      final userId1 = await db.insert('users', {
        'email': 'candidat1@test.com',
        'password_hash': 'hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('job_seeker_profiles', {
        'user_id': userId1,
        'nom': 'Rakoto',
        'prenom': 'Jean',
        'titre_professionnel': 'Développeur Flutter',
        'localisation': 'Antananarivo',
        'telephone': '0341234567',
        'presentation': 'Développeur passionné',
        'profil_visible': 1,
      });
      
      await db.insert('job_seeker_skills', {
        'user_id': userId1,
        'name': 'Flutter',
        'rating': 4,
      });
      
      final userId2 = await db.insert('users', {
        'email': 'candidat2@test.com',
        'password_hash': 'hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('job_seeker_profiles', {
        'user_id': userId2,
        'nom': 'Rasoa',
        'prenom': 'Marie',
        'titre_professionnel': 'Designer UX',
        'localisation': 'Antsirabe',
        'telephone': '0347654321',
        'presentation': 'Designer créative',
        'profil_visible': 1,
      });
      
      await db.insert('job_seeker_skills', {
        'user_id': userId2,
        'name': 'Figma',
        'rating': 5,
      });
      
      // Candidat invisible
      final userId3 = await db.insert('users', {
        'email': 'candidat3@test.com',
        'password_hash': 'hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('job_seeker_profiles', {
        'user_id': userId3,
        'nom': 'Randria',
        'prenom': 'Pierre',
        'titre_professionnel': 'Manager',
        'localisation': 'Toamasina',
        'profil_visible': 0, // Invisible
      });
    });

    test('recherche par nom', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchJobSeekers('Jean');
      
      expect(results.length, 1);
      expect(results.first.firstName, 'Jean');
      expect(results.first.lastName, 'Rakoto');
    });

    test('recherche par titre professionnel', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchJobSeekers('Designer');
      
      expect(results.length, 1);
      expect(results.first.position, 'Designer UX');
    });

    test('recherche par localisation', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchJobSeekers('Antananarivo');
      
      expect(results.length, 1);
      expect(results.first.localisation, 'Antananarivo');
    });

    test('recherche par compétence', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchJobSeekers('Flutter');
      
      expect(results.length, 1);
      expect(results.first.skills, contains('Flutter'));
    });

    test('ne retourne pas les profils invisibles', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchJobSeekers('Pierre');
      
      expect(results.length, 0);
    });

    test('récupère tous les candidats visibles', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.fetchAllJobSeekers();
      
      expect(results.length, 2); // Seuls les 2 visibles
    });

    test('récupère un candidat par ID', () async {
      final repo = const AccountSearchRepository();
      final candidate = await repo.fetchJobSeekerById('1');
      
      expect(candidate, isNotNull);
      expect(candidate!.firstName, 'Jean');
    });

    test('récupère un candidat avec ses compétences', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchJobSeekers('Jean');
      
      expect(results.first.skills.length, greaterThan(0));
      expect(results.first.skills, contains('Flutter'));
    });
  });

  group('AccountSearchRepository - Recherche d\'entreprises', () {
    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      
      final db = await AppDatabase.instance.database;
      
      final userId1 = await db.insert('users', {
        'email': 'company1@test.com',
        'password_hash': 'hash',
        'role': 'employer',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('employer_profiles', {
        'user_id': userId1,
        'nom': 'Director',
        'prenom': 'John',
        'nom_entreprise': 'Tech Mada',
        'localisation': 'Antananarivo',
        'telephone': '0341111111',
        'description': 'Entreprise technologique',
        'entreprise_visible': 1,
      });
      
      final userId2 = await db.insert('users', {
        'email': 'company2@test.com',
        'password_hash': 'hash',
        'role': 'employer',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('employer_profiles', {
        'user_id': userId2,
        'nom': 'Manager',
        'prenom': 'Jane',
        'nom_entreprise': 'Design Studio',
        'localisation': 'Fianarantsoa',
        'telephone': '0342222222',
        'description': 'Agence de design',
        'entreprise_visible': 1,
      });
      
      // Entreprise invisible
      final userId3 = await db.insert('users', {
        'email': 'company3@test.com',
        'password_hash': 'hash',
        'role': 'employer',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('employer_profiles', {
        'user_id': userId3,
        'nom': 'Owner',
        'prenom': 'Bob',
        'nom_entreprise': 'Hidden Company',
        'entreprise_visible': 0,
      });
    });

    test('recherche par nom d\'entreprise', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchEmployers('Tech Mada');
      
      expect(results.length, 1);
      expect(results.first.companyName, 'Tech Mada');
    });

    test('recherche par localisation', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchEmployers('Antananarivo');
      
      expect(results.length, 1);
      expect(results.first.localisation, 'Antananarivo');
    });

    test('recherche par description', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchEmployers('technologique');
      
      expect(results.length, 1);
    });

    test('ne retourne pas les entreprises invisibles', () async {
      final repo = const AccountSearchRepository();
      final results = await repo.searchEmployers('Hidden');
      
      expect(results.length, 0);
    });
  });

  group('AccountSearchRepository - Historique de recherche', () {
    setUp(() async {
      await AppDatabase.instance.resetDatabase();
    });

    test('enregistre une recherche', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Développeur',
      );
      
      final history = await repo.fetchHistory(
        userId: '1',
        searchType: SearchAccountType.candidate,
      );
      
      expect(history.length, 1);
      expect(history.first, 'Développeur');
    });

    test('une recherche répétée remonte en tête', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Flutter',
      );
      
      await Future.delayed(const Duration(milliseconds: 10));
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Designer',
      );
      
      await Future.delayed(const Duration(milliseconds: 10));
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Flutter', // Répété
      );
      
      final history = await repo.fetchHistory(
        userId: '1',
        searchType: SearchAccountType.candidate,
      );
      
      expect(history.length, 2); // Pas de doublon
      expect(history.first, 'Flutter'); // Remonté en tête
    });

    test('limite l\'historique à 8 entrées', () async {
      final repo = const AccountSearchRepository();
      
      for (int i = 1; i <= 10; i++) {
        await repo.recordSearch(
          userId: '1',
          searchType: SearchAccountType.candidate,
          query: 'Query $i',
        );
      }
      
      final history = await repo.fetchHistory(
        userId: '1',
        searchType: SearchAccountType.candidate,
      );
      
      expect(history.length, 8);
    });

    test('supprime une entrée d\'historique', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Test',
      );
      
      await repo.removeHistoryEntry(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Test',
      );
      
      final history = await repo.fetchHistory(
        userId: '1',
        searchType: SearchAccountType.candidate,
      );
      
      expect(history.length, 0);
    });

    test('efface tout l\'historique', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Query 1',
      );
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Query 2',
      );
      
      await repo.clearHistory(
        userId: '1',
        searchType: SearchAccountType.candidate,
      );
      
      final history = await repo.fetchHistory(
        userId: '1',
        searchType: SearchAccountType.candidate,
      );
      
      expect(history.length, 0);
    });

    test('sépare l\'historique par type de recherche', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.candidate,
        query: 'Développeur',
      );
      
      await repo.recordSearch(
        userId: '1',
        searchType: SearchAccountType.company,
        query: 'Tech Mada',
      );
      
      final candidateHistory = await repo.fetchHistory(
        userId: '1',
        searchType: SearchAccountType.candidate,
      );
      
      final companyHistory = await repo.fetchHistory(
        userId: '1',
        searchType: SearchAccountType.company,
      );
      
      expect(candidateHistory.length, 1);
      expect(companyHistory.length, 1);
      expect(candidateHistory.first, 'Développeur');
      expect(companyHistory.first, 'Tech Mada');
    });
  });

  group('AccountSearchRepository - Vues de profil', () {
    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      
      final db = await AppDatabase.instance.database;
      
      // Créer un candidat
      final candidateId = await db.insert('users', {
        'email': 'candidate@test.com',
        'password_hash': 'hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('job_seeker_profiles', {
        'user_id': candidateId,
        'nom': 'Test',
        'prenom': 'Candidate',
        'titre_professionnel': 'Developer',
        'profil_visible': 1,
      });
      
      // Créer des recruteurs
      final employerId1 = await db.insert('users', {
        'email': 'employer1@test.com',
        'password_hash': 'hash',
        'role': 'employer',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('employer_profiles', {
        'user_id': employerId1,
        'nom': 'Recruiter',
        'prenom': 'One',
        'nom_entreprise': 'Company A',
        'entreprise_visible': 1,
      });
      
      final employerId2 = await db.insert('users', {
        'email': 'employer2@test.com',
        'password_hash': 'hash',
        'role': 'employer',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('employer_profiles', {
        'user_id': employerId2,
        'nom': 'Recruiter',
        'prenom': 'Two',
        'nom_entreprise': 'Company B',
        'entreprise_visible': 1,
      });
    });

    test('enregistre une vue de profil', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '2',
      );
      
      final count = await repo.countProfileViews('1');
      expect(count, 1);
    });

    test('un même recruteur ne compte qu\'une fois', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '2',
      );
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '2',
      );
      
      final count = await repo.countProfileViews('1');
      expect(count, 1);
    });

    test('compte les vues de plusieurs recruteurs', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '2',
      );
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '3',
      );
      
      final count = await repo.countProfileViews('1');
      expect(count, 2);
    });

    test('récupère les viewers d\'un profil', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '2',
      );
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '3',
      );
      
      final viewers = await repo.fetchProfileViewers('1');
      
      expect(viewers.length, 2);
      expect(viewers.first.company, isNotNull);
      expect(viewers.first.company!.companyName, 'Company A');
    });

    test('ne compte pas les vues du propriétaire', () async {
      final repo = const AccountSearchRepository();
      
      await repo.recordProfileView(
        profileUserId: '1',
        viewerUserId: '1', // Même utilisateur
      );
      
      final count = await repo.countProfileViews('1');
      expect(count, 0);
    });
  });
}
