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
      version: 24,
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
        // v13 -> v14 : ajout de `cover_photo` sur `job_seeker_profiles` et
        // `employer_profiles` — la bannière de `JobProfileScreen`/
        // `EmployerProfileScreen` ne vivait qu'en mémoire (`Uint8List` local
        // à l'écran, perdue à sa fermeture) ; elle est désormais persistée
        // comme la photo/le logo (voir `AuthService.updateCoverPhoto`).
        if (oldVersion < 14) {
          final jobSeekerColumns = await db.rawQuery('PRAGMA table_info(job_seeker_profiles)');
          final jobSeekerColumnNames = jobSeekerColumns.map((c) => c['name'] as String).toSet();
          if (!jobSeekerColumnNames.contains('cover_photo')) {
            await db.execute('ALTER TABLE job_seeker_profiles ADD COLUMN cover_photo BLOB');
          }
          final employerColumns = await db.rawQuery('PRAGMA table_info(employer_profiles)');
          final employerColumnNames = employerColumns.map((c) => c['name'] as String).toSet();
          if (!employerColumnNames.contains('cover_photo')) {
            await db.execute('ALTER TABLE employer_profiles ADD COLUMN cover_photo BLOB');
          }
        }
        // v14 -> v15 : ajout de `job_seeker_profiles.profil_visible` — le
        // réglage "Confidentialité" de `JobSeekerSettingsScreen` permet à un
        // candidat de se retirer des résultats de `AccountSearchRepository
        // .searchJobSeekers` (recherche recruteur + "Candidats suggérés")
        // sans supprimer son compte. `DEFAULT 1` : un profil existant reste
        // visible tant que l'utilisateur n'a rien changé.
        if (oldVersion < 15) {
          final columns = await db.rawQuery('PRAGMA table_info(job_seeker_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('profil_visible')) {
            await db.execute(
              'ALTER TABLE job_seeker_profiles ADD COLUMN profil_visible INTEGER NOT NULL DEFAULT 1',
            );
          }
        }
        // v15 -> v16 : ajout des réglages "Notifications" et
        // "Confidentialité" (publicité) de `JobSeekerSettingsScreen` —
        // `notifications_actives` gate la pastille de compteur de nouvelles
        // offres (voir `AuthService.updateNotificationsEnabled`) ;
        // `publicite_personnalisee`/`communications_marketing` sont deux
        // consentements enregistrés dès maintenant (voir doc de
        // `User.adsPersonalized`/`User.marketingOptIn`) bien que JOEM ne
        // diffuse aujourd'hui ni publicité ni communication marketing.
        // `communications_marketing` démarre à 0 : un consentement marketing
        // ne doit jamais être présumé acquis.
        if (oldVersion < 16) {
          final columns = await db.rawQuery('PRAGMA table_info(job_seeker_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('notifications_actives')) {
            await db.execute(
              'ALTER TABLE job_seeker_profiles ADD COLUMN notifications_actives INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (!columnNames.contains('publicite_personnalisee')) {
            await db.execute(
              'ALTER TABLE job_seeker_profiles ADD COLUMN publicite_personnalisee INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (!columnNames.contains('communications_marketing')) {
            await db.execute(
              'ALTER TABLE job_seeker_profiles ADD COLUMN communications_marketing INTEGER NOT NULL DEFAULT 0',
            );
          }
        }
        // v16 -> v17 : ajout de la section "Affichage" de
        // `JobSeekerSettingsScreen` — `mode_nuit` (voir `AppSurfaceColors`/
        // `DisplayPreferencesController`), `texte_agrandi` (facteur
        // d'échelle appliqué au `MediaQuery.textScaler` global dans
        // `main.dart`) et `animations_reduites` (raccourcit les animations
        // d'apparition de `JobSeekerDashboard`/`ProfileSidePanel`).
        if (oldVersion < 17) {
          final columns = await db.rawQuery('PRAGMA table_info(job_seeker_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('mode_nuit')) {
            await db.execute(
              'ALTER TABLE job_seeker_profiles ADD COLUMN mode_nuit INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!columnNames.contains('texte_agrandi')) {
            await db.execute(
              'ALTER TABLE job_seeker_profiles ADD COLUMN texte_agrandi INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!columnNames.contains('animations_reduites')) {
            await db.execute(
              'ALTER TABLE job_seeker_profiles ADD COLUMN animations_reduites INTEGER NOT NULL DEFAULT 0',
            );
          }
        }
        // v17 -> v18 : ajout de `job_offer_views` — une ligne par candidat
        // qui ouvre le détail d'une offre (`JobOfferDetailScreen`), au plus
        // une par couple (offre, candidat) grâce à `UNIQUE`. Alimente la
        // carte statistique "Vues totales" de `EmployerDashboard`, jusqu'ici
        // figée à une valeur en dur. `viewer_user_id` en TEXT sans FK, même
        // raison que `job_offer_notification_reads.job_seeker_user_id` (les
        // comptes de démo n'ont aucune ligne dans `users`).
        if (oldVersion < 18) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_offer_views (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
              viewer_user_id TEXT NOT NULL,
              viewed_at TEXT NOT NULL,
              UNIQUE(job_offer_id, viewer_user_id)
            )
          ''');
        }
        // v18 -> v19 : ajout de `interviews` — entretiens planifiés par un
        // recruteur pour un candidat qui a postulé (`ScheduleInterviewScreen`,
        // ouvert depuis `CandidateApplicationDetailScreen`). Alimente
        // "Entretiens du jour"/"Mes prochains entretiens" et la carte
        // statistique "Entretiens" de `EmployerDashboard`. `candidate_name`/
        // `offer_title` sont dupliqués (instantané pris à la planification)
        // plutôt que rejoints, même raisonnement que `job_applications` :
        // aucune FK, pour rester compatible avec les comptes de démo et
        // survivre à la suppression de l'offre/de la candidature liée.
        // `scheduled_date` au format 'yyyy-MM-dd', `scheduled_time` 'HH:mm' ;
        // `mode` vaut 'presentiel' ou 'visio' ; `status` 'scheduled',
        // 'done' ou 'cancelled'.
        if (oldVersion < 19) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS interviews (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              employer_user_id INTEGER NOT NULL,
              job_application_id INTEGER,
              job_offer_id INTEGER,
              job_seeker_user_id TEXT NOT NULL,
              candidate_name TEXT NOT NULL DEFAULT '',
              offer_title TEXT NOT NULL DEFAULT '',
              scheduled_date TEXT NOT NULL,
              scheduled_time TEXT NOT NULL,
              location TEXT,
              mode TEXT NOT NULL DEFAULT 'presentiel',
              notes TEXT,
              status TEXT NOT NULL DEFAULT 'scheduled',
              created_at TEXT NOT NULL
            )
          ''');
        }
        // v19 -> v20 : côté candidat, chaque entretien planifié par un
        // recruteur EST une notification ("L'entreprise souhaite vous
        // rencontrer"). `seeker_read`/`seeker_deleted` portent l'état de
        // cette notification, propre au candidat concerné (un entretien
        // n'a qu'un seul candidat, comme `job_application_notification_reads`
        // n'a qu'un seul recruteur — l'état vit donc directement sur la
        // ligne `interviews`). Re-planifier un entretien remet `seeker_read`
        // à 0 (voir `InterviewRepository.update`) pour re-notifier le
        // candidat du changement de date/heure/lieu.
        if (oldVersion < 20) {
          final columns = await db.rawQuery('PRAGMA table_info(interviews)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('seeker_read')) {
            await db.execute(
              'ALTER TABLE interviews ADD COLUMN seeker_read INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!columnNames.contains('seeker_deleted')) {
            await db.execute(
              'ALTER TABLE interviews ADD COLUMN seeker_deleted INTEGER NOT NULL DEFAULT 0',
            );
          }
        }
        // v20 -> v21 : `revision` + `notified_at` sur `interviews`. Quand le
        // recruteur modifie un entretien déjà planifié (`InterviewRepository
        // .update`), `revision` est incrémenté et `notified_at` repositionné
        // à maintenant : la notification du candidat repasse alors en non-lue
        // ET change de libellé ("Entretien modifié" au lieu de "Proposition
        // d'entretien"), et remonte en tête de `JobNotificationsScreen`
        // (tri sur `notified_at`). `notified_at` NULL pour les lignes
        // antérieures → on retombe sur `created_at` à la lecture.
        if (oldVersion < 21) {
          final columns = await db.rawQuery('PRAGMA table_info(interviews)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('revision')) {
            await db.execute(
              'ALTER TABLE interviews ADD COLUMN revision INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!columnNames.contains('notified_at')) {
            await db.execute('ALTER TABLE interviews ADD COLUMN notified_at TEXT');
            await db.execute('UPDATE interviews SET notified_at = created_at');
          }
        }
        // v21 -> v22 : réglages de `EmployerSettingsScreen` sur
        // `employer_profiles`, miroirs de ceux de `JobSeekerSettingsScreen`
        // sur `job_seeker_profiles` : `notifications_actives` (met en
        // sourdine la pastille de nouvelles candidatures), `entreprise_visible`
        // (retire l'entreprise de `AccountSearchRepository.searchEmployers`
        // sans supprimer le compte), `publicite_personnalisee` /
        // `communications_marketing` (deux consentements enregistrés d'avance,
        // aucune régie pub ni canal marketing dans l'app). `communications_marketing`
        // démarre à 0.
        if (oldVersion < 22) {
          final columns = await db.rawQuery('PRAGMA table_info(employer_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('notifications_actives')) {
            await db.execute(
              'ALTER TABLE employer_profiles ADD COLUMN notifications_actives INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (!columnNames.contains('entreprise_visible')) {
            await db.execute(
              'ALTER TABLE employer_profiles ADD COLUMN entreprise_visible INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (!columnNames.contains('publicite_personnalisee')) {
            await db.execute(
              'ALTER TABLE employer_profiles ADD COLUMN publicite_personnalisee INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (!columnNames.contains('communications_marketing')) {
            await db.execute(
              'ALTER TABLE employer_profiles ADD COLUMN communications_marketing INTEGER NOT NULL DEFAULT 0',
            );
          }
        }
        // v22 -> v23 : section "Affichage" de `EmployerSettingsScreen`,
        // miroir de celle de `JobSeekerSettingsScreen` sur
        // `job_seeker_profiles` : `mode_nuit` (bascule `AppSurfaceColors`
        // clair/sombre via `DisplayPreferencesController`/`main.dart`),
        // `texte_agrandi` (facteur d'échelle du `MediaQuery.textScaler`
        // global) et `animations_reduites` (raccourcit les animations
        // d'apparition du dashboard recruteur).
        if (oldVersion < 23) {
          final columns = await db.rawQuery('PRAGMA table_info(employer_profiles)');
          final columnNames = columns.map((c) => c['name'] as String).toSet();
          if (!columnNames.contains('mode_nuit')) {
            await db.execute(
              'ALTER TABLE employer_profiles ADD COLUMN mode_nuit INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!columnNames.contains('texte_agrandi')) {
            await db.execute(
              'ALTER TABLE employer_profiles ADD COLUMN texte_agrandi INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!columnNames.contains('animations_reduites')) {
            await db.execute(
              'ALTER TABLE employer_profiles ADD COLUMN animations_reduites INTEGER NOT NULL DEFAULT 0',
            );
          }
        }
        // v23 -> v24 : ajout de `job_seeker_profile_views` — une ligne par
        // recruteur distinct qui ouvre le profil d'un candidat
        // (`CandidateProfileViewScreen`), au plus une par couple (profil,
        // recruteur) grâce à `UNIQUE`. Alimente le compteur "N vues du
        // profil" de `JobProfileScreen`, jusqu'ici figé à "128". `TEXT` sans
        // FK des deux côtés, même raison que `job_offer_views.viewer_user_id`
        // (les comptes de démo n'ont aucune ligne dans `users`).
        if (oldVersion < 24) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_seeker_profile_views (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_user_id TEXT NOT NULL,
              viewer_user_id TEXT NOT NULL,
              viewed_at TEXT NOT NULL,
              UNIQUE(profile_user_id, viewer_user_id)
            )
          ''');
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
            disponibilite TEXT,
            cover_photo BLOB,
            profil_visible INTEGER NOT NULL DEFAULT 1,
            notifications_actives INTEGER NOT NULL DEFAULT 1,
            publicite_personnalisee INTEGER NOT NULL DEFAULT 1,
            communications_marketing INTEGER NOT NULL DEFAULT 0,
            mode_nuit INTEGER NOT NULL DEFAULT 0,
            texte_agrandi INTEGER NOT NULL DEFAULT 0,
            animations_reduites INTEGER NOT NULL DEFAULT 0
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
            categorie TEXT,
            cover_photo BLOB,
            notifications_actives INTEGER NOT NULL DEFAULT 1,
            entreprise_visible INTEGER NOT NULL DEFAULT 1,
            publicite_personnalisee INTEGER NOT NULL DEFAULT 1,
            communications_marketing INTEGER NOT NULL DEFAULT 0,
            mode_nuit INTEGER NOT NULL DEFAULT 0,
            texte_agrandi INTEGER NOT NULL DEFAULT 0,
            animations_reduites INTEGER NOT NULL DEFAULT 0
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

        await db.execute('''
          CREATE TABLE job_offer_views (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_offer_id INTEGER NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
            viewer_user_id TEXT NOT NULL,
            viewed_at TEXT NOT NULL,
            UNIQUE(job_offer_id, viewer_user_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE job_seeker_profile_views (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_user_id TEXT NOT NULL,
            viewer_user_id TEXT NOT NULL,
            viewed_at TEXT NOT NULL,
            UNIQUE(profile_user_id, viewer_user_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE interviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employer_user_id INTEGER NOT NULL,
            job_application_id INTEGER,
            job_offer_id INTEGER,
            job_seeker_user_id TEXT NOT NULL,
            candidate_name TEXT NOT NULL DEFAULT '',
            offer_title TEXT NOT NULL DEFAULT '',
            scheduled_date TEXT NOT NULL,
            scheduled_time TEXT NOT NULL,
            location TEXT,
            mode TEXT NOT NULL DEFAULT 'presentiel',
            notes TEXT,
            status TEXT NOT NULL DEFAULT 'scheduled',
            created_at TEXT NOT NULL,
            seeker_read INTEGER NOT NULL DEFAULT 0,
            seeker_deleted INTEGER NOT NULL DEFAULT 0,
            revision INTEGER NOT NULL DEFAULT 0,
            notified_at TEXT
          )
        ''');
      },
    );
  }
}
