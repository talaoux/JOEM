import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/features/job_seeker_registration/presentation/job_seeker_registration_screen.dart';
import 'package:joem/features/login/presentation/forgot_password_screen.dart';
import 'package:joem/features/login/presentation/login_screen.dart';
import 'package:joem/features/recruiter_registration/presentation/recruiter_registration_screen.dart';

/// Fumée : connexion, mot de passe oublié et les deux wizards d'inscription
/// s'ouvrent et jouent leurs animations d'apparition sans erreur de mise en
/// page (l'accueil est couvert par `widget_test.dart`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

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
      if (!error.toString().contains('google_fonts') &&
          !error.toString().contains('Failed to load font')) {
        otherErrors.add(error);
      }
    });
    await done.future;
    expect(otherErrors, isEmpty);
  }

  final screens = <String, Widget Function()>{
    'LoginScreen': () => const LoginScreen(),
    'ForgotPasswordScreen': () => const ForgotPasswordScreen(),
    'RecruiterRegistrationScreen': () => const RecruiterRegistrationScreen(),
    'JobSeekerRegistrationScreen': () => const JobSeekerRegistrationScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} opens and animates without error', (tester) async {
      await run(() async {
        await tester.pumpWidget(MaterialApp(home: entry.value()));
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('login "remember me" checkbox animates without error', (tester) async {
    await run(() async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.tap(find.text('Se souvenir de moi'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Se souvenir de moi'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });
}
