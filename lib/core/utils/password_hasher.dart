import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Hachage des mots de passe des comptes créés localement — jamais le mot
/// de passe en clair.
///
/// Format stocké : `pbkdf2_sha256$<itérations>$<sel base64>$<hash base64>`
/// (PBKDF2-HMAC-SHA256, sel aléatoire de 16 octets propre à chaque compte).
/// Le sel empêche de retrouver d'un coup tous les comptes qui partagent un
/// même mot de passe, et les itérations rendent chaque essai coûteux pour
/// un attaquant. Les anciens hash SHA-256 simples (sans préfixe) restent
/// acceptés à la connexion puis sont remplacés ([needsRehash]).
///
/// Solution locale : avec un vrai backend, le hachage se fera côté serveur.
const String _scheme = 'pbkdf2_sha256';

/// Compromis sécurité/temps pour du Dart pur sur téléphone (~quelques
/// centaines de ms) ; calcul hors du fil d'interface via [compute].
const int _iterations = 100000;

/// Hache [password] avec un sel aléatoire neuf.
Future<String> hashPassword(String password) {
  final random = Random.secure();
  final salt = List<int>.generate(16, (_) => random.nextInt(256));
  return compute(_hashWithSalt, (password, salt, _iterations));
}

/// `true` si [password] correspond à [stored] (nouveau format ou ancien
/// SHA-256 simple).
Future<bool> verifyPassword(String password, String stored) async {
  if (!stored.startsWith('$_scheme\$')) {
    return _constantTimeEquals(
      sha256.convert(utf8.encode(password)).toString(),
      stored,
    );
  }
  final parts = stored.split('\$');
  if (parts.length != 4) return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null) return false;
  final salt = base64.decode(parts[2]);
  final recomputed = await compute(_hashWithSalt, (password, salt, iterations));
  return _constantTimeEquals(recomputed, stored);
}

/// `true` si [stored] est dans un ancien format (à re-hacher après une
/// connexion réussie).
bool needsRehash(String stored) => !stored.startsWith('$_scheme\$$_iterations\$');

String _hashWithSalt((String, List<int>, int) args) {
  final (password, salt, iterations) = args;
  final derived = _pbkdf2(utf8.encode(password), salt, iterations, 32);
  return '$_scheme\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
}

/// PBKDF2 (RFC 8018) avec HMAC-SHA256.
List<int> _pbkdf2(List<int> password, List<int> salt, int iterations, int length) {
  final hmac = Hmac(sha256, password);
  final blocks = (length / 32).ceil();
  final output = <int>[];
  for (var block = 1; block <= blocks; block++) {
    var u = hmac.convert([
      ...salt,
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ]).bytes;
    final t = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    output.addAll(t);
  }
  return output.sublist(0, length);
}

/// Comparaison en temps constant (ne révèle pas où les chaînes diffèrent).
bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
