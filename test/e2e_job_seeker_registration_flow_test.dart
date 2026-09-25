import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/job_seeker_registration/presentation/job_seeker_registration_screen.dart';

/// Test E2E du flux d'inscription chercheur d'emploi complet
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_e2e_registration');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    // Initialisation de sqflite FFI
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

  group('E2E - Inscription Chercheur d\'Emploi', () {
    testWidgets('flux d\'inscription complet', (tester) async {
      final authService = AuthService();
      
      // Étape 1: Informations personnelles
      await tester.pumpWidget(
        MaterialApp(
          home: JobSeekerRegistrationScreen(
            onRegistrationComplete: () {},
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Vérifier que l'écran s'affiche
      expect(find.text('Inscription Chercheur d\'Emploi'), findsOneWidget);
      
      // Simuler la navigation à travers les étapes
      // Note: Ce test est un squelette - l'implémentation réelle dépendrait
      // de la structure exacte de JobSeekerRegistrationScreen
      
      // Pour un vrai test E2E, on testerait:
      // - Saisie du nom/prénom
      // - Saisie de l'email
      // - Saisie du mot de passe
      // - Saisie du titre professionnel
      // - Saisie des compétences
      // - Saisie de la localisation
      // - Validation et soumission
    });

    testWidgets('après inscription, l\'utilisateur peut se connecter', (tester) async {
      final authService = AuthService();
      
      // Simuler une inscription via AuthService directement
      await authService.registerJobSeeker(
        email: 'test_e2e@example.com',
        password: 'Test123!',
        firstName: 'Test',
        lastName: 'User',
        professionalTitle: 'Développeur',
        skills: ['Flutter', 'Dart'],
      );
      
      // Déconnexion
      await authService.logout();
      
      // Tentative de connexion
      final loginResult = await authService.login('test_e2e@example.com', 'Test123!');
      
      expect(loginResult, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser!.email, 'test_e2e@example.com');
      expect(authService.currentUser!.role, 'job_seeker');
    });

    testWidgets('inscription avec données complètes', (tester) async {
      final authService = AuthService();
      
      await authService.registerJobSeeker(
        email: 'complete@example.com',
        password: 'Secure123!',
        firstName: 'Jean',
        lastName: 'Dupont',
        professionalTitle: 'Développeur Full Stack',
        skills: ['Flutter', 'Dart', 'Firebase', 'REST API'],
        location: 'Antananarivo',
        telephone: '0341234567',
        presentation: 'Développeur passionné avec 5 ans d\'expérience',
        dailyRate: '500000-800000 MGA',
        availability: 'Immédiate',
      );
      
      final user = authService.currentUser;
      expect(user, isNotNull);
      expect(user!.firstName, 'Jean');
      expect(user.lastName, 'Dupont');
      expect(user.position, 'Développeur Full Stack');
      expect(user.skills.length, 4);
      expect(user.localisation, 'Antananarivo');
      expect(user.telephone, '0341234567');
      expect(user.presentation, 'Développeur passionné avec 5 ans d\'expérience');
      expect(user.dailyRate, '500000-800000 MGA');
      expect(user.availability, 'Immédiate');
    });

    testWidgets('échec de l\'inscription avec email invalide', (tester) async {
      final authService = AuthService();
      
      expect(
        () => authService.registerJobSeeker(
          email: 'invalid-email',
          password: 'Test123!',
          firstName: 'Test',
          lastName: 'User',
          professionalTitle: 'Developer',
          skills: [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('échec de l\'inscription avec mot de passe faible', (tester) async {
      final authService = AuthService();
      
      expect(
        () => authService.registerJobSeeker(
          email: 'test@example.com',
          password: 'weak', // Trop court
          firstName: 'Test',
          lastName: 'User',
          professionalTitle: 'Developer',
          skills: [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('échec de l\'inscription avec email déjà utilisé', (tester) async {
      final authService = AuthService();
      
      await authService.registerJobSeeker(
        email: 'duplicate@example.com',
        password: 'Test123!',
        firstName: 'First',
        lastName: 'User',
        professionalTitle: 'Developer',
        skills: [],
      );
      
      await authService.logout();
      
      expect(
        () => authService.registerJobSeeker(
          email: 'duplicate@example.com', // Même email
          password: 'Test123!',
          firstName: 'Second',
          lastName: 'User',
          professionalTitle: 'Designer',
          skills: [],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
