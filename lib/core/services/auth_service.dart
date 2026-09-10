import 'package:flutter/foundation.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/services/display_preferences_controller.dart';
import 'package:joem/core/services/google_auth_service.dart';
import 'package:joem/core/utils/cv_storage.dart';
import 'package:joem/core/utils/password_hasher.dart';

/// Une expérience professionnelle saisie par le candidat depuis
/// `JobProfileScreen` (`job_seeker_experiences`) — l'inscription ne
/// collecte aucune expérience, seulement le titre professionnel courant.
/// [id] reste `null` tant que l'entrée n'a pas été persistée (compte de
/// démo, id négatif : jamais persistée).
class JobExperience {
  const JobExperience({
    this.id,
    required this.poste,
    required this.entreprise,
    required this.dateDebut,
    this.dateFin,
    this.enCours = false,
    this.description,
  });

  final int? id;
  final String poste;
  final String entreprise;
  final String dateDebut;
  final String? dateFin;
  final bool enCours;
  final String? description;
}

/// Modèle d'utilisateur
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'job_seeker' ou 'employer'
  final String? companyName;

  /// Catégorie de l'entreprise (parmi `kJobCategories`), choisie à
  /// l'inscription recruteur (`StepTwoPersonalInfo`, champ obligatoire) et
  /// modifiable depuis `EditEmployerProfileScreen` — réutilisée côté
  /// candidat pour filtrer les offres par secteur
  /// (`JobOfferRepository.fetchByCategory`). Toujours `null` pour un
  /// chercheur d'emploi.
  final String? categorieEntreprise;

  /// Titre professionnel du chercheur d'emploi (ex: "Développeur Flutter"),
  /// saisi à l'étape "Info" de l'inscription.
  final String? position;

  /// Photo de profil choisie à l'étape "Info" de l'inscription (`null` si
  /// aucune n'a été sélectionnée).
  final Uint8List? photoBytes;

  /// Photo de couverture (bannière) de `JobProfileScreen`/
  /// `EmployerProfileScreen`, choisie via l'icône caméra (`null` si aucune
  /// n'a été sélectionnée).
  final Uint8List? coverPhotoBytes;

  // Les champs ci-dessous reprennent, un par un, les données optionnelles
  // saisies à l'inscription — wizard chercheur d'emploi (`job_seeker_profiles`
  // + tables liées) ou wizard recruteur (`employer_profiles`) selon [role].
  // `telephone`/`localisation`/`presentation`/`photoBytes` sont partagés par
  // les deux rôles (pour un employeur : `presentation` = description de
  // l'entreprise, `photoBytes` = logo) ; `cvPicked`/`tarifJournalier`/
  // `disponibilite`/`skills`/`workModes` restent vides/`false` pour un
  // employeur. Servent à calculer [profileCompletion]/[missingJobSeekerFieldLabels]
  // (chercheur d'emploi) ou [employerProfileCompletion]/[missingEmployerFieldLabels]
  // (employeur).
  final String? telephone;
  final String? localisation;
  final String? presentation;

  /// Chemin absolu du fichier CV (PDF ou image) sur le disque — écrit par
  /// `saveCvFile` (`lib/core/utils/cv_storage.dart`) plutôt que stocké en
  /// BLOB dans SQLite, pour ne jamais dépasser la limite d'un
  /// `CursorWindow` Android (~2 Mo par ligne) avec un fichier un peu lourd.
  final String? cvPath;
  final String? cvFileName;

  /// `true` dès qu'un fichier CV est attaché.
  bool get cvPicked => cvFileName != null;

  final String? tarifJournalier;
  final String? disponibilite;

  /// Noms des compétences saisies à l'étape "Profil professionnel" de
  /// l'inscription (`job_seeker_skills`) — liste vide si aucune.
  final List<String> skills;

  /// Modes de travail sélectionnés à l'étape "Tarif" de l'inscription
  /// (`job_seeker_work_modes`) — liste vide si aucun.
  final List<String> workModes;

  /// Expériences professionnelles réellement ajoutées depuis
  /// `JobProfileScreen` (`job_seeker_experiences`) — liste vide si aucune.
  final List<JobExperience> experiences;

  /// `false` si le candidat a désactivé "Profil visible par les
  /// recruteurs" (`JobSeekerSettingsScreen`) — exclut alors son profil de
  /// `AccountSearchRepository.searchJobSeekers` (recherche recruteur et
  /// "Candidats suggérés"). Toujours `true` pour un employeur (non
  /// concerné) et pour un compte fraîchement chargé sans préférence
  /// explicite.
  final bool profilVisible;

  /// `false` si le candidat a désactivé "Recevoir des notifications de
  /// nouvelles offres" (`JobSeekerSettingsScreen`) — la pastille de
  /// compteur (header, nav basse) reste alors à 0 sans interroger
  /// `JobOfferRepository.countUnreadNotificationsForJobSeeker`, voir
  /// `JobSeekerDashboard._loadNotificationCount`. Les notifications déjà
  /// reçues restent consultables depuis `JobNotificationsScreen`, rien
  /// n'est supprimé.
  final bool notificationsEnabled;

  /// Consentement "Publicités personnalisées" (`JobSeekerSettingsScreen`,
  /// section Confidentialité) — équivalent du réglage `Ad personalization`
  /// des grands OS/apps. JOEM ne diffuse aujourd'hui aucune publicité
  /// (application 100% locale, sans SDK publicitaire) : cette préférence
  /// est donc pour l'instant seulement enregistrée, prête à être respectée
  /// si une régie publicitaire est un jour intégrée.
  final bool adsPersonalized;

  /// Consentement "Communications marketing" (offres promotionnelles et
  /// actualités JOEM) — décoché par défaut, comme tout consentement
  /// marketing. Même remarque que [adsPersonalized] : aucun canal d'envoi
  /// (email/push) n'existe encore dans l'app pour l'honorer.
  final bool marketingOptIn;

  /// "Mode nuit" (`JobSeekerSettingsScreen`, section Affichage) — synchronisé
  /// vers `DisplayPreferencesController` à chaque connexion/déconnexion
  /// (voir `AuthService`), qui pilote réellement l'assombrissement de tout
  /// le parcours candidat via `AppSurfaceColors`/`main.dart`.
  final bool darkModeEnabled;

  /// "Texte agrandi" — applique `DisplayPreferencesController
  /// .largeTextScaleFactor` au `MediaQuery.textScaler` global (voir
  /// `main.dart`), donc à tout texte de l'app tant que ce compte est
  /// connecté.
  final bool largeTextEnabled;

  /// "Réduire les animations" — raccourcit le fondu d'apparition de
  /// `JobSeekerDashboard` et le glissement de `ProfileSidePanel`.
  final bool reducedAnimationsEnabled;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.companyName,
    this.categorieEntreprise,
    this.position,
    this.photoBytes,
    this.coverPhotoBytes,
    this.telephone,
    this.localisation,
    this.presentation,
    this.cvPath,
    this.cvFileName,
    this.tarifJournalier,
    this.disponibilite,
    this.skills = const [],
    this.workModes = const [],
    this.experiences = const [],
    this.profilVisible = true,
    this.notificationsEnabled = true,
    this.adsPersonalized = true,
    this.marketingOptIn = false,
    this.darkModeEnabled = false,
    this.largeTextEnabled = false,
    this.reducedAnimationsEnabled = false,
  });

  /// Copie l'utilisateur en ne remplaçant que les champs fournis — les
  /// champs saisis à l'inscription (nom, coordonnées, tarif...) se
  /// modifient via `AuthService.updateJobSeekerProfile`/
  /// `updateEmployerProfile`, qui reconstruisent `User` en entier ; ce
  /// `copyWith` couvre les mises à jour ponctuelles (photo, CV,
  /// expériences, préférences) déclenchées depuis un seul écran.
  User copyWith({
    Uint8List? photoBytes,
    Uint8List? coverPhotoBytes,
    String? cvPath,
    String? cvFileName,
    bool clearCv = false,
    List<JobExperience>? experiences,
    bool? profilVisible,
    bool? notificationsEnabled,
    bool? adsPersonalized,
    bool? marketingOptIn,
    bool? darkModeEnabled,
    bool? largeTextEnabled,
    bool? reducedAnimationsEnabled,
  }) {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      companyName: companyName,
      categorieEntreprise: categorieEntreprise,
      position: position,
      photoBytes: photoBytes ?? this.photoBytes,
      coverPhotoBytes: coverPhotoBytes ?? this.coverPhotoBytes,
      telephone: telephone,
      localisation: localisation,
      presentation: presentation,
      cvPath: clearCv ? null : (cvPath ?? this.cvPath),
      cvFileName: clearCv ? null : (cvFileName ?? this.cvFileName),
      tarifJournalier: tarifJournalier,
      disponibilite: disponibilite,
      skills: skills,
      workModes: workModes,
      experiences: experiences ?? this.experiences,
      profilVisible: profilVisible ?? this.profilVisible,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      adsPersonalized: adsPersonalized ?? this.adsPersonalized,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      largeTextEnabled: largeTextEnabled ?? this.largeTextEnabled,
      reducedAnimationsEnabled: reducedAnimationsEnabled ?? this.reducedAnimationsEnabled,
    );
  }

  /// Part des champs du profil chercheur d'emploi qui sont renseignés (les
  /// 5 étapes du wizard d'inscription réunies), pour la barre "Profil
  /// complété" de `ProfileSidePanel`/`JobProfileScreen`. Toujours 0.0 pour
  /// un employeur.
  double get profileCompletion {
    final fieldsFilled = <bool>[
      firstName.trim().isNotEmpty,
      lastName.trim().isNotEmpty,
      (position ?? '').trim().isNotEmpty,
      (telephone ?? '').trim().isNotEmpty,
      (localisation ?? '').trim().isNotEmpty,
      (presentation ?? '').trim().isNotEmpty,
      photoBytes != null,
      cvPicked,
      (tarifJournalier ?? '').trim().isNotEmpty,
      (disponibilite ?? '').trim().isNotEmpty,
      skills.isNotEmpty,
      workModes.isNotEmpty,
      experiences.isNotEmpty,
    ];
    final filledCount = fieldsFilled.where((filled) => filled).length;
    return filledCount / fieldsFilled.length;
  }

  /// Libellés (français) des champs du profil chercheur d'emploi encore
  /// vides, dans l'ordre du wizard d'inscription — utilisés comme
  /// suggestions dans la carte "Profil complété" de `JobProfileScreen`.
  List<String> get missingJobSeekerFieldLabels {
    return [
      if (firstName.trim().isEmpty || lastName.trim().isEmpty)
        'Complétez votre nom et prénom',
      if ((position ?? '').trim().isEmpty) 'Ajoutez votre titre professionnel',
      if ((telephone ?? '').trim().isEmpty) 'Ajoutez votre numéro de téléphone',
      if ((localisation ?? '').trim().isEmpty) 'Indiquez votre localisation',
      if ((presentation ?? '').trim().isEmpty) 'Rédigez la section "À propos"',
      if (photoBytes == null) 'Ajoutez une photo de profil',
      if (!cvPicked) 'Ajoutez votre CV',
      if ((tarifJournalier ?? '').trim().isEmpty) 'Renseignez votre tarif journalier',
      if ((disponibilite ?? '').trim().isEmpty) 'Indiquez votre disponibilité',
      if (skills.isEmpty) 'Ajoutez au moins une compétence',
      if (workModes.isEmpty) 'Précisez vos modes de travail préférés',
      if (experiences.isEmpty) 'Ajoutez une expérience professionnelle',
    ];
  }

  /// Part des champs du profil recruteur qui sont renseignés (les 2 étapes
  /// du wizard d'inscription recruteur réunies), pour la barre "Profil
  /// complété" de `EmployerProfileSidePanel`/`EmployerProfileScreen`.
  /// Toujours 0.0 pour un chercheur d'emploi.
  double get employerProfileCompletion {
    final fieldsFilled = <bool>[
      firstName.trim().isNotEmpty,
      lastName.trim().isNotEmpty,
      (telephone ?? '').trim().isNotEmpty,
      (localisation ?? '').trim().isNotEmpty,
      (companyName ?? '').trim().isNotEmpty,
      (categorieEntreprise ?? '').trim().isNotEmpty,
      (presentation ?? '').trim().isNotEmpty,
      photoBytes != null,
    ];
    final filledCount = fieldsFilled.where((filled) => filled).length;
    return filledCount / fieldsFilled.length;
  }

  /// Libellés (français) des champs du profil recruteur encore vides —
  /// utilisés comme suggestions dans la carte "Profil complété" de
  /// `EmployerProfileScreen`.
  List<String> get missingEmployerFieldLabels {
    return [
      if (firstName.trim().isEmpty || lastName.trim().isEmpty)
        'Complétez votre nom et prénom',
      if ((telephone ?? '').trim().isEmpty) 'Ajoutez votre numéro de téléphone',
      if ((localisation ?? '').trim().isEmpty) 'Indiquez la localisation de l\'entreprise',
      if ((companyName ?? '').trim().isEmpty) 'Renseignez le nom de l\'entreprise',
      if ((categorieEntreprise ?? '').trim().isEmpty) 'Choisissez la catégorie de votre entreprise',
      if ((presentation ?? '').trim().isEmpty) 'Décrivez votre entreprise et vos besoins',
      if (photoBytes == null) 'Ajoutez le logo de l\'entreprise',
    ];
  }
}

/// Service d'authentification. Singleton : toutes les instances
/// `AuthService()` partagent la même session (`_currentUser`), pour que
/// LoginScreen, l'inscription et les écrans de dashboard restent en phase.
class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Comptes de démonstration. `id` négatif exprès : ces comptes n'ont
  /// aucune ligne dans `users` (AUTOINCREMENT, toujours positif), donc un
  /// id positif collisionnerait tôt ou tard avec un vrai utilisateur
  /// inscrit — notamment pour `job_offers.employer_user_id`.
  static final Map<String, Map<String, dynamic>> _demoAccounts = {
    'employeur@gmail.com': {
      'password': 'employeur123@gmail.com',
      'user': User(
        id: '-1',
        email: 'employeur@gmail.com',
        firstName: 'Jean',
        lastName: 'Dupont',
        role: 'employer',
        companyName: 'Tech Solutions',
      ),
    },
    'candidat@gmail.com': {
      'password': 'candidat123',
      'user': User(
        id: '-2',
        email: 'candidat@gmail.com',
        firstName: 'Marie',
        lastName: 'Martin',
        role: 'job_seeker',
      ),
    },
  };

  /// Connexion — vérifie d'abord les comptes de démo codés en dur, puis
  /// les comptes créés localement via un wizard d'inscription (SQLite).
  ///
  /// Le bloc `try`/`finally` garantit que [_isLoading] repasse à `false`
  /// même si la lecture en base échoue (avant, une exception ici laissait
  /// `LoginScreen` bloqué indéfiniment sur "Connexion...", puisque son
  /// propre `await` n'était entouré d'aucun `try/catch` non plus).
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(seconds: 1));

      final demoAccount = _demoAccounts[email];
      if (demoAccount != null && demoAccount['password'] == password) {
        _currentUser = demoAccount['user'] as User;
        _syncDisplayPreferences();
        await _persistSession(email);
        return true;
      }

      final dbUser = await _loginFromDatabase(email, password);
      if (dbUser != null) {
        _currentUser = dbUser;
        _syncDisplayPreferences();
        await _persistSession(email);
        return true;
      }

      return false;
    } catch (error, stackTrace) {
      debugPrint('AuthService.login failed: $error\n$stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restaure la session du dernier utilisateur connecté (email retenu
  /// dans `session`, voir `AppDatabase`) — utilisé au démarrage de l'app
  /// pour renvoyer directement sur le bon dashboard plutôt que sur
  /// Welcome, notamment après un retour matériel accidentel qui a quitté
  /// l'app. Retourne `false` si personne n'était connecté ou si le
  /// compte associé n'existe plus.
  Future<bool> restoreSession() async {
    if (_currentUser != null) return true;

    final db = await AppDatabase.instance.database;
    final sessionRows = await db.query('session', limit: 1);
    if (sessionRows.isEmpty) return false;
    final email = sessionRows.first['email'] as String;

    final demoAccount = _demoAccounts[email];
    if (demoAccount != null) {
      _currentUser = demoAccount['user'] as User;
      _syncDisplayPreferences();
      notifyListeners();
      return true;
    }

    final user = await _loadUserByEmail(email);
    if (user == null) {
      await _clearPersistedSession();
      return false;
    }
    _currentUser = user;
    _syncDisplayPreferences();
    notifyListeners();
    return true;
  }

  /// Applique les préférences d'affichage (`darkModeEnabled`/
  /// `largeTextEnabled`/`reducedAnimationsEnabled`) de [_currentUser] à
  /// `DisplayPreferencesController`, seule source consultée par `main.dart`/
  /// `JobSeekerDashboard` — appelé après toute connexion réussie. Sans
  /// effet si personne n'est connecté (comptes employeur : ces préférences
  /// restent à leurs valeurs par défaut, `false`).
  void _syncDisplayPreferences() {
    final user = _currentUser;
    DisplayPreferencesController.instance.syncFrom(
      isDarkMode: user?.darkModeEnabled ?? false,
      isLargeText: user?.largeTextEnabled ?? false,
      reducedAnimations: user?.reducedAnimationsEnabled ?? false,
    );
  }

  Future<void> _persistSession(String email) async {
    final db = await AppDatabase.instance.database;
    await db.delete('session');
    await db.insert('session', {'id': 1, 'email': email});
  }

  Future<void> _clearPersistedSession() async {
    final db = await AppDatabase.instance.database;
    await db.delete('session');
  }

  Future<User?> _loginFromDatabase(String email, String password) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.first;
    if (row['password_hash'] != hashPassword(password)) return null;

    return _buildUserFromRow(row, email);
  }

  /// Recharge un utilisateur déjà authentifié (session persistée), sans
  /// revérifier de mot de passe — utilisé par [restoreSession] uniquement.
  Future<User?> _loadUserByEmail(String email) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (rows.isEmpty) return null;
    return _buildUserFromRow(rows.first, email);
  }

  Future<User> _buildUserFromRow(Map<String, Object?> row, String email) async {
    final db = await AppDatabase.instance.database;
    final userId = row['id'] as int;
    final role = row['role'] as String;

    if (role == 'job_seeker') {
      // `cv_bytes` (colonne legacy, plus jamais écrite) est explicitement
      // exclue de cette lecture — voir `AppDatabase`, migration v10 -> v11 :
      // le CV vit désormais comme un fichier sur le disque (`cv_path`),
      // pas en BLOB, pour ne jamais dépasser la limite d'un `CursorWindow`
      // Android (~2 Mo par ligne).
      final profileRows = await db.query(
        'job_seeker_profiles',
        columns: [
          'prenom', 'nom', 'telephone', 'localisation', 'titre_professionnel',
          'presentation', 'photo', 'cover_photo', 'cv_path', 'cv_file_name',
          'tarif_journalier', 'disponibilite', 'profil_visible',
          'notifications_actives', 'publicite_personnalisee', 'communications_marketing',
          'mode_nuit', 'texte_agrandi', 'animations_reduites',
        ],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      final profile = profileRows.isNotEmpty ? profileRows.first : null;

      final skillRows = await db.query(
        'job_seeker_skills',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final workModeRows = await db.query(
        'job_seeker_work_modes',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final experienceRows = await db.query(
        'job_seeker_experiences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return User(
        id: userId.toString(),
        email: email,
        firstName: profile?['prenom'] as String? ?? '',
        lastName: profile?['nom'] as String? ?? '',
        role: role,
        position: profile?['titre_professionnel'] as String?,
        photoBytes: profile?['photo'] as Uint8List?,
        coverPhotoBytes: profile?['cover_photo'] as Uint8List?,
        telephone: profile?['telephone'] as String?,
        localisation: profile?['localisation'] as String?,
        presentation: profile?['presentation'] as String?,
        cvPath: profile?['cv_path'] as String?,
        cvFileName: profile?['cv_file_name'] as String?,
        tarifJournalier: profile?['tarif_journalier'] as String?,
        disponibilite: profile?['disponibilite'] as String?,
        profilVisible: (profile?['profil_visible'] as int? ?? 1) == 1,
        notificationsEnabled: (profile?['notifications_actives'] as int? ?? 1) == 1,
        adsPersonalized: (profile?['publicite_personnalisee'] as int? ?? 1) == 1,
        marketingOptIn: (profile?['communications_marketing'] as int? ?? 0) == 1,
        darkModeEnabled: (profile?['mode_nuit'] as int? ?? 0) == 1,
        largeTextEnabled: (profile?['texte_agrandi'] as int? ?? 0) == 1,
        reducedAnimationsEnabled: (profile?['animations_reduites'] as int? ?? 0) == 1,
        skills: skillRows.map((row) => row['name'] as String).toList(),
        workModes: workModeRows.map((row) => row['work_mode'] as String).toList(),
        experiences: experienceRows
            .map((row) => JobExperience(
                  id: row['id'] as int,
                  poste: row['poste'] as String,
                  entreprise: row['entreprise'] as String,
                  dateDebut: row['date_debut'] as String,
                  dateFin: row['date_fin'] as String?,
                  enCours: (row['en_cours'] as int? ?? 0) == 1,
                  description: row['description'] as String?,
                ))
            .toList(),
      );
    }

    if (role == 'employer') {
      final profileRows = await db.query(
        'employer_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      final profile = profileRows.isNotEmpty ? profileRows.first : null;

      return User(
        id: userId.toString(),
        email: email,
        firstName: profile?['prenom'] as String? ?? '',
        lastName: profile?['nom'] as String? ?? '',
        role: role,
        companyName: profile?['nom_entreprise'] as String?,
        categorieEntreprise: profile?['categorie'] as String?,
        photoBytes: profile?['logo'] as Uint8List?,
        coverPhotoBytes: profile?['cover_photo'] as Uint8List?,
        telephone: profile?['telephone'] as String?,
        localisation: profile?['localisation'] as String?,
        presentation: profile?['description'] as String?,
        // Réglages `EmployerSettingsScreen` (colonnes ajoutées en v22, la
        // section "Affichage" en v23). `profilVisible` sert ici de
        // "entreprise visible dans la recherche des candidats"
        // (`employer_profiles.entreprise_visible`).
        profilVisible: (profile?['entreprise_visible'] as int? ?? 1) == 1,
        notificationsEnabled: (profile?['notifications_actives'] as int? ?? 1) == 1,
        adsPersonalized: (profile?['publicite_personnalisee'] as int? ?? 1) == 1,
        marketingOptIn: (profile?['communications_marketing'] as int? ?? 0) == 1,
        darkModeEnabled: (profile?['mode_nuit'] as int? ?? 0) == 1,
        largeTextEnabled: (profile?['texte_agrandi'] as int? ?? 0) == 1,
        reducedAnimationsEnabled: (profile?['animations_reduites'] as int? ?? 0) == 1,
      );
    }

    return User(id: userId.toString(), email: email, firstName: '', lastName: '', role: role);
  }

  /// Ouvre directement une session pour [user] — utilisé juste après une
  /// inscription réussie pour envoyer l'utilisateur sur son dashboard
  /// sans lui refaire saisir ses identifiants.
  Future<void> setSession(User user) async {
    _currentUser = user;
    _syncDisplayPreferences();
    notifyListeners();
    await _persistSession(user.email);
  }

  /// Connexion via un compte Google déjà lié à un compte JOEM (même email
  /// — un compte créé via "Continuer avec Google" à l'inscription utilise
  /// justement l'email du compte Google réel, voir `StepOneAccount`). Ne
  /// crée jamais de compte ici : si aucun compte JOEM n'a cet email,
  /// l'utilisateur doit d'abord s'inscrire.
  ///
  /// Renvoie `null` si l'utilisateur annule la sélection de compte Google
  /// (pas une erreur, rien à afficher), `false` si aucun compte JOEM ne
  /// correspond à l'email obtenu, `true` si la connexion a réussi. Laisse
  /// remonter [GoogleSignInException] pour toute autre erreur
  /// (configuration Google Cloud incomplète, pas de réseau, etc.).
  Future<bool?> loginWithGoogle() async {
    final account = await GoogleAuthService.instance.signIn();
    if (account == null) return null;

    final user = await _loadUserByEmail(account.email);
    if (user == null) return false;

    _currentUser = user;
    _syncDisplayPreferences();
    notifyListeners();
    await _persistSession(user.email);
    return true;
  }

  /// Déconnexion
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
    DisplayPreferencesController.instance.reset();
    await _clearPersistedSession();
    _isLoading = false;
    notifyListeners();
  }

  /// Réinitialise le mot de passe du compte [email] (`ForgotPasswordScreen`)
  /// — appli 100% locale, sans serveur mail : pas d'envoi de lien, on
  /// vérifie juste qu'un compte existe avec cet email puis on écrase son
  /// `password_hash` directement. Renvoie `false` si aucun compte inscrit
  /// (via un wizard) ne correspond — les comptes de démo codés en dur
  /// (`_demoAccounts`, aucune ligne dans `users`) ne sont volontairement
  /// pas concernés, leur mot de passe reste celui du code.
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final db = await AppDatabase.instance.database;
    final trimmedEmail = email.trim();
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [trimmedEmail],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    await db.update(
      'users',
      {'password_hash': hashPassword(newPassword)},
      where: 'email = ?',
      whereArgs: [trimmedEmail],
    );
    return true;
  }

  /// Change la photo de profil de l'utilisateur connecté et la persiste
  /// (compte inscrit via un wizard : `job_seeker_profiles.photo` ou
  /// `employer_profiles.logo` ; comptes de démo : id négatif, aucune ligne
  /// `users` à mettre à jour, la nouvelle photo ne vit que pour la session
  /// en cours). `notifyListeners()` propage le changement à tous les
  /// écrans qui lisent `currentUser` après reconstruction (header,
  /// panneau latéral, publication, etc.).
  Future<void> updateProfilePhoto(Uint8List photoBytes) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(photoBytes: photoBytes);
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    if (user.role == 'job_seeker') {
      await db.update(
        'job_seeker_profiles',
        {'photo': photoBytes},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else if (user.role == 'employer') {
      await db.update(
        'employer_profiles',
        {'logo': photoBytes},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  /// Change la photo de couverture (bannière) de l'utilisateur connecté et
  /// la persiste, même logique que [updateProfilePhoto] : `job_seeker_profiles.cover_photo`
  /// ou `employer_profiles.cover_photo` pour un compte inscrit ; comptes de
  /// démo (id négatif), la nouvelle bannière ne vit que pour la session en
  /// cours.
  Future<void> updateCoverPhoto(Uint8List coverPhotoBytes) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(coverPhotoBytes: coverPhotoBytes);
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    if (user.role == 'job_seeker') {
      await db.update(
        'job_seeker_profiles',
        {'cover_photo': coverPhotoBytes},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else if (user.role == 'employer') {
      await db.update(
        'employer_profiles',
        {'cover_photo': coverPhotoBytes},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  /// Change le CV (PDF ou image) du chercheur d'emploi connecté et le
  /// persiste (compte inscrit via le wizard) ou le garde en mémoire pour
  /// la session (comptes de démo, id négatif).
  Future<void> updateCv({required Uint8List cvBytes, required String cvFileName}) async {
    final user = _currentUser;
    if (user == null) return;

    final cvPath = await saveCvFile(cvBytes, cvFileName);

    _currentUser = user.copyWith(cvPath: cvPath, cvFileName: cvFileName);
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      'job_seeker_profiles',
      {'cv_path': cvPath, 'cv_file_name': cvFileName, 'cv_picked': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Supprime le CV du chercheur d'emploi connecté — fichier sur le disque
  /// (`deleteCvFile`) et champs en base, utilisé par "Supprimer mon CV" de
  /// `JobSeekerSettingsScreen`. Ne fait rien si aucun CV n'est attaché.
  Future<void> deleteCv() async {
    final user = _currentUser;
    if (user == null || user.cvPath == null) return;

    await deleteCvFile(user.cvPath!);

    _currentUser = user.copyWith(clearCv: true);
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      'job_seeker_profiles',
      {'cv_path': null, 'cv_file_name': null, 'cv_picked': 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Change la préférence "Profil visible par les recruteurs" du candidat
  /// connecté et la persiste (`job_seeker_profiles.profil_visible`) —
  /// réglage "Confidentialité" de `JobSeekerSettingsScreen`. Un profil
  /// masqué disparaît de `AccountSearchRepository.searchJobSeekers`
  /// (recherche recruteur et "Candidats suggérés") sans supprimer le
  /// compte. Comptes de démo (id négatif) : la préférence ne vit que pour
  /// la session en cours, aucune ligne `job_seeker_profiles` à mettre à
  /// jour.
  Future<void> updateProfileVisibility(bool visible) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(profilVisible: visible);
    notifyListeners();
    await _persistProfileFlag(
      user,
      jobSeekerColumn: 'profil_visible',
      employerColumn: 'entreprise_visible',
      value: visible,
    );
  }

  /// Écrit un drapeau booléen (`0`/`1`) de réglage sur la table de profil
  /// correspondant au rôle de [user] — `job_seeker_profiles` ou
  /// `employer_profiles`, colonnes miroir de `JobSeekerSettingsScreen` /
  /// `EmployerSettingsScreen`. Ne fait rien pour un compte de démo (id
  /// négatif) : la préférence ne vit alors que pour la session en cours.
  Future<void> _persistProfileFlag(
    User user, {
    required String jobSeekerColumn,
    required String employerColumn,
    required bool value,
  }) async {
    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    final (table, column) = user.role == 'employer'
        ? ('employer_profiles', employerColumn)
        : ('job_seeker_profiles', jobSeekerColumn);
    await db.update(
      table,
      {column: value ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Change la préférence "Recevoir des notifications de nouvelles offres"
  /// du candidat connecté et la persiste (`job_seeker_profiles
  /// .notifications_actives`) — réglage "Notifications" de
  /// `JobSeekerSettingsScreen`. Désactivée, la pastille de compteur
  /// (header, nav basse) reste à 0 sans interroger `JobOfferRepository
  /// .countUnreadNotificationsForJobSeeker` (voir `JobSeekerDashboard
  /// ._loadNotificationCount`) ; les notifications déjà reçues restent
  /// consultables depuis `JobNotificationsScreen`, rien n'est supprimé.
  Future<void> updateNotificationsEnabled(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await _persistProfileFlag(
      user,
      jobSeekerColumn: 'notifications_actives',
      employerColumn: 'notifications_actives',
      value: enabled,
    );
  }

  /// Change le consentement "Publicités personnalisées" du candidat
  /// connecté et le persiste (`job_seeker_profiles.publicite_personnalisee`)
  /// — réglage "Confidentialité" de `JobSeekerSettingsScreen`. JOEM ne
  /// diffuse aujourd'hui aucune publicité (voir doc de [User.adsPersonalized]) :
  /// cette préférence est enregistrée pour être respectée si une régie
  /// publicitaire est un jour intégrée.
  Future<void> updateAdsPersonalized(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(adsPersonalized: enabled);
    notifyListeners();
    await _persistProfileFlag(
      user,
      jobSeekerColumn: 'publicite_personnalisee',
      employerColumn: 'publicite_personnalisee',
      value: enabled,
    );
  }

  /// Change le consentement "Communications marketing" (offres
  /// promotionnelles et actualités JOEM) du candidat connecté et le
  /// persiste (`job_seeker_profiles.communications_marketing`) — réglage
  /// "Confidentialité" de `JobSeekerSettingsScreen`. Voir doc de
  /// [User.marketingOptIn] : aucun canal d'envoi n'existe encore dans
  /// l'app pour l'honorer.
  Future<void> updateMarketingOptIn(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(marketingOptIn: enabled);
    notifyListeners();
    await _persistProfileFlag(
      user,
      jobSeekerColumn: 'communications_marketing',
      employerColumn: 'communications_marketing',
      value: enabled,
    );
  }

  /// Table de profil qui porte les colonnes de réglages (`mode_nuit`,
  /// `texte_agrandi`, `animations_reduites`, visibilité, notifications...)
  /// pour [user] : `employer_profiles` pour un recruteur, sinon
  /// `job_seeker_profiles`. Les deux tables ont les mêmes colonnes de
  /// réglages depuis les migrations v22/v23.
  String _profileTableFor(User user) =>
      user.role == 'employer' ? 'employer_profiles' : 'job_seeker_profiles';

  /// Change "Mode nuit" de l'utilisateur connecté (candidat ou recruteur),
  /// le persiste (`<profil>.mode_nuit`) et met à jour
  /// `DisplayPreferencesController` — qui pilote l'assombrissement via
  /// `AppSurfaceColors`/`main.dart`.
  Future<void> updateDarkMode(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(darkModeEnabled: enabled);
    DisplayPreferencesController.instance.setDarkMode(enabled);
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      _profileTableFor(user),
      {'mode_nuit': enabled ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Change "Texte agrandi" de l'utilisateur connecté (candidat ou
  /// recruteur), le persiste (`<profil>.texte_agrandi`) et met à jour
  /// `DisplayPreferencesController` — qui applique le facteur d'échelle au
  /// `MediaQuery.textScaler` global (voir `main.dart`).
  Future<void> updateLargeText(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(largeTextEnabled: enabled);
    DisplayPreferencesController.instance.setLargeText(enabled);
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      _profileTableFor(user),
      {'texte_agrandi': enabled ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Change "Réduire les animations" de l'utilisateur connecté (candidat ou
  /// recruteur), le persiste (`<profil>.animations_reduites`) et met à jour
  /// `DisplayPreferencesController` — consulté par `JobSeekerDashboard`/
  /// `ProfileSidePanel` et `EmployerDashboard` pour raccourcir leurs
  /// animations d'apparition.
  Future<void> updateReducedAnimations(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(reducedAnimationsEnabled: enabled);
    DisplayPreferencesController.instance.setReducedAnimations(enabled);
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      _profileTableFor(user),
      {'animations_reduites': enabled ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Met à jour les champs du profil chercheur d'emploi modifiables depuis
  /// l'écran "Modifier le profil" (`JobProfileScreen`, icône stylo) et les
  /// persiste (compte inscrit via le wizard) ou les garde en mémoire pour
  /// la session (comptes de démo, id négatif). `notifyListeners()` propage
  /// le changement à tous les écrans qui lisent `currentUser` — dont la
  /// carte "Profil complété", recalculée depuis ces mêmes champs.
  Future<void> updateJobSeekerProfile({
    required String firstName,
    required String lastName,
    required String? position,
    required String? telephone,
    required String? localisation,
    required String? presentation,
    required String? tarifJournalier,
    required String? disponibilite,
    required List<String> skills,
    required List<String> workModes,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = User(
      id: user.id,
      email: user.email,
      firstName: firstName,
      lastName: lastName,
      role: user.role,
      companyName: user.companyName,
      position: position,
      photoBytes: user.photoBytes,
      coverPhotoBytes: user.coverPhotoBytes,
      telephone: telephone,
      localisation: localisation,
      presentation: presentation,
      cvPath: user.cvPath,
      cvFileName: user.cvFileName,
      tarifJournalier: tarifJournalier,
      disponibilite: disponibilite,
      skills: skills,
      workModes: workModes,
      experiences: user.experiences,
      profilVisible: user.profilVisible,
      notificationsEnabled: user.notificationsEnabled,
      adsPersonalized: user.adsPersonalized,
      marketingOptIn: user.marketingOptIn,
      darkModeEnabled: user.darkModeEnabled,
      largeTextEnabled: user.largeTextEnabled,
      reducedAnimationsEnabled: user.reducedAnimationsEnabled,
    );
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      'job_seeker_profiles',
      {
        'nom': lastName,
        'prenom': firstName,
        'telephone': telephone,
        'localisation': localisation,
        'titre_professionnel': position ?? '',
        'presentation': presentation,
        'tarif_journalier': tarifJournalier,
        'disponibilite': disponibilite,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    await db.delete('job_seeker_skills', where: 'user_id = ?', whereArgs: [userId]);
    for (final skill in skills) {
      await db.insert('job_seeker_skills', {'user_id': userId, 'name': skill, 'rating': 0});
    }

    await db.delete('job_seeker_work_modes', where: 'user_id = ?', whereArgs: [userId]);
    for (final mode in workModes) {
      await db.insert('job_seeker_work_modes', {'user_id': userId, 'work_mode': mode});
    }
  }

  /// Met à jour les champs du profil recruteur modifiables depuis l'écran
  /// "Modifier le profil" (`EmployerProfileScreen`, icône stylo) et les
  /// persiste (compte inscrit via le wizard) ou les garde en mémoire pour
  /// la session (comptes de démo, id négatif). `notifyListeners()` propage
  /// le changement à tous les écrans qui lisent `currentUser` — dont la
  /// carte "Profil complété", recalculée depuis ces mêmes champs.
  Future<void> updateEmployerProfile({
    required String firstName,
    required String lastName,
    required String? companyName,
    required String? categorieEntreprise,
    required String? telephone,
    required String? localisation,
    required String? presentation,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = User(
      id: user.id,
      email: user.email,
      firstName: firstName,
      lastName: lastName,
      role: user.role,
      companyName: companyName,
      categorieEntreprise: categorieEntreprise,
      position: user.position,
      photoBytes: user.photoBytes,
      coverPhotoBytes: user.coverPhotoBytes,
      telephone: telephone,
      localisation: localisation,
      presentation: presentation,
      cvPath: user.cvPath,
      cvFileName: user.cvFileName,
      tarifJournalier: user.tarifJournalier,
      disponibilite: user.disponibilite,
      skills: user.skills,
      workModes: user.workModes,
      experiences: user.experiences,
      profilVisible: user.profilVisible,
      notificationsEnabled: user.notificationsEnabled,
      adsPersonalized: user.adsPersonalized,
      marketingOptIn: user.marketingOptIn,
      darkModeEnabled: user.darkModeEnabled,
      largeTextEnabled: user.largeTextEnabled,
      reducedAnimationsEnabled: user.reducedAnimationsEnabled,
    );
    notifyListeners();

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      'employer_profiles',
      {
        'nom': lastName,
        'prenom': firstName,
        'telephone': telephone,
        'localisation': localisation,
        'nom_entreprise': (companyName ?? '').trim(),
        'categorie': categorieEntreprise,
        'description': presentation,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Ajoute une expérience professionnelle au profil connecté, saisie
  /// depuis `JobProfileScreen` — persistée (`job_seeker_experiences`) pour
  /// un compte inscrit via le wizard, gardée en mémoire pour un compte de
  /// démo (id négatif).
  Future<void> addExperience({
    required String poste,
    required String entreprise,
    required String dateDebut,
    String? dateFin,
    bool enCours = false,
    String? description,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    int? id;
    final userId = int.tryParse(user.id);
    if (userId != null && userId > 0) {
      final db = await AppDatabase.instance.database;
      id = await db.insert('job_seeker_experiences', {
        'user_id': userId,
        'poste': poste,
        'entreprise': entreprise,
        'date_debut': dateDebut,
        'date_fin': dateFin,
        'en_cours': enCours ? 1 : 0,
        'description': description,
      });
    }

    final experience = JobExperience(
      id: id,
      poste: poste,
      entreprise: entreprise,
      dateDebut: dateDebut,
      dateFin: dateFin,
      enCours: enCours,
      description: description,
    );
    _currentUser = user.copyWith(experiences: [...user.experiences, experience]);
    notifyListeners();
  }

  /// Supprime l'expérience à [index] (ordre d'affichage de
  /// `JobProfileScreen`) du profil connecté.
  Future<void> deleteExperienceAt(int index) async {
    final user = _currentUser;
    if (user == null) return;
    if (index < 0 || index >= user.experiences.length) return;

    final experience = user.experiences[index];
    final updated = List<JobExperience>.from(user.experiences)..removeAt(index);
    _currentUser = user.copyWith(experiences: updated);
    notifyListeners();

    if (experience.id != null) {
      final db = await AppDatabase.instance.database;
      await db.delete('job_seeker_experiences', where: 'id = ?', whereArgs: [experience.id]);
    }
  }

  /// Vérifier si l'utilisateur est un employeur
  bool isEmployer() {
    return _currentUser?.role == 'employer';
  }

  /// Vérifier si l'utilisateur est un chercheur d'emploi
  bool isJobSeeker() {
    return _currentUser?.role == 'job_seeker';
  }

  /// `true` pour un compte de démo (`_demoAccounts`, id négatif, aucune
  /// ligne dans `users`) — ces comptes n'ont ni mot de passe modifiable ni
  /// ligne à supprimer, utilisé par `JobSeekerSettingsScreen` pour
  /// désactiver "Changer le mot de passe"/"Supprimer mon compte".
  bool get isDemoAccount {
    final userId = int.tryParse(_currentUser?.id ?? '');
    return userId != null && userId < 0;
  }

  /// Vérifie que [password] correspond bien au mot de passe actuel du
  /// compte connecté — utilisé par l'écran "Changer le mot de passe" avant
  /// d'appeler [resetPassword], pour ne jamais laisser quelqu'un déjà dans
  /// la session en changer le mot de passe sans le connaître.
  Future<bool> verifyCurrentPassword(String password) async {
    final user = _currentUser;
    if (user == null) return false;

    final demoAccount = _demoAccounts[user.email];
    if (demoAccount != null) {
      return demoAccount['password'] == password;
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['password_hash'] == hashPassword(password);
  }

  /// Supprime définitivement le compte connecté : la ligne `users`
  /// (entraîne, via `ON DELETE CASCADE`, la suppression du profil,
  /// compétences, modes de travail, expériences liés — et, pour un
  /// recruteur, ses offres avec en cascade candidatures / enregistrements /
  /// vues / notifications). Les tables qui référencent l'utilisateur par un
  /// `TEXT` sans clé étrangère (comptes de démo obligent) sont nettoyées à
  /// la main selon le rôle. Déconnecte ensuite la session. Renvoie `false`
  /// sans rien modifier pour un compte de démo (id négatif, aucune ligne
  /// `users` à supprimer).
  Future<bool> deleteAccount() async {
    final user = _currentUser;
    if (user == null) return false;

    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return false;

    final db = await AppDatabase.instance.database;
    if (user.role == 'employer') {
      // `job_offers` n'a pas de FK vers `users` (comptes de démo obligent,
      // voir `AppDatabase.onCreate`) — on supprime les offres à la main,
      // ce qui fait partir en cascade candidatures / enregistrements /
      // vues / états de notification (eux ont bien une FK vers
      // `job_offers`). `interviews` n'a aucune FK non plus.
      await db.delete('job_offers', where: 'employer_user_id = ?', whereArgs: [userId]);
      await db.delete('interviews', where: 'employer_user_id = ?', whereArgs: [userId]);
    } else {
      await db.delete('job_offer_saves', where: 'job_seeker_user_id = ?', whereArgs: [user.id]);
      await db.delete(
        'job_offer_notification_reads',
        where: 'job_seeker_user_id = ?',
        whereArgs: [user.id],
      );
      await db.delete('job_applications', where: 'job_seeker_user_id = ?', whereArgs: [user.id]);
      await db.delete('interviews', where: 'job_seeker_user_id = ?', whereArgs: [user.id]);
    }
    await db.delete('search_history', where: 'user_id = ?', whereArgs: [user.id]);
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);

    _currentUser = null;
    DisplayPreferencesController.instance.reset();
    await _clearPersistedSession();
    notifyListeners();
    return true;
  }
}