import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/navigation/app_route_observer.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';
import 'package:joem/features/dashboard/presentation/pages/job_seeker_dashboard.dart';

/// Accueil candidat : uniquement les offres (plus de bannière, de
/// "Catégories populaires" ni de conseil), 100 offres au maximum, et le
/// bouton "Voir plus d'offres" seulement au-delà de 100. Le conseil
/// ("Complétez votre profil"...) est dans le panneau latéral.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  Future<void> pumpHome(WidgetTester tester, {required int offerCount}) async {
    await tester.runAsync(() async {
      await AppDatabase.instance.resetDatabase();
      const repository = JobOfferRepository();
      for (var i = 0; i < offerCount; i++) {
        await repository.publish(
          employerUserId: 7,
          companyName: 'Tech Mada',
          title: 'Offre $i',
          description: '',
          location: 'Antananarivo',
          salary: 'À négocier',
          contractType: 'CDI',
        );
      }
      await AuthService().login('candidat@gmail.com', 'candidat123');
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppSurfaceColors.light]),
      navigatorObservers: [appRouteObserver],
      home: const JobSeekerDashboard(),
    ));
    for (var i = 0; i < 30 && find.text('Offre 0').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 2));
  }

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

  testWidgets('home shows only offers, without "Voir plus" under 100 offers', (tester) async {
    await run(() async {
      await pumpHome(tester, offerCount: 3);
      expect(tester.takeException(), isNull);
      expect(find.text('Offre 0'), findsOneWidget);
      expect(find.text('Offre 2'), findsOneWidget);
      expect(find.text("Voir plus d'offres"), findsNothing);
      expect(find.text('Trouvez votre prochain emploi'), findsNothing);
      expect(find.text('Catégories populaires'), findsNothing);
      // Le conseil n'est plus sur l'accueil mais dans le panneau latéral
      // (monté hors écran) : une seule occurrence, celle du panneau.
      expect(find.text('Complétez votre profil'), findsOneWidget);
    });
  });

  testWidgets('home caps at 100 offers and shows "Voir plus d\'offres" beyond', (tester) async {
    await run(() async {
      await pumpHome(tester, offerCount: 101);
      expect(tester.takeException(), isNull);
      // Offres les plus récentes en premier : "Offre 100" affichée, la plus
      // ancienne ("Offre 0") au-delà de la limite.
      expect(find.text('Offre 100'), findsOneWidget);
      expect(find.text('Offre 0'), findsNothing);
      expect(find.text("Voir plus d'offres"), findsOneWidget);
    });
  });
}
