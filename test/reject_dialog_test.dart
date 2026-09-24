import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';
import 'package:joem/features/dashboard/presentation/pages/candidate_application_detail_screen.dart';

/// Parcours de décision sur `CandidateApplicationDetailScreen` :
/// - "Rejeter" : régression du dialogue qui levait `'_dependents.isEmpty'`
///   (contrôleur du champ libéré pendant l'animation de fermeture) ;
/// - "Accepter" : oblige à planifier un entretien, dont la date peut rester
///   "à définir".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  /// google_fonts télécharge les polices en tâche de fond (réseau
  /// indisponible en test) et ses échecs remontent comme erreurs non
  /// gérées : on les absorbe dans une zone, comme `widget_test.dart`.
  /// Attention : dans une zone `runZonedGuarded`, une exception du corps
  /// (ex. `expect` qui échoue) part dans le gestionnaire et le `Future`
  /// renvoyé ne se termine jamais — le test semblerait bloqué au lieu
  /// d'échouer. D'où le `Completer`, qui fait remonter le vrai échec.
  Future<void> runIgnoringFontErrors(Future<void> Function() body) async {
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
      if (!error.toString().contains('google_fonts') &&
          !error.toString().contains('Failed to load font')) {
        otherErrors.add(error);
      }
    });
    await done.future;
    expect(otherErrors, isEmpty);
  }

  /// Crée une offre et la candidature d'un compte de démo (id négatif : pas
  /// de profil à charger).
  Future<JobApplicationNotification> createApplication(WidgetTester tester) async {
    late JobApplicationNotification application;
    await tester.runAsync(() async {
      await AppDatabase.instance.resetDatabase();
      const repository = JobOfferRepository();
      final offer = await repository.publish(
        employerUserId: 7,
        companyName: 'Tech Mada',
        title: 'Développeur Flutter',
        description: '',
        location: 'Antananarivo',
        salary: 'À négocier',
        contractType: 'CDI',
      );
      await repository.apply(jobOfferId: offer.id, jobSeekerUserId: '-1', candidateName: 'Hery');
      application = (await repository.fetchApplicationsForOffer(offer.id)).single;
    });
    return application;
  }

  /// Laisse avancer les vraies E/S SQLite (hors horloge simulée) jusqu'à
  /// ce que [finder] trouve quelque chose.
  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('rejecting with a message closes the dialog without error', (tester) async {
    final application = await createApplication(tester);
    await runIgnoringFontErrors(() async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppSurfaceColors.light]),
        home: CandidateApplicationDetailScreen(notification: application),
      ));
      await pumpUntilFound(tester, find.text('Rejeter'));

      await tester.tap(find.text('Rejeter'));
      await tester.pumpAndSettle();
      expect(find.text('Rejeter cette candidature ?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Nous avons retenu un autre profil.');
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Rejeter')));
      await pumpUntilFound(tester, find.text('Annuler le rejet'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Rejeter cette candidature ?'), findsNothing);
      expect(find.text('Annuler le rejet'), findsOneWidget);
      expect(find.textContaining('Nous avons retenu un autre profil.'), findsOneWidget);
    });
  });

  testWidgets('accepting requires planning an interview, whose date can stay undefined',
      (tester) async {
    final application = await createApplication(tester);
    // `ScheduleInterviewScreen` enregistre l'entretien au nom du recruteur
    // connecté : sans session, l'enregistrement est ignoré.
    await tester.runAsync(
      () => AuthService().login('employeur@gmail.com', 'employeur123@gmail.com'),
    );
    // Écran haut : le formulaire de planification tient sans défilement.
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await runIgnoringFontErrors(() async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppSurfaceColors.light]),
        home: CandidateApplicationDetailScreen(notification: application),
      ));
      await pumpUntilFound(tester, find.text('Accepter'));

      // "Accepter" ouvre la planification d'entretien, pas une simple popup.
      await tester.tap(find.text('Accepter'));
      await tester.pumpAndSettle();
      expect(find.text('Accepter la candidature'), findsOneWidget);

      // Sans date ni "à définir", l'enregistrement est refusé.
      await tester.tap(find.text('Accepter et planifier'));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez une date'), findsOneWidget);
      expect(find.text('Accepter la candidature'), findsOneWidget);

      // Date "à voir" + message au candidat.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez une date'), findsNothing);
      // Dernier champ du formulaire : "Message au candidat (facultatif)".
      await tester.enterText(find.byType(TextField).last, 'Bienvenue dans l’équipe !');
      await tester.tap(find.text('Accepter et planifier'));
      await pumpUntilFound(tester, find.textContaining('Candidature acceptée le'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Candidature acceptée le'), findsOneWidget);
      expect(find.textContaining('Bienvenue dans l’équipe !'), findsOneWidget);
      expect(find.text('Date à définir'), findsOneWidget);
      expect(find.text("Modifier l'entretien"), findsOneWidget);
    });
  });
}
