import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/features/dashboard/data/account_search_repository.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';
import 'package:joem/features/dashboard/presentation/pages/candidate_full_portfolio_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/change_password_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/edit_job_seeker_profile_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/job_categories_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/job_offer_detail_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/job_profile_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/job_seeker_settings_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/portfolio_about_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/portfolio_certifications_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/portfolio_experience_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/portfolio_projects_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/portfolio_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/portfolio_skills_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/profile_stats_screens.dart';

/// Fumée : chaque écran candidat s'ouvre et joue ses animations d'apparition
/// (sections en cascade, listes décalées) sans erreur de mise en page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  late JobOffer offer;

  setUpAll(() async {
    await AppDatabase.instance.resetDatabase();
    offer = await const JobOfferRepository().publish(
      employerUserId: 7,
      companyName: 'Tech Mada',
      title: 'Développeur Flutter',
      description: 'Une offre de test.',
      location: 'Antananarivo',
      salary: 'À négocier',
      contractType: 'CDI',
      categories: ['Informatique'],
    );
    await AuthService().login('candidat@gmail.com', 'candidat123');
  });

  final screens = <String, Widget Function()>{
    'JobOfferDetailScreen': () => JobOfferDetailScreen(offer: offer),
    'JobProfileScreen': () => const JobProfileScreen(),
    'EditJobSeekerProfileScreen': () => const EditJobSeekerProfileScreen(),
    'JobSeekerSettingsScreen': () => const JobSeekerSettingsScreen(),
    'ChangePasswordScreen': () => const ChangePasswordScreen(),
    'JobCategoriesScreen': () => const JobCategoriesScreen(),
    'PortfolioScreen': () => const PortfolioScreen(),
    'PortfolioAboutScreen': () => const PortfolioAboutScreen(),
    'PortfolioSkillsScreen': () => const PortfolioSkillsScreen(),
    'PortfolioExperienceScreen': () => const PortfolioExperienceScreen(),
    'PortfolioProjectsScreen': () => const PortfolioProjectsScreen(),
    'PortfolioCertificationsScreen': () => const PortfolioCertificationsScreen(),
    'CandidateFullPortfolioScreen': () => CandidateFullPortfolioScreen(
          candidate: CandidateSearchResult.fromUser(AuthService().currentUser!),
        ),
    'MyApplicationsScreen': () => const MyApplicationsScreen(),
    'MyInterviewsScreen': () => const MyInterviewsScreen(),
    'MySavedOffersScreen': () => const MySavedOffersScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} opens and animates without error', (tester) async {
      final otherErrors = <Object>[];
      final done = Completer<void>();
      // google_fonts : erreurs réseau en tâche de fond ignorées (voir
      // `reject_dialog_test.dart`) ; toute autre erreur fait échouer.
      runZonedGuarded(() async {
        try {
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(extensions: const [AppSurfaceColors.light]),
            home: entry.value(),
          ));
          for (var i = 0; i < 10; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
            await tester.pump(const Duration(milliseconds: 100));
          }
          // Laisse finir toutes les apparitions (délais de cascade compris).
          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull);
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
    });
  }
}
