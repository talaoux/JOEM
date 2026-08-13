import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  test('a candidate applying creates a real notification + counter for the employer', () async {
    await AppDatabase.instance.resetDatabase();

    const repo = JobOfferRepository();

    final offer = await repo.publish(
      employerUserId: 42,
      companyName: 'Tech Solutions',
      title: 'Développeur Flutter',
      description: 'Recherche développeur Flutter.',
      location: 'Antananarivo',
      salary: '2 000 000 Ar',
      contractType: 'CDI',
    );

    // Aucune notification tant que personne n'a postulé.
    expect(await repo.countUnreadApplicationNotificationsForEmployer(42), 0);

    await repo.apply(
      jobOfferId: offer.id,
      jobSeekerUserId: '-2',
      candidateName: 'Marie Martin',
      candidatePosition: 'Développeuse Flutter',
    );

    // Le recruteur voit une notification non lue.
    expect(await repo.countUnreadApplicationNotificationsForEmployer(42), 1);
    final notifications = await repo.fetchApplicationNotificationsForEmployer(42);
    expect(notifications, hasLength(1));
    expect(notifications.first.candidateName, 'Marie Martin');
    expect(notifications.first.jobSeekerUserId, '-2');
    expect(notifications.first.message, contains('Marie Martin'));
    expect(notifications.first.message, contains('Développeur Flutter'));
    expect(notifications.first.isRead, isFalse);

    // Compte de démo (id négatif) : pas de profil complet à joindre.
    expect(await repo.fetchJobSeekerProfileSummary('-2'), isNull);

    // Un autre recruteur ne voit rien.
    expect(await repo.fetchApplicationNotificationsForEmployer(99), isEmpty);

    // Marquer comme lue fait redescendre le compteur.
    await repo.markApplicationNotificationRead(notifications.first.applicationId);
    expect(await repo.countUnreadApplicationNotificationsForEmployer(42), 0);

    // Supprimer la notification la retire de la liste, sans supprimer la candidature.
    await repo.deleteApplicationNotification(notifications.first.applicationId);
    expect(await repo.fetchApplicationNotificationsForEmployer(42), isEmpty);
    expect(await repo.countApplicantsForEmployer(42), 1);
  });
}
