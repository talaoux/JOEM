import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/interview_repository.dart';
import 'package:joem/features/dashboard/presentation/pages/candidate_interview_detail_screen.dart';
import 'package:joem/features/dashboard/presentation/widgets/soft_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Le candidat doit savoir quelle entreprise lui propose un entretien.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  final logo = Uint8List.fromList([137, 80, 78, 71]);

  /// Ignore les erreurs réseau de google_fonts (voir `reject_dialog_test.dart`).
  Future<void> run(Future<void> Function() body) async {
    final otherErrors = <Object>[];
    final done = Completer<void>();
    runZonedGuarded(() async {
      try {
        await body();
        done.complete();
      } catch (error, stack) {
        done.completeError(error, stack);
      }
    }, (error, _) {
      if (!error.toString().contains('google_fonts') && !error.toString().contains('Failed to load font')) {
        otherErrors.add(error);
      }
    });
    await done.future;
    expect(otherErrors, isEmpty);
  }

  Interview interviewFrom(String? companyName, {Uint8List? companyLogo}) => Interview(
        id: 1,
        employerUserId: 7,
        jobSeekerUserId: '42',
        candidateName: 'Hery',
        offerTitle: 'Développeur Flutter',
        mode: InterviewMode.visio,
        status: InterviewStatus.scheduled,
        createdAt: DateTime(2026, 9, 29),
        companyName: companyName,
        companyLogo: companyLogo,
      );

  test('the candidate\'s interviews carry the company name and logo', () async {
    await AppDatabase.instance.resetDatabase();
    final db = await AppDatabase.instance.database;
    final employerId = await db.insert('users', {
      'email': 'rh@vohitra.test',
      'password_hash': 'x',
      'role': 'employer',
      'created_at': '2026-09-29',
    });
    await db.insert('employer_profiles', {
      'user_id': employerId,
      'nom': 'Randria',
      'prenom': 'Tiana',
      'nom_entreprise': 'Vohitra Tech',
      'logo': logo,
    });
    const repository = InterviewRepository();
    await repository.schedule(
      employerUserId: employerId,
      jobSeekerUserId: '42',
      candidateName: 'Hery',
      offerTitle: 'Développeur Flutter',
      mode: InterviewMode.visio,
    );

    final interview = (await repository.fetchNotificationsForJobSeeker('42')).single;

    expect(interview.companyName, 'Vohitra Tech');
    expect(interview.companyLogo, logo);
  });

  testWidgets('the interview page says who proposes it', (tester) async {
    await run(() async {
      await tester.pumpWidget(MaterialApp(home: CandidateInterviewDetailScreen(interview: interviewFrom('Vohitra Tech'))));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Proposé par'), findsOneWidget);
      expect(find.text('Vohitra Tech'), findsOneWidget);
      expect(find.byType(SoftAvatar), findsOneWidget);
    });
  });

  testWidgets('without a known company the page keeps its previous layout', (tester) async {
    await run(() async {
      await tester.pumpWidget(MaterialApp(home: CandidateInterviewDetailScreen(interview: interviewFrom(null))));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Proposé par'), findsNothing);
      expect(find.text('Pour le poste : Développeur Flutter'), findsOneWidget);
    });
  });
}
