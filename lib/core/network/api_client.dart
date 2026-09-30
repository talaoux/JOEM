import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'token_storage.dart';

/// Erreur renvoyée par l'API (ou réseau injoignable), déjà traduite pour
/// l'utilisateur : `message` et `errors` sont en français (contrat §3).
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors = const {},
  });

  /// `null` quand le serveur n'a pas pu être joint (pas de réseau, PC
  /// éteint, mauvaise adresse, délai dépassé).
  final int? statusCode;
  final String message;

  /// Erreurs de validation (422) : `champ -> messages`.
  final Map<String, List<String>> errors;

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isValidationError => statusCode == 422;

  String? firstErrorFor(String field) {
    final messages = errors[field];
    return messages == null || messages.isEmpty ? null : messages.first;
  }

  /// Premier message de champ s'il y en a un, sinon le message général —
  /// à afficher tel quel dans un `SnackBar`.
  String get displayMessage {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $displayMessage';
}

/// Client HTTP de l'API JOEM : ajoute `Accept: application/json` et le
/// jeton `Bearer` à chaque requête, lit l'enveloppe
/// `{ success, message, data }` et renvoie `data`, ou lève
/// [ApiException].
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    this.timeout = const Duration(seconds: 20),
    this.getCacheDuration = const Duration(seconds: 3),
  })  : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _http = httpClient ?? http.Client(),
        tokenStorage = tokenStorage ?? const SecureTokenStorage();

  static ApiClient? _shared;

  /// Client partagé de l'application, ou `null` si `API_BASE_URL` n'a pas
  /// été fourni (mode 100% local).
  static ApiClient? get shared {
    if (_shared == null && ApiConfig.isEnabled) {
      _shared = ApiClient(baseUrl: ApiConfig.baseUrl);
    }
    return _shared;
  }

  /// Remplace le client partagé — tests uniquement (`null` = mode local).
  @visibleForTesting
  static set shared(ApiClient? client) => _shared = client;

  static const _networkErrorMessage =
      'Impossible de joindre le serveur JOEM. Vérifiez votre connexion et réessayez.';

  final String _baseUrl;
  final http.Client _http;
  final TokenStorage tokenStorage;
  final Duration timeout;

  /// Durée pendant laquelle une réponse `GET` est réutilisée telle quelle.
  ///
  /// Un même écran interroge souvent plusieurs fois la même route coup sur
  /// coup (`/notifications` pour la liste, puis pour chaque pastille de
  /// compteur...) : sur un serveur de développement qui traite une requête
  /// à la fois (`php artisan serve` sous Windows), ces appels en double
  /// s'additionnaient et rendaient l'ouverture des notifications très
  /// lente. Les requêtes identiques en cours sont aussi partagées. Toute
  /// requête d'écriture, un changement de jeton ou un changement signalé
  /// par `LiveUpdates` vide ce cache ([invalidateCache]).
  final Duration getCacheDuration;

  final Map<String, ({DateTime at, Future<dynamic> response})> _getCache = {};

  /// Oublie les réponses `GET` gardées en mémoire.
  void invalidateCache() => _getCache.clear();

  String? _token;
  bool _tokenLoaded = false;

  Future<String?> get token async {
    if (!_tokenLoaded) {
      _token = await tokenStorage.read();
      _tokenLoaded = true;
    }
    return _token;
  }

  Future<void> saveToken(String token) async {
    invalidateCache();
    _token = token;
    _tokenLoaded = true;
    await tokenStorage.write(token);
  }

  Future<void> clearToken() async {
    invalidateCache();
    _token = null;
    _tokenLoaded = true;
    await tokenStorage.delete();
  }

  /// [fresh] ignore le cache (voir [getCacheDuration]) — pour
  /// `GET /sync`, dont le rôle est justement de détecter les changements.
  Future<dynamic> get(String path, {Map<String, String>? query, bool fresh = false}) {
    if (fresh || getCacheDuration == Duration.zero) return _send('GET', path, query: query);

    final key = _uri(path, query).toString();
    final now = DateTime.now();
    final cached = _getCache[key];
    if (cached != null && now.difference(cached.at) < getCacheDuration) return cached.response;

    final response = _send('GET', path, query: query);
    _getCache[key] = (at: now, response: response);
    // Une erreur ne doit pas être resservie : on réessaiera au prochain appel.
    response.catchError((Object _) {
      if (identical(_getCache[key]?.response, response)) _getCache.remove(key);
      return null;
    });
    return response;
  }

  /// Toutes les lignes d'une liste paginée (contrat §4), page après page —
  /// les écrans actuels affichent des listes complètes.
  Future<List<Map<String, dynamic>>> getAllPages(String path, {Map<String, String>? query}) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final data = await get(path, query: {...?query, 'page': '$page'}) as Map<String, dynamic>;
      rows.addAll((data['data'] as List).cast<Map<String, dynamic>>());
      if ((data['current_page'] as int) >= (data['last_page'] as int)) return rows;
      page++;
    }
  }

  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<dynamic> delete(String path, {Object? body}) => _send('DELETE', path, body: body);

  /// Envoie un fichier en `multipart/form-data`, champ `file` (contrat §8).
  Future<dynamic> upload(String path, {required Uint8List bytes, required String filename}) async {
    invalidateCache();
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(await _headers(json: false))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    try {
      return await _run(() async => http.Response.fromStream(await _http.send(request).timeout(timeout)));
    } finally {
      invalidateCache();
    }
  }

  /// Télécharge un fichier servi par l'API (photo publique, CV protégé) —
  /// `null` si le serveur ne le fournit pas.
  Future<Uint8List?> downloadBytes(String url) async {
    try {
      final response = await _http.get(resolveServerUrl(url), headers: await _headers(json: false)).timeout(timeout);
      return response.statusCode == 200 ? response.bodyBytes : null;
    } on Exception catch (error) {
      debugPrint('ApiClient.downloadBytes($url) failed: $error');
      return null;
    }
  }

  /// Adresse d'un fichier servi par l'API, ramenée sur l'hôte de
  /// `API_BASE_URL`.
  ///
  /// Laravel construit les `*_url` des images à partir de son `APP_URL`
  /// (`.env`), qui peut ne pas être l'adresse par laquelle le téléphone
  /// joint le PC (IP qui a changé, `localhost`, accès depuis l'extérieur
  /// du réseau...). Chaque image partait alors vers une adresse
  /// injoignable et attendait le délai complet ([timeout]) avant d'échouer
  /// — puis réessayait au rechargement suivant. Les fichiers étant servis
  /// par le même serveur que l'API, on garde seulement leur chemin.
  Uri resolveServerUrl(String url) {
    final target = Uri.parse(url);
    final api = Uri.parse(_baseUrl);
    if (!target.hasScheme || target.host.isEmpty) {
      return api.resolve(url);
    }
    return target.replace(scheme: api.scheme, host: api.host, port: api.port);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({required bool json}) async {
    final bearer = await token;
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json; charset=utf-8',
      if (bearer != null) 'Authorization': 'Bearer $bearer',
    };
  }

  Future<dynamic> _send(String method, String path, {Map<String, String>? query, Object? body}) async {
    final isWrite = method != 'GET';
    if (isWrite) invalidateCache();
    final request = http.Request(method, _uri(path, query))..headers.addAll(await _headers(json: body != null));
    if (body != null) request.body = jsonEncode(body);

    try {
      return await _run(() async => http.Response.fromStream(await _http.send(request).timeout(timeout)));
    } finally {
      // Un GET lancé pendant l'écriture a pu lire l'état d'avant.
      if (isWrite) invalidateCache();
    }
  }

  Future<dynamic> _run(Future<http.Response> Function() send) async {
    final http.Response response;
    try {
      response = await send();
    } on SocketException {
      throw const ApiException(statusCode: null, message: _networkErrorMessage);
    } on TimeoutException {
      throw const ApiException(statusCode: null, message: _networkErrorMessage);
    } on http.ClientException {
      throw const ApiException(statusCode: null, message: _networkErrorMessage);
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) envelope = decoded;
    } on FormatException {
      envelope = null;
    }

    final succeeded = response.statusCode >= 200 && response.statusCode < 300;
    if (succeeded && envelope != null && envelope['success'] != false) {
      return envelope['data'];
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: envelope?['message'] as String? ?? _fallbackMessage(response.statusCode),
      errors: _parseErrors(envelope?['errors']),
    );
  }

  static Map<String, List<String>> _parseErrors(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): [
          if (entry.value is List)
            for (final message in entry.value as List) message.toString(),
        ],
    };
  }

  static String _fallbackMessage(int statusCode) => switch (statusCode) {
        401 => 'Votre session a expiré, veuillez vous reconnecter.',
        429 => 'Trop de tentatives. Réessayez dans une minute.',
        >= 500 => 'Le serveur JOEM a rencontré une erreur. Réessayez plus tard.',
        _ => 'Réponse inattendue du serveur JOEM.',
      };
}
