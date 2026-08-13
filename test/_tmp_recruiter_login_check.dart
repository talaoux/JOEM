import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/recruiter_registration/data/recruiter_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('joem_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  test('a registered recruiter can log back in', () async {
    await AppDatabase.instance.resetDatabase();

    const repo = RecruiterRepository();
    await repo.register(
      const RecruiterRegistrationData(
        email: 'test.recruteur@example.com',
        password: 'motdepasse123',
        nom: 'Rakoto',
        prenom: 'Hery',
        telephone: '+261340000000',
        localisation: 'Antananarivo',
        nomEntreprise: 'Test SARL',
        description: 'Une entreprise de test',
        logoBytes: null,
        categorieEntreprise: 'Informatique',
      ),
    );

    await AuthService().logout();
    final success = await AuthService().login('test.recruteur@example.com', 'motdepasse123');

    expect(success, isTrue);
    expect(AuthService().currentUser?.role, 'employer');
    expect(AuthService().currentUser?.companyName, 'Test SARL');
  });
}
