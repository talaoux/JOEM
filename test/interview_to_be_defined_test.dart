import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/interview_repository.dart';

/// Un entretien peut être planifié avec une date "à définir" (proposé à
/// l'acceptation d'une candidature), puis recevoir sa date plus tard.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  test('an interview with an undefined date is upcoming, sorted last, then gets a date', () async {
    await AppDatabase.instance.resetDatabase();
    const repository = InterviewRepository();
    const employerId = 7;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dated = await repository.schedule(
      employerUserId: employerId,
      jobSeekerUserId: '41',
      candidateName: 'Soa',
      offerTitle: 'Comptable',
      date: tomorrow,
      time: '10:00',
      mode: InterviewMode.presentiel,
    );
    final undefined = await repository.schedule(
      employerUserId: employerId,
      jobApplicationId: 99,
      jobSeekerUserId: '42',
      candidateName: 'Hery',
      offerTitle: 'Développeur Flutter',
      mode: InterviewMode.visio,
    );

    expect(undefined.isDateToBeDefined, isTrue);
    final stored = (await repository.fetchByApplication(99))!;
    expect(stored.isDateToBeDefined, isTrue);
    expect(stored.time, isNull);
    expect(stored.scheduledDateTime, isNull);
    expect(stored.dateLabel, 'Date à définir');
    expect(stored.whenLabel, 'Date à définir');

    // À venir (reste à organiser), après les entretiens datés ; jamais "du jour".
    final upcoming = await repository.fetchUpcomingForEmployer(employerId);
    expect(upcoming.map((i) => i.id), [dated.id, undefined.id]);
    expect(await repository.countUpcomingForEmployer(employerId), 2);
    expect(await repository.fetchTodayForEmployer(employerId), isEmpty);

    // Côté candidat, c'est bien une notification non lue.
    expect(await repository.countUnreadNotificationsForJobSeeker('42'), 1);
    await repository.markSeekerNotificationRead(undefined.id);

    // Le recruteur fixe la date : "Entretien modifié", de nouveau non lu.
    await repository.update(
      id: undefined.id,
      date: tomorrow,
      time: '14:30',
      mode: InterviewMode.visio,
    );
    final updated = (await repository.fetchByApplication(99))!;
    expect(updated.isDateToBeDefined, isFalse);
    expect(updated.timeLabel, '14:30');
    expect(updated.isModified, isTrue);
    expect(updated.seekerRead, isFalse);
    expect(updated.whenLabel, '${updated.dateLabel} · 14:30');
  });
}
