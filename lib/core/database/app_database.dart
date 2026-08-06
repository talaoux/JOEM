import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Base SQLite locale de l'application (mock de backend — voir
/// CLAUDE.md, "Deux implémentations parallèles"). Un seul fichier
/// `joem.db`, ouvert paresseusement et partagé par tous les repositories.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  /// Supprime entièrement le fichier `joem.db` (tous les comptes/données
  /// créés via les wizards d'inscription) — utilisé par le bouton de
  /// debug "Réinitialiser les comptes de test". Les tables sont
  /// recréées vides à la prochaine ouverture (`onCreate`).
  Future<void> resetDatabase() async {
    final db = await database;
    final dbPath = db.path;
    await db.close();
    _db = null;
    await deleteDatabase(dbPath);
  }

  Future<Database> _open() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationSupportDirectory();
    final dbPath = p.join(directory.path, 'joem.db');

    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE job_seeker_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
            nom TEXT NOT NULL,
            prenom TEXT NOT NULL,
            telephone TEXT,
            localisation TEXT,
            titre_professionnel TEXT NOT NULL,
            presentation TEXT,
            photo BLOB,
            cv_picked INTEGER NOT NULL DEFAULT 0,
            tarif_journalier TEXT,
            disponibilite TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE job_seeker_skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            rating INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE job_seeker_work_modes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            work_mode TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
