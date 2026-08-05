import 'package:flutter/foundation.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/utils/password_hasher.dart';

/// Modèle d'utilisateur
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'job_seeker' ou 'employer'
  final String? companyName;

  /// Titre professionnel du chercheur d'emploi (ex: "Développeur Flutter"),
  /// saisi à l'étape "Info" de l'inscription.
  final String? position;

  /// Photo de profil choisie à l'étape "Info" de l'inscription (`null` si
  /// aucune n'a été sélectionnée).
  final Uint8List? photoBytes;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.companyName,
    this.position,
    this.photoBytes,
  });
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

  /// Comptes de démonstration
  static final Map<String, Map<String, dynamic>> _demoAccounts = {
    'employeur@gmail.com': {
      'password': 'employeur123@gmail.com',
      'user': User(
        id: '1',
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
        id: '2',
        email: 'candidat@gmail.com',
        firstName: 'Marie',
        lastName: 'Martin',
        role: 'job_seeker',
      ),
    },
  };

  /// Connexion — vérifie d'abord les comptes de démo codés en dur, puis
  /// les comptes créés localement via un wizard d'inscription (SQLite).
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    final demoAccount = _demoAccounts[email];
    if (demoAccount != null && demoAccount['password'] == password) {
      _currentUser = demoAccount['user'] as User;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    final dbUser = await _loginFromDatabase(email, password);
    if (dbUser != null) {
      _currentUser = dbUser;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<User?> _loginFromDatabase(String email, String password) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.first;
    if (row['password_hash'] != hashPassword(password)) return null;

    final userId = row['id'] as int;
    final role = row['role'] as String;

    if (role == 'job_seeker') {
      final profileRows = await db.query(
        'job_seeker_profiles',
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
        position: profile?['titre_professionnel'] as String?,
        photoBytes: profile?['photo'] as Uint8List?,
      );
    }

    return User(id: userId.toString(), email: email, firstName: '', lastName: '', role: role);
  }

  /// Ouvre directement une session pour [user] — utilisé juste après une
  /// inscription réussie pour envoyer l'utilisateur sur son dashboard
  /// sans lui refaire saisir ses identifiants.
  void setSession(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Déconnexion
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
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