import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Images servies par l'API (`*_url`, contrat §8), téléchargées une fois
/// puis gardées en mémoire.
///
/// Les modèles et écrans actuels affichent des octets (`Uint8List`, venus
/// des BLOB SQLite) : les télécharger permet de brancher l'API sans toucher
/// aux widgets. Une URL change à chaque remplacement de fichier (nom généré
/// par le serveur), le cache ne sert donc jamais une image périmée.
abstract final class RemoteImages {
  static final Map<String, Future<Uint8List?>> _cache = {};

  /// `null` si [url] est vide, si l'API n'est pas branchée ou si le
  /// téléchargement échoue (réessayé au prochain appel).
  static Future<Uint8List?> load(Object? url) {
    final api = ApiClient.shared;
    if (url is! String || url.isEmpty || api == null) return Future.value(null);

    return _cache.putIfAbsent(url, () async {
      final bytes = await api.downloadBytes(url);
      if (bytes == null) _cache.remove(url);
      return bytes;
    });
  }

  @visibleForTesting
  static void clear() => _cache.clear();
}
