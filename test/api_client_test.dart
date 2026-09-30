import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/api_config.dart';
import 'package:joem/core/network/token_storage.dart';

http.Response jsonResponse(Object body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('ApiClient', () {
    test('returns the envelope data and sends JSON with the bearer token', () async {
      late http.Request sent;
      final client = ApiClient(
        baseUrl: 'http://pc.local:8000/api/',
        tokenStorage: MemoryTokenStorage(),
        httpClient: MockClient((request) async {
          sent = request;
          return jsonResponse({'success': true, 'message': 'Profil mis à jour.', 'data': {'id': 7}}, 200);
        }),
      );
      await client.saveToken('jeton-123');

      final data = await client.patch('/profile', body: {'nom': 'Rakoto'});

      expect(data, {'id': 7});
      expect(sent.url.toString(), 'http://pc.local:8000/api/profile');
      expect(sent.headers['Authorization'], 'Bearer jeton-123');
      expect(sent.headers['Accept'], 'application/json');
      expect(jsonDecode(sent.body), {'nom': 'Rakoto'});
    });

    test('turns a 422 into field errors in French', () async {
      final client = ApiClient(
        baseUrl: 'http://pc.local:8000/api',
        tokenStorage: MemoryTokenStorage(),
        httpClient: MockClient((_) async => jsonResponse({
              'success': false,
              'message': 'Les données fournies sont invalides.',
              'errors': {
                'email': ['Cet e-mail est déjà utilisé, veuillez en choisir un autre.'],
              },
            }, 422)),
      );

      final error = await client.post('/auth/register', body: {}).then<ApiException?>((_) => null, onError: (Object e) => e as ApiException);

      expect(error!.isValidationError, isTrue);
      expect(error.firstErrorFor('email'), 'Cet e-mail est déjà utilisé, veuillez en choisir un autre.');
      expect(error.displayMessage, 'Cet e-mail est déjà utilisé, veuillez en choisir un autre.');
    });

    test('reports an unreachable server as a network error', () async {
      final client = ApiClient(
        baseUrl: 'http://pc.local:8000/api',
        tokenStorage: MemoryTokenStorage(),
        httpClient: MockClient((_) async => throw http.ClientException('Connection refused')),
      );

      expect(
        () => client.get('/auth/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', isTrue)
            .having((e) => e.message, 'message', contains('Impossible de joindre le serveur JOEM'))),
      );
    });

    test('a non JSON error page still gives a readable message', () async {
      final client = ApiClient(
        baseUrl: 'http://pc.local:8000/api',
        tokenStorage: MemoryTokenStorage(),
        httpClient: MockClient((_) async => http.Response('<html>Server Error</html>', 500)),
      );

      expect(
        () => client.get('/jobs'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Le serveur JOEM a rencontré une erreur. Réessayez plus tard.')),
      );
    });

    test('uploads a file as multipart field "file"', () async {
      late http.BaseRequest sent;
      String body = '';
      final client = ApiClient(
        baseUrl: 'http://pc.local:8000/api',
        tokenStorage: MemoryTokenStorage(),
        httpClient: MockClient((request) async {
          sent = request;
          body = request.body;
          return jsonResponse({'success': true, 'message': 'CV enregistré.', 'data': null}, 200);
        }),
      );

      await client.upload('/profile/cv', bytes: utf8.encode('%PDF-1.4'), filename: 'CV Miora.pdf');

      expect(sent.headers['content-type'], startsWith('multipart/form-data'));
      expect(body, contains('name="file"; filename="CV Miora.pdf"'));
    });

    test('clearing the token stops sending it', () async {
      final storage = MemoryTokenStorage();
      late http.Request sent;
      final client = ApiClient(
        baseUrl: 'http://pc.local:8000/api',
        tokenStorage: storage,
        httpClient: MockClient((request) async {
          sent = request;
          return jsonResponse({'success': true, 'message': 'ok', 'data': []}, 200);
        }),
      );
      await client.saveToken('jeton-123');

      await client.clearToken();
      await client.get('/categories');

      expect(await storage.read(), isNull);
      expect(sent.headers.containsKey('Authorization'), isFalse);
    });
  });

  test('role names are converted in both directions', () {
    expect(ApiRole.toApi('job_seeker'), 'candidate');
    expect(ApiRole.toApi('employer'), 'employer');
    expect(ApiRole.toLocal('candidate'), 'job_seeker');
    expect(ApiRole.toLocal('employer'), 'employer');
  });
}
