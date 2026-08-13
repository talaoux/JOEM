// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joem/main.dart';

void main() {
  testWidgets('Welcome screen loads', (WidgetTester tester) async {
    // SplashScreen consulte AppDatabase (via AuthService.restoreSession) au
    // démarrage pour restaurer une éventuelle session ouverte : sans ce mock,
    // `getApplicationSupportDirectory` (path_provider) n'a pas de handler en
    // test et l'ouverture de la base ne se termine jamais.
    final tempDir = Directory.systemTemp.createTempSync('joem_widget_test');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    // google_fonts tente de récupérer les polices sur le réseau (toujours
    // indisponible en test) en tâche de fond, sans jamais attendre/capturer
    // le résultat lui-même : la requête échoue de façon non gérée et fait
    // planter le test, sans rapport avec ce qu'on vérifie ici. On isole
    // l'exécution dans sa propre zone pour absorber ces erreurs.
    await runZonedGuarded(() async {
      // Build our app and let the splash screen redirect to the welcome screen.
      await tester.pumpWidget(const JOEMApp());
      await tester.pump(const Duration(milliseconds: 3000));
      // La redirection interroge la base SQLite (I/O réelle via FFI, hors
      // de l'horloge simulée des `pump`, et l'ouverture initiale peut
      // prendre plusieurs secondes) avant de naviguer : `runAsync` laisse
      // l'event loop réel tourner le temps qu'elle se termine.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 8)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify that the welcome screen loads with its key content.
      expect(find.text('Réussissez.'), findsOneWidget);
      expect(find.text('Je suis recruteur'), findsOneWidget);
      expect(find.text('Je cherche un emploi'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    }, (error, stack) {
      if (error.toString().toLowerCase().contains('font')) return;
      // ignore: only_throw_errors
      throw error;
    });
  });
}