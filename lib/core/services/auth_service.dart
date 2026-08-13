import 'package:flutter/foundation.dart';

import 'package:joem/core/database/app_database.dart';
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
  });

  /// Copie l'utilisateur avec une nouvelle photo — utilisé par
  /// `AuthService.updateProfilePhoto` pour propager un changement d'avatar
  /// à tout le reste de l'app (header, panneau latéral, etc.) sans
  /// resaisir les autres champs.
  User copyWithPhoto(Uint8List photoBytes) {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      companyName: companyName,
      categorieEntreprise: categorieEntreprise,
      position: position,
      photoBytes: photoBytes,
      telephone: telephone,
      localisation: localisation,
      presentation: presentation,
      cvPath: cvPath,
      cvFileName: cvFileName,
      tarifJournalier: tarifJournalier,
      disponibilite: disponibilite,
      skills: skills,
      workModes: workModes,
      experiences: experiences,
    );
  }

  /// Copie l'utilisateur avec une nouvelle liste d'expériences — utilisé
  /// par `AuthService.addExperience`/`deleteExperienceAt`.
  User copyWithExperiences(List<JobExperience> experiences) {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      companyName: companyName,
      categorieEntreprise: categorieEntreprise,
      position: position,
      photoBytes: photoBytes,
      telephone: telephone,
      localisation: localisation,
      presentation: presentation,
      cvPath: cvPath,
      cvFileName: cvFileName,
      tarifJournalier: tarifJournalier,
      disponibilite: disponibilite,
      skills: skills,
      workModes: workModes,
      experiences: experiences,
    );
  }

  /// Copie l'utilisateur avec un nouveau CV — utilisé par
  /// `AuthService.updateCv`.
  User copyWithCv({required String cvPath, required String cvFileName}) {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      companyName: companyName,
      categorieEntreprise: categorieEntreprise,
      position: position,
      photoBytes: photoBytes,
      telephone: telephone,
      localisation: localisation,
      presentation: presentation,
      cvPath: cvPath,
      cvFileName: cvFileName,
      tarifJournalier: tarifJournalier,
      disponibilite: disponibilite,
      skills: skills,
      workModes: workModes,
      experiences: experiences,
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
        await _persistSession(email);
        return true;
      }

      final dbUser = await _loginFromDatabase(email, password);
      if (dbUser != null) {
        _currentUser = dbUser;
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
      notifyListeners();
      return true;
    }

    final user = await _loadUserByEmail(email);
    if (user == null) {
      await _clearPersistedSession();
      return false;
    }
    _currentUser = user;
    notifyListeners();
    return true;
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
          'presentation', 'photo', 'cv_path', 'cv_file_name', 'tarif_journalier', 'disponibilite',
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
        telephone: profile?['telephone'] as String?,
        localisation: profile?['localisation'] as String?,
        presentation: profile?['presentation'] as String?,
        cvPath: profile?['cv_path'] as String?,
        cvFileName: profile?['cv_file_name'] as String?,
        tarifJournalier: profile?['tarif_journalier'] as String?,
        disponibilite: profile?['disponibilite'] as String?,
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
        telephone: profile?['telephone'] as String?,
        localisation: profile?['localisation'] as String?,
        presentation: profile?['description'] as String?,
      );
    }

    return User(id: userId.toString(), email: email, firstName: '', lastName: '', role: role);
  }

  /// Ouvre directement une session pour [user] — utilisé juste après une
  /// inscription réussie pour envoyer l'utilisateur sur son dashboard
  /// sans lui refaire saisir ses identifiants.
  Future<void> setSession(User user) async {
    _currentUser = user;
    notifyListeners();
    await _persistSession(user.email);
  }

  /// Déconnexion
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
    await _clearPersistedSession();
    _isLoading = false;
    notifyListeners();
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

    _currentUser = user.copyWithPhoto(photoBytes);
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

  /// Change le CV (PDF ou image) du chercheur d'emploi connecté et le
  /// persiste (compte inscrit via le wizard) ou le garde en mémoire pour
  /// la session (comptes de démo, id négatif).
  Future<void> updateCv({required Uint8List cvBytes, required String cvFileName}) async {
    final user = _currentUser;
    if (user == null) return;

    final cvPath = await saveCvFile(cvBytes, cvFileName);

    _currentUser = user.copyWithCv(cvPath: cvPath, cvFileName: cvFileName);
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
    _currentUser = user.copyWithExperiences([...user.experiences, experience]);
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
    _currentUser = user.copyWithExperiences(updated);
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
}