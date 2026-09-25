import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/utils/password_hasher.dart';

void main() {
  test('hash salé : vérifie le bon mot de passe, refuse le mauvais', () async {
    final a = await hashPassword('Secret123!');
    final b = await hashPassword('Secret123!');
    expect(a, startsWith('pbkdf2_sha256\$'));
    // Sel aléatoire : deux hash du même mot de passe diffèrent.
    expect(a, isNot(b));
    expect(await verifyPassword('Secret123!', a), isTrue);
    expect(await verifyPassword('secret123!', a), isFalse);
    expect(needsRehash(a), isFalse);
  });

  test('ancien hash SHA-256 sans sel : encore accepté, à re-hacher', () async {
    final legacy = sha256.convert(utf8.encode('ancien')).toString();
    expect(await verifyPassword('ancien', legacy), isTrue);
    expect(await verifyPassword('autre', legacy), isFalse);
    expect(needsRehash(legacy), isTrue);
  });
}
