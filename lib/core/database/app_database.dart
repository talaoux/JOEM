import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

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
    String dbPath;
    if (kIsWeb) {
      // sqflite lui-même n'a pas d'implémentation web (canaux de plateforme
      // natifs uniquement) : sans ceci, `databaseFactory` reste jamais
      // initialisé et toute opération (inscription, connexion, publication
      // d'offre...) échoue avec "databaseFactory not initialized" — avalé
      // par les blocs `catch` génériques des écrans en "Une erreur est
      // survenue". La persistance web se fait via IndexedDB (sqlite3 en
      // WASM), pas de vrai chemin de fichier : un simple nom suffit. Voir
      // `dart run sqflite_common_ffi_web:setup` (télécharge `sqlite3.wasm`
      // et `sqflite_sw.js` dans `web/`, requis pour que ceci fonctionne).
      databaseFactory = databaseFactoryFfiWeb;
      dbPath = 'joem.db';
    } else {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final directory = await getApplicationSupportDirectory();
      dbPath = p.join(directory.path, 'joem.db');
    }

    return openDatabase(
      dbPath,
      version: 13,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2 : ajout de `employer_profiles` (inscription recruteur).
        // Sans cette migration, un `joem.db` créé avant son ajout n'a
        // jamais cette table (`onCreate` ne s'exécute qu'à la toute
        // première création du fichier) et l'inscription recruteur échoue
        // avec "no such table: employer_profiles".
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS employer_profiles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
              nom TEXT NOT NULL,
              prenom TEXT NOT NULL,
              telephone TEXT,
              localisation TEXT,
              nom_entreprise TEXT NOT NULL,
              description TEXT,
              logo BLOB
            )
          ''');
        }
        // v2 -> v3 : ajout de `job_offers` (offres réellement publiées par
        // les recruteurs, visibles par tous les candidats).
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_offers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              employer_user_id INTEGER NOT NULL,
              company_name TEXT NOT NULL,
              company_logo BLOB,
              title TEXT NOT NULL,
              description TEXT,
              location TEXT,
              salary TEXT,
              contract_type TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        // v3 -> v4 : ajout de `job_offer_notification_reads` — état
        // lu/supprimé, propre à chaque chercheur d'emploi, d'une offre
        // publiée. Les notifications elles-mêmes ne sont pas dupliquées :
        // elles sont dérivées de `job_offers` à la volée, cette table ne
        // stocke que l'écart par rapport à l'état "non lue" par défaut.
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_offer_notification_reads (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
              job_seeker_user_id TEXT NOT NULL,
              is_read INTEGER NOT NULL DEFAULT 0,
              is_deleted INTEGER NOT NULL DEFAULT 0,
              UNIQUE(job_offer_id, job_seeker_user_id)
            )
          ''');
        }
        // v4 -> v5 : ajout de `session` — retient l'email du dernier
        // utilisateur connecté pour restaurer sa session au redémarrage de
        // l'app (ex. retour matériel accidentel qui quitte l'app), voir
        // `AuthService.restoreSession`.
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS session (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              email TEXT NOT NULL
            )
          ''');
        }
        // v5 -> v6 : ajout de `job_applications` — une ligne par
        // candidature réelle, quand un chercheur d'emploi clique
        // "Postuler" sur une offre (`JobOfferRepository.apply`).
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_applications (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
              job_seeker_user_id TEXT NOT NULL,
              applied_at TEXT NOT NULL,
              UNIQUE(job_offer_id, job_seeker_user_id)
            )
          ''');
        }
        // v6 -> v7 : notification réelle côté recruteur quand un candidat
        // postule. `candidate_name`/`candidate_position` sont dupliqués sur
        // `job_applications` (pris au moment de la candidature) plutôt que
        // rejoints depuis un profil candidat — même raisonnement que
        // `job_offers.company_name` : les comptes de démo (id négatif)
        // n'ont aucune ligne dans `users`/`job_seeker_profiles` à joindre.
        // `job_application_notification_reads` retient l'état lu/supprimé
        // de chaque candidature, propre au recruteur qui la reçoit — un
        // seul recruteur étant concerné par candidature (contrairement à
        // `job_offer_notification_reads`, partagée par tous les candidats),
        // la clé unique porte directement sur `job_application_id`.
        if (oldVersion < 7) {
          // `ADD COLUMN` plutôt que `IF NOT EXISTS` (non supporté avant
          // SQLite 3.35 pour les colonnes) : on vérifie nous-mêmes via
          // `PRAGMA table_info` pour rester idempotent si cette migration a
          // déjà tourné une fois sur cet appareil (ex. version de la base
          // bougée plusieurs fois pendant le développement) — sans ce
          // garde-fou, un second passage lève "duplicate column name" et
          // fait échouer l'ouverture de la base pour toute l'app, pas
          // seulement pour les candidatures.
          final columns = await db.rawQuery('PRAGMA table_info(job_applications)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('candidate_name')) {
            await db.execute(
              "ALTER TABLE job_applications ADD COLUMN candidate_name TEXT NOT NULL DEFAULT ''",
            );
          }
          if (!columnNames.contains('candidate_position')) {
            await db.execute(
              'ALTER TABLE job_applications ADD COLUMN candidate_position TEXT',
            );
          }
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_application_notification_reads (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              job_application_id INTEGER NOT NULL UNIQUE REFERENCES job_applications(id) ON DELETE CASCADE,
              is_read INTEGER NOT NULL DEFAULT 0,
              is_deleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        // v7 -> v8 : affiche (image) optionnelle sur une offre, et
        // `job_offer_saves` — une offre "enregistrée" par un candidat
        // depuis la carte façon post (bouton "..." -> "Enregistrer
        // publication"), distinct de `job_offer_notification_reads` (qui ne
        // suit que lu/masqué, jamais un choix explicite de sauvegarde).
        if (oldVersion < 8) {
          final columns = await db.rawQuery('PRAGMA table_info(job_offers)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('poster_image')) {
            await db.execute('ALTER TABLE job_offers ADD COLUMN poster_image BLOB');
          }
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_offer_saves (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
              job_seeker_user_id TEXT NOT NULL,
              saved_at TEXT NOT NULL,
              UNIQUE(job_offer_id, job_seeker_user_id)
            )
          ''');
        }
        // v8 -> v9 : ajout de `job_seeker_experiences` — expériences
        // professionnelles réellement saisies par le candidat depuis
        // `JobProfileScreen` (l'inscription ne collecte aucune expérience,
        // seulement le titre professionnel courant).
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_seeker_experiences (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              poste TEXT NOT NULL,
              entreprise TEXT NOT NULL,
              date_debut TEXT NOT NULL,
              date_fin TEXT,
              en_cours INTEGER NOT NULL DEFAULT 0,
              description TEXT
            )
          ''');
        }
        // v9 -> v10 : le CV n'était qu'une case à cocher (`cv_picked`,
        // jamais de fichier réel) — `cv_bytes`/`cv_file_name` stockent
        // désormais le vrai fichier choisi (PDF ou image) depuis
        // l'inscription ou `JobProfileScreen`. `cv_picked` reste à jour
        // (dérivé de `cv_bytes`) pour ne pas casser les lignes déjà
        // écrites par du code plus ancien.
        if (oldVersion < 10) {
          final columns = await db.rawQuery('PRAGMA table_info(job_seeker_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('cv_bytes')) {
            await db.execute('ALTER TABLE job_seeker_profiles ADD COLUMN cv_bytes BLOB');
          }
          if (!columnNames.contains('cv_file_name')) {
            await db.execute('ALTER TABLE job_seeker_profiles ADD COLUMN cv_file_name TEXT');
          }
        }
        // v10 -> v11 : `cv_bytes` (BLOB en base) pouvait dépasser la limite
        // d'un `CursorWindow` Android (~2 Mo par ligne) dès qu'un CV un peu
        // lourd était choisi, faisant planter la connexion et la lecture
        // du profil avec "row too big to fit into CursorWindow". Le CV vit
        // désormais comme un vrai fichier sur le disque (voir
        // `lib/core/utils/cv_storage.dart`) ; `cv_path` retient juste son
        // chemin (texte, minuscule). `cv_bytes` reste en base, inutilisée,
        // plutôt que de tenter de la relire pour la migrer (ce qui
        // provoquerait le même crash pour les lignes déjà trop grosses).
        if (oldVersion < 11) {
          final columns = await db.rawQuery('PRAGMA table_info(job_seeker_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('cv_path')) {
            await db.execute('ALTER TABLE job_seeker_profiles ADD COLUMN cv_path TEXT');
          }
        }
        // v11 -> v12 : ajout de `search_history` — historique réel des
        // recherches de comptes (candidats côté recruteur, entreprises côté
        // candidat), propre à chaque utilisateur et type de recherche.
        // Remplace les listes mockées codées en dur dans `CandidateSearchScreen`
        // et `JobSearchScreen`. `user_id` en TEXT (pas de FK vers `users`) :
        // les comptes de démo (id négatif, voir `AuthService._demoAccounts`)
        // n'ont aucune ligne dans `users` mais doivent quand même pouvoir
        // avoir un historique de recherche, même raisonnement que
        // `job_offer_notification_reads.job_seeker_user_id`.
        if (oldVersion < 12) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS search_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              search_type TEXT NOT NULL,
              query TEXT NOT NULL,
              searched_at TEXT NOT NULL,
              UNIQUE(user_id, search_type, query)
            )
          ''');
        }
        // v12 -> v13 : ajout de `employer_profiles.categorie` — catégorie
        // d'entreprise choisie à l'inscription recruteur (`StepTwoPersonalInfo`,
        // champ obligatoire), réutilisée côté candidat pour filtrer les
        // offres par secteur (`JobCategoriesScreen`/grille "Catégories
        // populaires" du dashboard, voir `JobOfferRepository.fetchByCategory`).
        if (oldVersion < 13) {
          final columns = await db.rawQuery('PRAGMA table_info(employer_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('categorie')) {
            await db.execute('ALTER TABLE employer_profiles ADD COLUMN categorie TEXT');
          }
        }
      },
      onDowngrade: onDatabaseDowngradeDelete,
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
            cv_bytes BLOB,
            cv_file_name TEXT,
            cv_path TEXT,
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

        await db.execute('''
          CREATE TABLE employer_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
            nom TEXT NOT NULL,
            prenom TEXT NOT NULL,
            telephone TEXT,
            localisation TEXT,
            nom_entreprise TEXT NOT NULL,
            description TEXT,
            logo BLOB,
            categorie TEXT
          )
        ''');

        // Pas de FK vers `users` : les comptes de démo (`AuthService`) ne
        // sont jamais insérés dans `users`, mais peuvent quand même
        // publier des offres — le nom/logo de l'entreprise sont donc
        // dupliqués ici (pris au moment de la publication) plutôt que
        // rejoints depuis `employer_profiles`.
        await db.execute('''
          CREATE TABLE job_offers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employer_user_id INTEGER NOT NULL,
            company_name TEXT NOT NULL,
            company_logo BLOB,
            title TEXT NOT NULL,
            description TEXT,
            location TEXT,
            salary TEXT,
            contract_type TEXT,
            poster_image BLOB,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE job_offer_saves (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
            job_seeker_user_id TEXT NOT NULL,
            saved_at TEXT NOT NULL,
            UNIQUE(job_offer_id, job_seeker_user_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE job_offer_notification_reads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
            job_seeker_user_id TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            UNIQUE(job_offer_id, job_seeker_user_id)
          )
        ''');




        await db.execute('''
          CREATE TABLE session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            email TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE job_applications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
            job_seeker_user_id TEXT NOT NULL,
            candidate_name TEXT NOT NULL DEFAULT '',
            candidate_position TEXT,
            applied_at TEXT NOT NULL,
            UNIQUE(job_offer_id, job_seeker_user_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE job_application_notification_reads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_application_id INTEGER NOT NULL UNIQUE REFERENCES job_applications(id) ON DELETE CASCADE,
            is_read INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE job_seeker_experiences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            poste TEXT NOT NULL,
            entreprise TEXT NOT NULL,
            date_debut TEXT NOT NULL,
            date_fin TEXT,
            en_cours INTEGER NOT NULL DEFAULT 0,
            description TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            search_type TEXT NOT NULL,
            query TEXT NOT NULL,
            searched_at TEXT NOT NULL,
            UNIQUE(user_id, search_type, query)
          )
        ''');
      },
    );
  }
}
