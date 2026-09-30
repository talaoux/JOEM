import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/core/widgets/step_one_account.dart';
import 'package:joem/features/job_seeker_registration/data/job_seeker_repository.dart';
import 'package:joem/features/job_seeker_registration/presentation/job_seeker_registration_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_e2e_registration');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
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

  testWidgets('registration wizard opens at its account step', (tester) async {
    final unexpectedErrors = <Object>[];
    final done = Completer<void>();
    runZonedGuarded(
      () async {
        try {
          await tester.pumpWidget(
            const MaterialApp(home: JobSeekerRegistrationScreen()),
          );
          await tester.pumpAndSettle();

          // Le titre texte a été remplacé par le logo JOEM lors de la
          // refonte du design : l'en-tête se vérifie par le logo.
          expect(find.byType(JoemGradientLogo), findsOneWidget);
          expect(find.byType(StepOneAccount), findsOneWidget);
          expect(find.text('Compte'), findsOneWidget);
          done.complete();
        } catch (error, stack) {
          done.completeError(error, stack);
        }
      },
      (error, _) {
        if (!error.toString().contains('google_fonts') &&
            !error.toString().contains('Failed to load font')) {
          unexpectedErrors.add(error);
        }
      },
    );
    await done.future;
    expect(unexpectedErrors, isEmpty);
  });

  test('registered candidate data can be loaded by login', () async {
    const repository = JobSeekerRepository();
    await repository.register(
      const JobSeekerRegistrationData(
        email: 'complete@example.com',
        password: 'Secure123!',
        nom: 'Dupont',
        prenom: 'Jean',
        telephone: '0341234567',
        localisation: 'Antananarivo',
        titreProfessionnel: 'Développeur Full Stack',
        presentation: 'Développeur passionné.',
        photoBytes: null,
        skills: [(name: 'Flutter', rating: 4), (name: 'Dart', rating: 5)],
        tarifJournalier: '500000-800000 MGA',
        disponibilite: 'Immédiate',
        workModes: ['Remote'],
      ),
    );

    final authService = AuthService();
    expect(
      await authService.login('complete@example.com', 'Secure123!'),
      isTrue,
    );
    final user = authService.currentUser!;
    expect(user.firstName, 'Jean');
    expect(user.lastName, 'Dupont');
    expect(user.position, 'Développeur Full Stack');
    expect(user.skills, ['Flutter', 'Dart']);
    expect(user.localisation, 'Antananarivo');
    expect(user.telephone, '0341234567');
    expect(user.presentation, 'Développeur passionné.');
    expect(user.tarifJournalier, '500000-800000 MGA');
    expect(user.disponibilite, 'Immédiate');
    expect(user.workModes, ['Remote']);
    await authService.logout();
  });

  test('repository rejects registering the same email twice', () async {
    const repository = JobSeekerRepository();
    const data = JobSeekerRegistrationData(
      email: 'duplicate@example.com',
      password: 'Secure123!',
      nom: 'User',
      prenom: 'First',
      telephone: '',
      localisation: '',
      titreProfessionnel: 'Developer',
      presentation: '',
      photoBytes: null,
      skills: [],
      tarifJournalier: '',
      disponibilite: null,
      workModes: [],
    );

    await repository.register(data);
    await expectLater(
      repository.register(data),
      throwsA(isA<EmailAlreadyUsedException>()),
    );
  });
}
