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

  test('an offer published by a recruiter is visible to every candidate, with a publish time', () async {
    await AppDatabase.instance.resetDatabase();

    const repo = JobOfferRepository();

    // Un recruteur publie une offre.
    final published = await repo.publish(
      employerUserId: 42,
      companyName: 'Tech Solutions',
      title: 'Comptable',
      description: 'Recherche comptable expérimenté.',
      location: 'Antananarivo',
      salary: '1 500 000 Ar',
      contractType: 'CDI',
    );

    expect(published.id, greaterThan(0));
    expect(published.publishedLabel, isNotEmpty);

    // N'importe quel chercheur d'emploi (peu importe le métier recherché)
    // doit voir cette offre dans le flux global.
    final allOffers = await repo.fetchAll();
    expect(allOffers, hasLength(1));
    expect(allOffers.first.title, 'Comptable');
    expect(allOffers.first.companyName, 'Tech Solutions');
    // Publiée à l'instant : doit afficher une heure de publication réelle.
    expect(allOffers.first.publishedLabel, isNot(contains('null')));

    // "Mes offres" côté recruteur reste filtré sur son propre compte.
    final ownOffers = await repo.fetchByEmployer(42);
    expect(ownOffers, hasLength(1));
    final otherEmployerOffers = await repo.fetchByEmployer(99);
    expect(otherEmployerOffers, isEmpty);
  });
}
