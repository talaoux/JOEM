import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';

/// Le recruteur rejette une candidature reçue : le candidat reçoit une
/// notification "Candidature non retenue" (avec le message éventuel), ne
/// peut plus retirer sa candidature pour effacer le rejet, et le recruteur
/// peut annuler le rejet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  test('rejecting an application notifies the candidate and can be undone', () async {
    await AppDatabase.instance.resetDatabase();
    const repository = JobOfferRepository();
    const employerId = 7;
    const candidateId = '42';

    final offer = await repository.publish(
      employerUserId: employerId,
      companyName: 'Tech Mada',
      title: 'Développeur Flutter',
      description: '',
      location: 'Antananarivo',
      salary: 'À négocier',
      contractType: 'CDI',
      categories: ['Informatique'],
    );
    await repository.apply(jobOfferId: offer.id, jobSeekerUserId: candidateId, candidateName: 'Hery');

    var application = (await repository.fetchApplicationsForOffer(offer.id)).single;
    expect(application.isRejected, isFalse);
    expect((await repository.fetchApplicationStatus(offer.id, candidateId))?.status,
        ApplicationStatus.pending);
    expect(await repository.fetchDecisionNotificationsForJobSeeker(candidateId), isEmpty);

    // Rejet avec un message.
    await repository.rejectApplication(application.applicationId,
        message: '  Nous avons retenu un autre profil.  ');

    application = (await repository.fetchApplicationsForOffer(offer.id)).single;
    expect(application.isRejected, isTrue);
    expect(application.decisionMessage, 'Nous avons retenu un autre profil.');
    expect(application.decidedAt, isNotNull);
    final employerSide =
        (await repository.fetchApplicationNotificationsForEmployer(employerId)).single;
    expect(employerSide.isRejected, isTrue);
    // copyWith (utilisé pour marquer lu/non lu) conserve le statut.
    expect(employerSide.copyWith(isRead: true).isRejected, isTrue);

    final status = await repository.fetchApplicationStatus(offer.id, candidateId);
    expect(status?.status, ApplicationStatus.rejected);
    expect(status?.decisionMessage, 'Nous avons retenu un autre profil.');
    expect(await repository.fetchApplicationStatusesByOffer(candidateId), {offer.id: ApplicationStatus.rejected});

    // Notification côté candidat, non lue puis lue.
    final decisions = await repository.fetchDecisionNotificationsForJobSeeker(candidateId);
    expect(decisions.single.offer.title, 'Développeur Flutter');
    expect(decisions.single.isRead, isFalse);
    expect(await repository.countUnreadDecisionNotificationsForJobSeeker(candidateId), 1);
    await repository.markDecisionNotificationRead(decisions.single.applicationId);
    expect(await repository.countUnreadDecisionNotificationsForJobSeeker(candidateId), 0);

    // Le candidat ne peut pas retirer (puis renvoyer) une candidature rejetée.
    expect(
      await repository.withdrawApplication(jobOfferId: offer.id, jobSeekerUserId: candidateId),
      isFalse,
    );
    expect(await repository.hasApplied(offer.id, candidateId), isTrue);

    // Suppression de la notification par le candidat : le rejet reste.
    await repository.deleteDecisionNotification(decisions.single.applicationId);
    expect(await repository.fetchDecisionNotificationsForJobSeeker(candidateId), isEmpty);
    expect(await repository.fetchApplicationStatusesByOffer(candidateId), {offer.id: ApplicationStatus.rejected});

    // Le recruteur annule le rejet : tout revient à "en attente".
    await repository.restoreApplication(application.applicationId);
    application = (await repository.fetchApplicationsForOffer(offer.id)).single;
    expect(application.isRejected, isFalse);
    expect(application.decisionMessage, isNull);
    expect(await repository.fetchDecisionNotificationsForJobSeeker(candidateId), isEmpty);
    expect(await repository.fetchApplicationStatusesByOffer(candidateId), {offer.id: ApplicationStatus.pending});

    // Une candidature en attente peut de nouveau être retirée.
    expect(
      await repository.withdrawApplication(jobOfferId: offer.id, jobSeekerUserId: candidateId),
      isTrue,
    );
    expect(await repository.hasApplied(offer.id, candidateId), isFalse);
  });

  test('accepting an application notifies the candidate and blocks withdrawal', () async {
    await AppDatabase.instance.resetDatabase();
    const repository = JobOfferRepository();
    const candidateId = '42';

    final offer = await repository.publish(
      employerUserId: 7,
      companyName: 'Tech Mada',
      title: 'Développeur Flutter',
      description: '',
      location: 'Antananarivo',
      salary: 'À négocier',
      contractType: 'CDI',
    );
    await repository.apply(jobOfferId: offer.id, jobSeekerUserId: candidateId, candidateName: 'Hery');
    var application = (await repository.fetchApplicationsForOffer(offer.id)).single;

    await repository.acceptApplication(application.applicationId, message: 'Bienvenue !');

    application = (await repository.fetchApplicationsForOffer(offer.id)).single;
    expect(application.isAccepted, isTrue);
    expect(application.isRejected, isFalse);
    expect(application.decisionMessage, 'Bienvenue !');
    expect(application.copyWith(isRead: true).isAccepted, isTrue);

    final status = await repository.fetchApplicationStatus(offer.id, candidateId);
    expect(status?.status, ApplicationStatus.accepted);
    expect(await repository.fetchApplicationStatusesByOffer(candidateId),
        {offer.id: ApplicationStatus.accepted});

    final decision = (await repository.fetchDecisionNotificationsForJobSeeker(candidateId)).single;
    expect(decision.isAccepted, isTrue);
    expect(decision.title, 'Candidature acceptée');
    expect(decision.decisionMessage, 'Bienvenue !');
    expect(await repository.countUnreadDecisionNotificationsForJobSeeker(candidateId), 1);
    await repository.markAllDecisionNotificationsRead(candidateId);
    expect(await repository.countUnreadDecisionNotificationsForJobSeeker(candidateId), 0);

    // Une candidature acceptée ne peut pas non plus être retirée.
    expect(
      await repository.withdrawApplication(jobOfferId: offer.id, jobSeekerUserId: candidateId),
      isFalse,
    );

    // Changement d'avis : accepté -> rejeté remplace la décision, et la
    // notification repasse en non lue avec le nouveau libellé.
    await repository.rejectApplication(application.applicationId);
    final changed = (await repository.fetchDecisionNotificationsForJobSeeker(candidateId)).single;
    expect(changed.isAccepted, isFalse);
    expect(changed.title, 'Candidature non retenue');
    expect(changed.decisionMessage, isNull);
    expect(changed.isRead, isFalse);
  });
}
