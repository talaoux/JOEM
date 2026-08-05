import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hash à sens unique (SHA-256) utilisé pour stocker les mots de passe des
/// comptes créés localement — jamais le mot de passe en clair.
String hashPassword(String password) => sha256.convert(utf8.encode(password)).toString();