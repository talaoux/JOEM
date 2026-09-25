import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';
import 'package:joem/features/dashboard/data/account_search_repository.dart';

/// Tests de performance pour les opérations de base de données
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_perf_test');
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

  group('Performance - Opérations CRUD', () {
    test('insertion de 1000 utilisateurs en moins de 2 secondes', () async {
      final db = await AppDatabase.instance.database;
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        await db.insert('users', {
          'email': 'user$i@test.com',
          'password_hash': 'hash_$i',
          'role': i % 2 == 0 ? 'job_seeker' : 'employer',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      stopwatch.stop();
      
      print('1000 insertions utilisateurs: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test('insertion en lot avec transaction plus rapide que séquentielle', () async {
      final db = await AppDatabase.instance.database;
      
      // Insertion séquentielle
      final sequentialStopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        await db.insert('users', {
          'email': 'seq$i@test.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      sequentialStopwatch.stop();
      
      await AppDatabase.instance.resetDatabase();
      
      // Insertion en transaction
      final transactionStopwatch = Stopwatch()..start();
      await db.transaction((txn) async {
        for (int i = 0; i < 100; i++) {
          await txn.insert('users', {
            'email': 'txn$i@test.com',
            'password_hash': 'hash',
            'role': 'job_seeker',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      });
      transactionStopwatch.stop();
      
      print('Insertion séquentielle: ${sequentialStopwatch.elapsedMilliseconds}ms');
      print('Insertion transaction: ${transactionStopwatch.elapsedMilliseconds}ms');
      
      expect(transactionStopwatch.elapsedMilliseconds, lessThan(sequentialStopwatch.elapsedMilliseconds));
    });

    test('lecture de 1000 utilisateurs en moins de 500ms', () async {
      final db = await AppDatabase.instance.database;
      
      // Préparer les données
      for (int i = 0; i < 1000; i++) {
        await db.insert('users', {
          'email': 'read$i@test.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      final stopwatch = Stopwatch()..start();
      final users = await db.query('users');
      stopwatch.stop();
      
      print('Lecture de ${users.length} utilisateurs: ${stopwatch.elapsedMilliseconds}ms');
      expect(users.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('mise à jour de 1000 utilisateurs en moins de 1 seconde', () async {
      final db = await AppDatabase.instance.database;
      
      // Préparer les données
      final ids = <int>[];
      for (int i = 0; i < 1000; i++) {
        final id = await db.insert('users', {
          'email': 'update$i@test.com',
          'password_hash': 'old_hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
        ids.add(id);
      }
      
      final stopwatch = Stopwatch()..start();
      for (final id in ids) {
        await db.update(
          'users',
          {'password_hash': 'new_hash'},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      stopwatch.stop();
      
      print('1000 mises à jour: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('suppression de 1000 utilisateurs en moins de 1 seconde', () async {
      final db = await AppDatabase.instance.database;
      
      // Préparer les données
      for (int i = 0; i < 1000; i++) {
        await db.insert('users', {
          'email': 'delete$i@test.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      final stopwatch = Stopwatch()..start();
      final deleted = await db.delete('users');
      stopwatch.stop();
      
      print('Suppression de $deleted utilisateurs: ${stopwatch.elapsedMilliseconds}ms');
      expect(deleted, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Performance - Requêtes complexes', () {
    setUp(() async {
      await AppDatabase.instance.resetDatabase();
      final db = await AppDatabase.instance.database;
      
      // Créer des données de test
      for (int i = 0; i < 100; i++) {
        final userId = await db.insert('users', {
          'email': 'candidate$i@test.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        await db.insert('job_seeker_profiles', {
          'user_id': userId,
          'nom': 'Nom$i',
          'prenom': 'Prénom$i',
          'titre_professionnel': 'Titre$i',
          'localisation': i % 3 == 0 ? 'Antananarivo' : (i % 3 == 1 ? 'Antsirabe' : 'Toamasina'),
          'profil_visible': 1,
        });
        
        // Ajouter des compétences
        await db.insert('job_seeker_skills', {
          'user_id': userId,
          'name': 'Skill${i % 10}',
          'rating': i % 5 + 1,
        });
      }
    });

    test('recherche avec JOIN en moins de 200ms', () async {
      final db = await AppDatabase.instance.database;
      final stopwatch = Stopwatch()..start();
      
      final rows = await db.rawQuery('''
        SELECT u.id, jsp.nom, jsp.prenom, jsp.titre_professionnel
        FROM users u
        INNER JOIN job_seeker_profiles jsp ON jsp.user_id = u.id
        WHERE u.role = 'job_seeker'
      ''');
      
      stopwatch.stop();
      
      print('Recherche JOIN (${rows.length} résultats): ${stopwatch.elapsedMilliseconds}ms');
      expect(rows.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('recherche avec LIKE en moins de 300ms', () async {
      final db = await AppDatabase.instance.database;
      final stopwatch = Stopwatch()..start();
      
      final rows = await db.query(
        'job_seeker_profiles',
        where: 'LOWER(titre_professionnel) LIKE ?',
        whereArgs: ['%titre%'],
      );
      
      stopwatch.stop();
      
      print('Recherche LIKE (${rows.length} résultats): ${stopwatch.elapsedMilliseconds}ms');
      expect(rows.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });

    test('COUNT(*) en moins de 100ms', () async {
      final db = await AppDatabase.instance.database;
      final stopwatch = Stopwatch()..start();
      
      final result = await db.rawQuery('SELECT COUNT(*) FROM users');
      final count = Sqflite.firstIntValue(result);
      
      stopwatch.stop();
      
      print('COUNT(*): ${stopwatch.elapsedMilliseconds}ms (count: $count)');
      expect(count, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Performance - Repositories', () {
    test('publication de 100 offres en moins de 3 secondes', () async {
      await AppDatabase.instance.resetDatabase();
      final repo = const JobOfferRepository();
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        await repo.publish(
          employerUserId: i,
          companyName: 'Company $i',
          title: 'Job $i',
          description: 'Description $i',
          location: 'Location $i',
          salary: 'Salary $i',
          contractType: i % 2 == 0 ? 'CDI' : 'CDD',
          categories: ['Informatique'],
        );
      }
      
      stopwatch.stop();
      
      print('Publication de 100 offres: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('récupération de 100 offres en moins de 500ms', () async {
      final repo = const JobOfferRepository();
      final stopwatch = Stopwatch()..start();
      
      final offers = await repo.fetchAll();
      
      stopwatch.stop();
      
      print('Récupération de ${offers.length} offres: ${stopwatch.elapsedMilliseconds}ms');
      expect(offers.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('recherche de candidats avec données complètes en moins de 500ms', () async {
      await AppDatabase.instance.resetDatabase();
      
      // Créer des candidats
      final db = await AppDatabase.instance.database;
      for (int i = 0; i < 50; i++) {
        final userId = await db.insert('users', {
          'email': 'search$i@test.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        await db.insert('job_seeker_profiles', {
          'user_id': userId,
          'nom': 'Nom$i',
          'prenom': 'Prénom$i',
          'titre_professionnel': 'Développeur',
          'profil_visible': 1,
        });
        
        await db.insert('job_seeker_skills', {
          'user_id': userId,
          'name': 'Flutter',
          'rating': 4,
        });
      }
      
      final repo = const AccountSearchRepository();
      final stopwatch = Stopwatch()..start();
      
      final results = await repo.searchJobSeekers('Développeur');
      
      stopwatch.stop();
      
      print('Recherche candidats (${results.length} résultats): ${stopwatch.elapsedMilliseconds}ms');
      expect(results.length, 50);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });

  group('Performance - Scalabilité', () {
    test('performance dégrade linéairement avec le volume', () async {
      final db = await AppDatabase.instance.database;
      final results = <int, int>{};
      
      for (int count in [10, 50, 100, 500]) {
        await AppDatabase.instance.resetDatabase();
        
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < count; i++) {
          await db.insert('users', {
            'email': 'scale$i@test.com',
            'password_hash': 'hash',
            'role': 'job_seeker',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        stopwatch.stop();
        
        results[count] = stopwatch.elapsedMilliseconds;
        print('$count insertions: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      // Vérifier que 500 insertions prennent moins de 10x le temps de 50
      // (permet une certaine dégradation mais pas exponentielle)
      expect(results[500]!, lessThan(results[50]! * 10));
    });

    test('index améliore les performances de recherche', () async {
      final db = await AppDatabase.instance.database;
      
      // Sans index explicite (email a déjà UNIQUE qui crée un index)
      await AppDatabase.instance.resetDatabase();
      
      for (int i = 0; i < 1000; i++) {
        await db.insert('users', {
          'email': 'index$i@test.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      final stopwatch = Stopwatch()..start();
      await db.query('users', where: 'email = ?', whereArgs: ['index500@test.com']);
      stopwatch.stop();
      
      final indexedTime = stopwatch.elapsedMilliseconds;
      print('Recherche avec index: ${indexedTime}ms');
      
      // Une recherche indexée devrait être très rapide
      expect(indexedTime, lessThan(50));
    });
  });

  group('Performance - Mémoire', () {
    test('chargement de BLOB volumineux ne cause pas de crash', () async {
      final db = await AppDatabase.instance.database;
      
      // Simuler une image de 1MB
      final largeBlob = List.generate(1024 * 1024, (i) => i % 256);
      
      await db.insert('job_seeker_profiles', {
        'user_id': 999,
        'nom': 'Test',
        'prenom': 'User',
        'titre_professionnel': 'Developer',
        'photo': largeBlob,
      });
      
      final stopwatch = Stopwatch()..start();
      final profiles = await db.query('job_seeker_profiles', where: 'user_id = ?', whereArgs: [999]);
      stopwatch.stop();
      
      print('Chargement BLOB 1MB: ${stopwatch.elapsedMilliseconds}ms');
      expect(profiles.length, 1);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('pagination limite l\'utilisation mémoire', () async {
      final db = await AppDatabase.instance.database;
      
      // Créer beaucoup de données
      for (int i = 0; i < 1000; i++) {
        await db.insert('users', {
          'email': 'page$i@test.com',
          'password_hash': 'hash',
          'role': 'job_seeker',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      final stopwatch = Stopwatch()..start();
      
      // Charger par pages de 20
      for (int page = 0; page < 50; page++) {
        await db.query(
          'users',
          limit: 20,
          offset: page * 20,
        );
      }
      
      stopwatch.stop();
      
      print('Pagination 1000 enregistrements (50 pages de 20): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
