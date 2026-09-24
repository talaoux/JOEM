import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/account_search_repository.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';

/// Un candidat réellement inscrit postule : le recruteur reçoit la
/// notification ET peut charger le portfolio complet du candidat depuis
/// "Candidature reçue" (`AccountSearchRepository.fetchJobSeekerById`),
/// même si le candidat a masqué son profil de la recherche.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  test('application notifies the employer and exposes the candidate portfolio', () async {
    await AppDatabase.instance.resetDatabase();
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    // Candidat inscrit, profil MASQUÉ de la recherche, avec un portfolio.
    final candidateId = await db.insert('users', {
      'email': 'hery@example.com',
      'password_hash': 'x',
      'role': 'job_seeker',
      'created_at': now,
    });
    await db.insert('job_seeker_profiles', {
      'user_id': candidateId,
      'nom': 'Rakoto',
      'prenom': 'Hery',
      'titre_professionnel': 'Développeur Flutter',
      'presentation': 'Passionné de mobile.',
      'profil_visible': 0,
    });
    await db.insert('job_seeker_skills', {'user_id': candidateId, 'name': 'Flutter', 'rating': 4});
    await db.insert('job_seeker_portfolio_projects', {
      'user_id': candidateId,
      'title': 'Appli de livraison',
      'description': 'Suivi de colis en temps réel.',
      'created_at': now,
    });
    await db.insert('job_seeker_formations', {
      'user_id': candidateId,
      'etablissement': 'Université d\'Antananarivo',
      'date_debut': '2018',
    });

    const offers = JobOfferRepository();
    const accounts = AccountSearchRepository();

    final offer = await offers.publish(
      employerUserId: 42,
      companyName: 'Tech Solutions',
      title: 'Développeur Flutter',
      description: 'CDI à Antananarivo.',
      location: 'Antananarivo',
      salary: '2 000 000 Ar',
      contractType: 'CDI',
    );

    await offers.apply(
      jobOfferId: offer.id,
      jobSeekerUserId: candidateId.toString(),
      candidateName: 'Hery Rakoto',
      candidatePosition: 'Développeur Flutter',
    );

    // 1. Le recruteur reçoit la notification.
    expect(await offers.countUnreadApplicationNotificationsForEmployer(42), 1);
    final notification = (await offers.fetchApplicationNotificationsForEmployer(42)).single;
    expect(notification.jobSeekerUserId, candidateId.toString());

    // 2. Le profil masqué n'apparaît pas dans la recherche...
    expect(await accounts.searchJobSeekers('Hery'), isEmpty);

    // 3. ...mais son portfolio est accessible depuis la candidature.
    final candidate = await accounts.fetchJobSeekerById(notification.jobSeekerUserId);
    expect(candidate, isNotNull);
    expect(candidate!.fullName, contains('Hery'));
    expect(candidate.portfolioProjects.single.title, 'Appli de livraison');
    expect(candidate.formations, hasLength(1));
    expect(candidate.skills, ['Flutter']);

    // Compte de démo (id négatif, aucune ligne `users`) : pas de portfolio.
    expect(await accounts.fetchJobSeekerById('-2'), isNull);
  });
}
