import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/local_account_mirror.dart';
import 'package:joem/core/network/token_storage.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/job_seeker_registration/data/job_seeker_repository.dart';
import 'package:joem/features/recruiter_registration/data/recruiter_repository.dart';

/// Faux serveur `joem_api` : juste assez de `/auth/*` et `/profile` pour
/// suivre le contrat (enveloppe, codes, champs).
class FakeJoemServer {
  final Map<String, Map<String, dynamic>> accounts = {};
  final Map<String, String> tokens = {};
  final List<http.BaseRequest> requests = [];
  final Map<String, Object?> lastProfilePatch = {};

  /// Codes "mot de passe oublié" envoyés, par e-mail.
  final Map<String, String> resetCodes = {};
  bool reachable = true;
  int _nextId = 1;

  static final photoBytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);

  MockClient get client => MockClient((request) async {
        if (!reachable) throw http.ClientException('Connection refused');
        requests.add(request);
        return _handle(request);
      });

  Map<String, dynamic> account(String email) => accounts[email]!;

  http.Response _handle(http.Request request) {
    final path = request.url.path.replaceFirst('/api', '');
    final body = request.body.isEmpty || !(request.headers['content-type'] ?? '').contains('json')
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    final email = tokens[(request.headers['Authorization'] ?? '').replaceFirst('Bearer ', '')];

    if (request.url.path.startsWith('/storage/')) return http.Response.bytes(photoBytes, 200);

    switch ((request.method, path)) {
      case ('POST', '/auth/register'):
        // Jeton Google factice `google:<email>` : l'e-mail vient du jeton.
        final googleToken = body['google_id_token'] as String?;
        if (googleToken != null) {
          body['email'] = googleToken.replaceFirst('google:', '');
          body['password'] = 'aleatoire-$_nextId';
        }
        if (accounts.containsKey(body['email'])) {
          return _json(422, message: 'Les données fournies sont invalides.', errors: {
            'email': ['Cet e-mail est déjà utilisé, veuillez en choisir un autre.'],
          });
        }
        final id = _nextId++;
        final isCandidate = body['role'] == 'candidate';
        accounts[body['email'] as String] = {
          'id': id,
          'email': body['email'],
          'password': body['password'],
          'role': body['role'],
          'created_at': '2026-09-29T10:00:00.000000Z',
          'candidate_profile': isCandidate
              ? {
                  'nom': body['nom'],
                  'prenom': body['prenom'],
                  'titre_professionnel': body['titre_professionnel'],
                  'localisation': body['localisation'],
                  'profil_visible': true,
                  'mode_nuit': false,
                  'photo_url': null,
                }
              : null,
          'employer_profile': isCandidate
              ? null
              : {
                  'nom': body['nom'],
                  'prenom': body['prenom'],
                  'nom_entreprise': body['nom_entreprise'],
                  'categorie': body['categorie'],
                  'entreprise_visible': true,
                  'logo_url': null,
                },
          'skills': <Map<String, dynamic>>[],
          'work_modes': <Map<String, dynamic>>[],
        };
        return _json(201, data: {'user': _public(body['email'] as String), 'token': _issueToken(body['email'] as String)});
      case ('POST', '/auth/login'):
        final account = accounts[body['email']];
        if (account == null || account['password'] != body['password']) {
          return _json(422, message: 'Identifiants incorrects.', errors: {
            'email': ['Identifiants incorrects.'],
          });
        }
        return _json(200, data: {'user': _public(body['email'] as String), 'token': _issueToken(body['email'] as String)});
      case ('POST', '/auth/google'):
        final googleEmail = (body['id_token'] as String).replaceFirst('google:', '');
        if (!accounts.containsKey(googleEmail)) {
          return _json(404, message: "Aucun compte JOEM n'est associé à ce compte Google. Inscrivez-vous d'abord.");
        }
        return _json(200, data: {'user': _public(googleEmail), 'token': _issueToken(googleEmail)});
      case ('POST', '/auth/forgot-password'):
        if (accounts.containsKey(body['email'])) resetCodes[body['email'] as String] = '123456';
        return _json(200);
      case ('POST', '/auth/reset-password'):
        final resetEmail = body['email'] as String;
        if (resetCodes[resetEmail] != body['code']) {
          return _json(422, message: 'Les données fournies sont invalides.', errors: {
            'code': ['Code incorrect.'],
          });
        }
        resetCodes.remove(resetEmail);
        accounts[resetEmail]!['password'] = body['password'];
        tokens.removeWhere((_, owner) => owner == resetEmail);
        return _json(200);
      case ('POST', '/auth/logout'):
        tokens.removeWhere((_, owner) => owner == email);
        return _json(200);
    }

    if (email == null) return _json(401, message: 'Authentification requise.');

    switch ((request.method, path)) {
      case ('GET', '/profile'):
        return _json(200, data: _public(email));
      case ('PATCH', '/profile'):
        lastProfilePatch
          ..clear()
          ..addAll(body);
        final account = accounts[email]!;
        account['skills'] = [
          for (final skill in body['skills'] as List? ?? const []) Map<String, dynamic>.from(skill as Map),
        ];
        account['work_modes'] = [
          for (final mode in body['work_modes'] as List? ?? const []) {'work_mode': mode},
        ];
        (account['candidate_profile'] as Map<String, dynamic>)['tarif_journalier'] = body['tarif_journalier'];
        return _json(200, data: _public(email));
      case ('POST', '/profile/photo'):
        final account = accounts[email]!;
        final profileKey = account['role'] == 'candidate' ? 'candidate_profile' : 'employer_profile';
        final urlKey = account['role'] == 'candidate' ? 'photo_url' : 'logo_url';
        (account[profileKey] as Map<String, dynamic>)[urlKey] = 'http://pc.local:8000/storage/photos/${account['id']}.jpg';
        return _json(200, data: _public(email));
    }

    return _json(404, message: 'Route inconnue du faux serveur : ${request.method} $path');
  }

  String _issueToken(String email) {
    final token = 'jeton-${tokens.length + 1}';
    tokens[token] = email;
    return token;
  }

  Map<String, dynamic> _public(String email) => Map<String, dynamic>.from(accounts[email]!)..remove('password');

  http.Response _json(int status, {Object? data, String message = 'ok', Map<String, List<String>>? errors}) => http.Response.bytes(
        utf8.encode(jsonEncode({
          'success': status < 300,
          'message': message,
          'data': data,
          'errors': ?errors,
        })),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}

const _candidateRegistration = JobSeekerRegistrationData(
  email: 'miora@example.test',
  password: 'MotDePasse123',
  nom: 'Rakoto',
  prenom: 'Miora',
  telephone: '',
  localisation: 'Antananarivo',
  titreProfessionnel: 'Développeuse Flutter',
  presentation: '',
  photoBytes: null,
  skills: [(name: 'Flutter', rating: 0), (name: 'Laravel', rating: 4)],
  tarifJournalier: '150 000 Ar',
  disponibilite: null,
  workModes: ['teletravail', 'hybride'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakeJoemServer server;
  late MemoryTokenStorage tokenStorage;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('joem_api_auth');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.resetDatabase();
    server = FakeJoemServer();
    tokenStorage = MemoryTokenStorage();
    ApiClient.shared = ApiClient(baseUrl: 'http://pc.local:8000/api', httpClient: server.client, tokenStorage: tokenStorage);
  });

  tearDown(() async {
    server.reachable = true;
    if (AuthService().currentUser != null) await AuthService().logout();
    ApiClient.shared = null;
  });

  tearDownAll(() async {
    await AppDatabase.instance.resetDatabase();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Nouveau téléphone : base locale vide, aucun jeton.
  Future<void> switchToAnotherPhone() async {
    if (AuthService().currentUser != null) await AuthService().logout();
    await AppDatabase.instance.resetDatabase();
    tokenStorage = MemoryTokenStorage();
    ApiClient.shared = ApiClient(baseUrl: 'http://pc.local:8000/api', httpClient: server.client, tokenStorage: tokenStorage);
  }

  test('candidate registration creates the account on the server and mirrors it with the server id', () async {
    final result = await const JobSeekerRepository().register(_candidateRegistration);

    final serverId = server.account('miora@example.test')['id'] as int;
    expect(result.userId, serverId);
    expect(await tokenStorage.read(), isNotNull);
    expect(server.lastProfilePatch['skills'], [
      {'name': 'Flutter', 'rating': 1},
      {'name': 'Laravel', 'rating': 4},
    ], reason: 'une compétence sans étoile est envoyée avec la note minimale de l\'API');
    expect(server.lastProfilePatch['work_modes'], ['teletravail', 'hybride']);

    final db = await AppDatabase.instance.database;
    final users = await db.query('users', where: 'id = ?', whereArgs: [serverId]);
    expect(users.single['email'], 'miora@example.test');
    expect(users.single['password_hash'], LocalAccountMirror.serverAccountMarker);
    final profile = (await db.query('job_seeker_profiles', where: 'user_id = ?', whereArgs: [serverId])).single;
    expect(profile['titre_professionnel'], 'Développeuse Flutter');
    expect(profile['tarif_journalier'], '150 000 Ar');
    expect((await db.query('job_seeker_skills', where: 'user_id = ?', whereArgs: [serverId])).map((row) => row['name']), ['Flutter', 'Laravel']);
  });

  test('a duplicate e-mail is refused by the server and nothing is stored locally', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await switchToAnotherPhone();

    await expectLater(
      const JobSeekerRepository().register(_candidateRegistration),
      throwsA(isA<ApiException>().having((e) => e.firstErrorFor('email'), 'email error', 'Cet e-mail est déjà utilisé, veuillez en choisir un autre.')),
    );

    final db = await AppDatabase.instance.database;
    expect(await db.query('users'), isEmpty);
    expect(await tokenStorage.read(), isNull);
  });

  test('recruiter registration uploads the logo and keeps it locally', () async {
    final logo = Uint8List.fromList([1, 2, 3, 4]);

    final result = await const RecruiterRepository().register(RecruiterRegistrationData(
      email: 'rh@vohitra.test',
      password: 'MotDePasse123',
      nom: 'Randria',
      prenom: 'Tiana',
      telephone: '',
      localisation: 'Antananarivo',
      nomEntreprise: 'Vohitra Tech',
      description: '',
      logoBytes: logo,
      categorieEntreprise: 'Informatique',
    ));

    expect(server.requests.where((r) => r.url.path == '/api/profile/photo'), hasLength(1));
    final db = await AppDatabase.instance.database;
    final profile = (await db.query('employer_profiles', where: 'user_id = ?', whereArgs: [result.userId])).single;
    expect(profile['nom_entreprise'], 'Vohitra Tech');
    expect(profile['logo'], logo);
  });

  test('an account created on one phone logs in on another one', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    (server.account('miora@example.test')['candidate_profile'] as Map<String, dynamic>)['photo_url'] = 'http://pc.local:8000/storage/photos/1.jpg';
    await switchToAnotherPhone();

    final success = await AuthService().login('miora@example.test', 'MotDePasse123');

    expect(success, isTrue);
    final user = AuthService().currentUser!;
    expect(user.id, server.account('miora@example.test')['id'].toString());
    expect(user.role, 'job_seeker');
    expect(user.position, 'Développeuse Flutter');
    expect(user.skills, ['Flutter', 'Laravel']);
    expect(user.workModes, ['teletravail', 'hybride']);
    expect(user.photoBytes, FakeJoemServer.photoBytes, reason: 'la photo est téléchargée depuis photo_url');
  });

  test('wrong credentials return false without a session', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await switchToAnotherPhone();

    expect(await AuthService().login('miora@example.test', 'mauvais'), isFalse);
    expect(AuthService().currentUser, isNull);
    expect(await tokenStorage.read(), isNull);
  });

  test('demo accounts are disabled when the app talks to the server', () async {
    expect(await AuthService().login('candidat@gmail.com', 'candidat123'), isFalse);
  });

  test('startup restores the session from the saved token', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await AuthService().login('miora@example.test', 'MotDePasse123');
    await AuthService().logout();
    await AuthService().login('miora@example.test', 'MotDePasse123');
    await _restartApp(server, tokenStorage);

    expect(await AuthService().restoreSession(), isTrue);
    expect(AuthService().currentUser!.email, 'miora@example.test');
  });

  test('a revoked token ends the session at startup', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await AuthService().login('miora@example.test', 'MotDePasse123');
    await _restartApp(server, tokenStorage);
    server.tokens.clear();

    expect(await AuthService().restoreSession(), isFalse);
    expect(await tokenStorage.read(), isNull);
  });

  test('startup without network reopens the last account known on this phone', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await AuthService().login('miora@example.test', 'MotDePasse123');
    await _restartApp(server, tokenStorage);
    server.reachable = false;

    expect(await AuthService().restoreSession(), isTrue);
    expect(AuthService().currentUser!.email, 'miora@example.test');
  });

  test('profile edits made on this phone survive a restart', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await AuthService().login('miora@example.test', 'MotDePasse123');
    final id = int.parse(AuthService().currentUser!.id);
    final db = await AppDatabase.instance.database;
    await db.update('job_seeker_profiles', {'titre_professionnel': 'Lead Flutter'}, where: 'user_id = ?', whereArgs: [id]);
    await _restartApp(server, tokenStorage);

    await AuthService().restoreSession();

    expect(AuthService().currentUser!.position, 'Lead Flutter');
  });

  test('a local account occupying the server id is replaced by the server account', () async {
    final db = await AppDatabase.instance.database;
    await db.insert('users', {'id': 1, 'email': 'ancien@local.test', 'password_hash': 'x', 'role': 'employer', 'created_at': '2026-01-01'});

    final result = await const JobSeekerRepository().register(_candidateRegistration);

    expect(result.userId, 1);
    final users = await db.query('users');
    expect(users.map((row) => row['email']), ['miora@example.test']);
  });

  test('logout forgets the token even when the server is unreachable', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await AuthService().login('miora@example.test', 'MotDePasse123');
    server.reachable = false;

    await AuthService().logout();

    expect(AuthService().currentUser, isNull);
    expect(await tokenStorage.read(), isNull);
  });

  test('google registration sends the Google token instead of a password', () async {
    const data = JobSeekerRegistrationData(
      email: 'miora@gmail.com',
      password: 'google-oauth-1',
      googleIdToken: 'google:miora@gmail.com',
      nom: 'Rakoto',
      prenom: 'Miora',
      telephone: '',
      localisation: 'Antananarivo',
      titreProfessionnel: 'Développeuse Flutter',
      presentation: '',
      photoBytes: null,
      skills: [],
      tarifJournalier: '',
      disponibilite: null,
      workModes: [],
    );

    await const JobSeekerRepository().register(data);

    final registerRequest = server.requests.firstWhere((r) => r.url.path == '/api/auth/register') as http.Request;
    final sent = jsonDecode(registerRequest.body) as Map<String, dynamic>;
    expect(sent['google_id_token'], 'google:miora@gmail.com');
    expect(sent.containsKey('password'), isFalse);
    expect(server.accounts.containsKey('miora@gmail.com'), isTrue);
  });

  test('forgotten password: the emailed code sets a new password and signs out other phones', () async {
    await const JobSeekerRepository().register(_candidateRegistration);
    await AuthService().logout();

    await AuthService().requestPasswordResetCode(' miora@example.test ');
    await expectLater(
      AuthService().resetPasswordWithCode(email: 'miora@example.test', code: '000000', newPassword: 'NouveauMotDePasse1'),
      throwsA(isA<ApiException>().having((e) => e.firstErrorFor('code'), 'code error', 'Code incorrect.')),
    );
    await AuthService().resetPasswordWithCode(email: 'miora@example.test', code: '123456', newPassword: 'NouveauMotDePasse1');

    expect(await AuthService().login('miora@example.test', 'MotDePasse123'), isFalse);
    expect(await AuthService().login('miora@example.test', 'NouveauMotDePasse1'), isTrue);
  });

  test('forgotten password is not handled locally for server accounts', () async {
    expect(
      () => AuthService().resetPassword(email: 'miora@example.test', newPassword: 'NouveauMotDePasse1'),
      throwsA(isA<ApiException>()),
    );
  });
}

/// Simule un redémarrage de l'app : l'utilisateur en mémoire est oublié,
/// mais le jeton (stockage sécurisé) et la ligne `session` (SQLite) restent,
/// comme après avoir tué puis relancé l'application.
Future<void> _restartApp(FakeJoemServer server, MemoryTokenStorage storage) async {
  final token = await storage.read();
  final email = AuthService().currentUser!.email;

  server.reachable = false;
  await AuthService().logout();
  server.reachable = true;

  await storage.write(token!);
  final db = await AppDatabase.instance.database;
  await db.insert('session', {'id': 1, 'email': email});
  ApiClient.shared = ApiClient(baseUrl: 'http://pc.local:8000/api', httpClient: server.client, tokenStorage: storage);
}
