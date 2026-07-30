import 'package:flutter/foundation.dart';

/// Modèle d'utilisateur
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'job_seeker' ou 'employer'
  final String? companyName;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.companyName,
  });
}

/// Service d'authentification
class AuthService extends ChangeNotifier {
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

  /// Connexion
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    final account = _demoAccounts[email];

    if (account != null && account['password'] == password) {
      _currentUser = account['user'] as User;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
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