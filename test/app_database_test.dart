import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:joem/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    // Configuration pour les tests (simule path_provider)
    tempDir = Directory.systemTemp.createTempSync('joem_test_db');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    // Initialisation de sqflite FFI pour les tests desktop
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  tearDownAll(() async {
    await AppDatabase.instance.resetDatabase();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppDatabase - Ouverture et initialisation', () {
    test('ouvre la base de données avec succès', () async {
      final db = await AppDatabase.instance.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('crée toutes les tables requises au premier lancement', () async {
      final db = await AppDatabase.instance.database;
      
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      
      // Tables principales
      expect(tableNames, contains('users'));
      expect(tableNames, contains('job_seeker_profiles'));
      expect(tableNames, contains('employer_profiles'));
      expect(tableNames, contains('job_offers'));
      expect(tableNames, contains('job_applications'));
      expect(tableNames, contains('interviews'));
      
      // Tables auxiliaires
      expect(tableNames, contains('job_seeker_skills'));
      expect(tableNames, contains('job_seeker_work_modes'));
      expect(tableNames, contains('job_offer_saves'));
      expect(tableNames, contains('job_offer_notification_reads'));
      expect(tableNames, contains('job_application_notification_reads'));
      expect(tableNames, contains('job_seeker_experiences'));
      expect(tableNames, contains('search_history'));
      expect(tableNames, contains('job_offer_views'));
      expect(tableNames, contains('job_offer_categories'));
      expect(tableNames, contains('job_seeker_profile_views'));
      expect(tableNames, contains('job_seeker_portfolio_projects'));
      expect(tableNames, contains('job_seeker_formations'));
      expect(tableNames, contains('job_seeker_certifications'));
      expect(tableNames, contains('job_seeker_professional_links'));
      expect(tableNames, contains('session'));
    });

    test('active les clés étrangères', () async {
      final db = await AppDatabase.instance.database;
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], 1);
    });
  });

  group('AppDatabase - CRUD basique', () {
    test('insère et lit un utilisateur', () async {
      final db = await AppDatabase.instance.database;
      
      await db.insert('users', {
        'email': 'test@example.com',
        'password_hash': 'hashed_password',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      final users = await db.query('users', where: 'email = ?', whereArgs: ['test@example.com']);
      expect(users.length, 1);
      expect(users.first['email'], 'test@example.com');
      expect(users.first['role'], 'job_seeker');
    });

    test('met à jour un utilisateur', () async {
      final db = await AppDatabase.instance.database;
      
      final id = await db.insert('users', {
        'email': 'update@example.com',
        'password_hash': 'old_hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.update(
        'users',
        {'password_hash': 'new_hash'},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      final updated = await db.query('users', where: 'id = ?', whereArgs: [id]);
      expect(updated.first['password_hash'], 'new_hash');
    });

    test('supprime un utilisateur', () async {
      final db = await AppDatabase.instance.database;
      
      final id = await db.insert('users', {
        'email': 'delete@example.com',
        'password_hash': 'hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      final deleted = await db.delete('users', where: 'id = ?', whereArgs: [id]);
      expect(deleted, 1);
      
      final remaining = await db.query('users', where: 'id = ?', whereArgs: [id]);
      expect(remaining.length, 0);
    });

    test('les contraintes UNIQUE fonctionnent', () async {
      final db = await AppDatabase.instance.database;
      
      await db.insert('users', {
        'email': 'unique@example.com',
        'password_hash': 'hash1',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      expect(
        () => db.insert('users', {
          'email': 'unique@example.com',
          'password_hash': 'hash2',
          'role': 'employer',
          'created_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('AppDatabase - Relations et CASCADE', () {
    test('suppression en cascade: utilisateur -> job_seeker_profile', () async {
      final db = await AppDatabase.instance.database;
      
      final userId = await db.insert('users', {
        'email': 'cascade@example.com',
        'password_hash': 'hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('job_seeker_profiles', {
        'user_id': userId,
        'nom': 'Test',
        'prenom': 'User',
        'titre_professionnel': 'Developer',
      });
      
      // Vérifier que le profil existe
      final profiles = await db.query('job_seeker_profiles', where: 'user_id = ?', whereArgs: [userId]);
      expect(profiles.length, 1);
      
      // Supprimer l'utilisateur
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      
      // Vérifier que le profil est supprimé en cascade
      final remainingProfiles = await db.query('job_seeker_profiles', where: 'user_id = ?', whereArgs: [userId]);
      expect(remainingProfiles.length, 0);
    });

    test('suppression en cascade: job_offer -> job_application', () async {
      final db = await AppDatabase.instance.database;
      
      final offerId = await db.insert('job_offers', {
        'employer_user_id': 999,
        'company_name': 'Test Company',
        'title': 'Test Job',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('job_applications', {
        'job_offer_id': offerId,
        'job_seeker_user_id': 'test_user',
        'candidate_name': 'Test Candidate',
        'applied_at': DateTime.now().toIso8601String(),
      });
      
      // Vérifier que la candidature existe
      final applications = await db.query('job_applications', where: 'job_offer_id = ?', whereArgs: [offerId]);
      expect(applications.length, 1);
      
      // Supprimer l'offre
      await db.delete('job_offers', where: 'id = ?', whereArgs: [offerId]);
      
      // Vérifier que la candidature est supprimée en cascade
      final remainingApps = await db.query('job_applications', where: 'job_offer_id = ?', whereArgs: [offerId]);
      expect(remainingApps.length, 0);
    });
  });

  group('AppDatabase - Types de données', () {
    test('stocke et lit des BLOB (images)', () async {
      final db = await AppDatabase.instance.database;
      
      final testData = [1, 2, 3, 4, 5];
      
      await db.insert('job_seeker_profiles', {
        'user_id': 999,
        'nom': 'Test',
        'prenom': 'User',
        'titre_professionnel': 'Developer',
        'photo': testData,
      });
      
      final profiles = await db.query('job_seeker_profiles', where: 'user_id = ?', whereArgs: [999]);
      expect(profiles.first['photo'], testData);
    });

    test('stocke et lit des dates ISO8601', () async {
      final db = await AppDatabase.instance.database;
      
      final testDate = DateTime(2024, 1, 15, 14, 30);
      
      await db.insert('job_offers', {
        'employer_user_id': 999,
        'company_name': 'Test Company',
        'title': 'Test Job',
        'created_at': testDate.toIso8601String(),
      });
      
      final offers = await db.query('job_offers', where: 'employer_user_id = ?', whereArgs: [999]);
      final parsedDate = DateTime.parse(offers.first['created_at'] as String);
      expect(parsedDate.year, testDate.year);
      expect(parsedDate.month, testDate.month);
      expect(parsedDate.day, testDate.day);
    });
  });

  group('AppDatabase - resetDatabase', () {
    test('supprime et recrée la base de données', () async {
      final db = await AppDatabase.instance.database;
      
      // Insérer des données
      await db.insert('users', {
        'email': 'reset_test@example.com',
        'password_hash': 'hash',
        'role': 'job_seeker',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Vérifier que les données existent
      final beforeReset = await db.query('users');
      expect(beforeReset.length, greaterThan(0));
      
      // Reset
      await AppDatabase.instance.resetDatabase();
      
      // Réouvrir la base
      final newDb = await AppDatabase.instance.database;
      
      // Vérifier que la base est vide
      final afterReset = await newDb.query('users');
      expect(afterReset.length, 0);
    });
  });

  group('AppDatabase - Transactions', () {
    test('rollback en cas d\'erreur dans une transaction', () async {
      final db = await AppDatabase.instance.database;
      
      try {
        await db.transaction((txn) async {
          await txn.insert('users', {
            'email': 'transaction1@example.com',
            'password_hash': 'hash',
            'role': 'job_seeker',
            'created_at': DateTime.now().toIso8601String(),
          });
          
          // Tenter d'insérer un doublon (violation UNIQUE)
          await txn.insert('users', {
            'email': 'transaction1@example.com',
            'password_hash': 'hash2',
            'role': 'employer',
            'created_at': DateTime.now().toIso8601String(),
          });
        });
        fail('La transaction aurait dû échouer');
      } catch (e) {
        // Expected
      }
      
      // Vérifier que rien n'a été inséré
      final users = await db.query('users', where: 'email = ?', whereArgs: ['transaction1@example.com']);
      expect(users.length, 0);
    });

    test('commit réussi d\'une transaction', () async {
      final db = await AppDatabase.instance.database;
      
      await db.transaction((txn) async {
        await txn.insert('users', {
          'email': 'transaction2@example.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        await txn.insert('job_seeker_profiles', {
          'user_id': 1, // Sera l'ID du user inséré ci-dessus
          'nom': 'Test',
          'prenom': 'User',
          'titre_professionnel': 'Developer',
        });
      });
      
      // Vérifier que les données sont là
      final users = await db.query('users', where: 'email = ?', whereArgs: ['transaction2@example.com']);
      expect(users.length, 1);
    });
  });
}
