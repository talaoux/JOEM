import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/constants/job_categories.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/features/dashboard/data/job_offer_repository.dart';

/// Une offre publiée avec plusieurs catégories apparaît dans chacune côté
/// candidat (`fetchByCategory`) ; une offre sans catégorie propre (publiée
/// avant la migration v28) retombe sur la catégorie de l'entreprise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  test('an offer is listed in every category it was published in', () async {
    await AppDatabase.instance.resetDatabase();
    final db = await AppDatabase.instance.database;
    const repository = JobOfferRepository();

    final employerId = await db.insert('users', {
      'email': 'rh@example.com',
      'password_hash': 'x',
      'role': 'employer',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('employer_profiles', {
      'user_id': employerId,
      'nom': 'Rabe',
      'prenom': 'Soa',
      'nom_entreprise': 'Tech Mada',
      'categorie': 'Informatique',
    });

    Future<JobOffer> publish(String title, List<String> categories) => repository.publish(
          employerUserId: employerId,
          companyName: 'Tech Mada',
          title: title,
          description: '',
          location: 'Antananarivo',
          salary: 'À négocier',
          contractType: 'CDI',
          categories: categories,
        );

    final multi = await publish('Développeur marketing digital', ['Informatique', 'Marketing']);
    final legacy = await publish('Ancienne offre', const []);
    await publish('Comptable', ['Finance']);

    Future<List<String>> titles(String category) async =>
        (await repository.fetchByCategory(category)).map((o) => o.title).toList();

    expect(await titles('Marketing'), ['Développeur marketing digital']);
    expect(
      await titles('Informatique'),
      unorderedEquals(['Développeur marketing digital', 'Ancienne offre']),
    );
    expect(await titles('Finance'), ['Comptable']);
    expect(await titles('Santé'), isEmpty);

    expect(await repository.fetchCategoriesForOffer(multi.id), ['Informatique', 'Marketing']);
    expect(await repository.fetchCategoriesForOffer(legacy.id), isEmpty);

    // Un entretien planifié sur l'offre garde une copie de son titre.
    await db.insert('interviews', {
      'employer_user_id': employerId,
      'job_offer_id': multi.id,
      'job_seeker_user_id': '42',
      'offer_title': multi.title,
      'scheduled_date': '2026-10-01',
      'scheduled_time': '10:00',
      'created_at': DateTime.now().toIso8601String(),
    });
    // Une candidature reçue doit survivre à la modification.
    await repository.apply(jobOfferId: multi.id, jobSeekerUserId: '42', candidateName: 'Hery');

    // Modification complète : tous les champs + catégories remplacées.
    final updated = await repository.updateOffer(
      offer: multi,
      title: 'Chef de projet digital',
      description: 'Nouvelle description',
      location: 'Toamasina',
      salary: '3 000 000 Ar',
      contractType: 'CDD',
      categories: ['Marketing', 'Communication'],
    );
    expect(updated.id, multi.id);
    expect(updated.createdAt, multi.createdAt);

    final stored = (await repository.fetchByEmployer(employerId)).firstWhere((o) => o.id == multi.id);
    expect(stored.title, 'Chef de projet digital');
    expect(stored.description, 'Nouvelle description');
    expect(stored.location, 'Toamasina');
    expect(stored.salary, '3 000 000 Ar');
    expect(stored.contractType, 'CDD');

    expect(await titles('Informatique'), ['Ancienne offre']);
    expect(await titles('Communication'), ['Chef de projet digital']);
    expect(await titles('Marketing'), ['Chef de projet digital']);
    expect(await repository.hasApplied(multi.id, '42'), isTrue);
    final interview = await db.query('interviews', where: 'job_offer_id = ?', whereArgs: [multi.id]);
    expect(interview.single['offer_title'], 'Chef de projet digital');

    // Une ancienne offre sans catégorie propre peut en recevoir, et ne
    // retombe alors plus sur la catégorie de l'entreprise.
    await repository.updateOffer(
      offer: legacy,
      title: legacy.title,
      description: legacy.description,
      location: legacy.location,
      salary: legacy.salary,
      contractType: legacy.contractType,
      categories: ['Tourisme'],
    );
    expect(await titles('Tourisme'), ['Ancienne offre']);
    expect(await titles('Informatique'), isEmpty);

    final byOffer = await repository.fetchCategoriesByOffer(employerId);
    expect(byOffer[multi.id], ['Marketing', 'Communication']);
    expect(byOffer[legacy.id], ['Tourisme']);

    // Supprimer l'offre supprime ses catégories (ON DELETE CASCADE).
    await repository.deleteOffer(multi.id);
    expect(await titles('Marketing'), isEmpty);
    expect(await db.query('job_offer_categories', where: 'job_offer_id = ?', whereArgs: [multi.id]),
        isEmpty);
  });

  test('an offer in "Autres" keeps the sector specified by the recruiter', () async {
    await AppDatabase.instance.resetDatabase();
    const repository = JobOfferRepository();

    final offer = await repository.publish(
      employerUserId: 7,
      companyName: 'Air Mada',
      title: 'Technicien avion',
      description: '',
      location: 'Ivato',
      salary: 'À négocier',
      contractType: 'CDI',
      categories: [kOtherJobCategory],
      otherSector: 'Aéronautique',
    );

    final inOther = await repository.fetchByCategory(kOtherJobCategory);
    expect(inOther.map((o) => o.title), ['Technicien avion']);
    expect(inOther.single.otherSector, 'Aéronautique');
    expect(offerCategoryLabel(kOtherJobCategory, inOther.single.otherSector), 'Autres · Aéronautique');
    expect(offerCategoryLabel('Transport', inOther.single.otherSector), 'Transport');

    // Sortie de "Autres" à la modification : le secteur précisé est effacé.
    await repository.updateOffer(
      offer: offer,
      title: offer.title,
      description: offer.description,
      location: offer.location,
      salary: offer.salary,
      contractType: offer.contractType,
      categories: ['Transport'],
    );
    expect(await repository.fetchByCategory(kOtherJobCategory), isEmpty);
    final inTransport = await repository.fetchByCategory('Transport');
    expect(inTransport.single.otherSector, isNull);
  });
}
