import 'package:flutter/foundation.dart';

/// Préférences d'affichage du candidat connecté (`JobSeekerSettingsScreen`,
/// section "Affichage") — singleton `ChangeNotifier` séparé d'`AuthService`
/// pour que `JOEMApp` (racine de l'arbre de widgets, dans `main.dart`)
/// puisse s'y abonner directement sans dépendre de toute la logique
/// d'authentification. `AuthService` reste la seule source de vérité
/// persistée (`job_seeker_profiles`) ; ce contrôleur n'est qu'un miroir en
/// mémoire de la session en cours, remis à zéro à la déconnexion
/// (`AuthService.logout`/`deleteAccount`) pour qu'un compte employeur
/// connecté ensuite sur le même appareil reparte toujours en affichage par
/// défaut.
class DisplayPreferencesController extends ChangeNotifier {
  DisplayPreferencesController._internal();

  static final DisplayPreferencesController instance = DisplayPreferencesController._internal();

  bool _isDarkMode = false;
  bool _isLargeText = false;
  bool _reducedAnimations = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLargeText => _isLargeText;
  bool get reducedAnimations => _reducedAnimations;

  /// Facteur appliqué au `MediaQuery.textScaler` de tout l'arbre
  /// (`JOEMApp`, voir `main.dart`) quand [isLargeText] est actif.
  static const double largeTextScaleFactor = 1.15;

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }

  void setLargeText(bool value) {
    if (_isLargeText == value) return;
    _isLargeText = value;
    notifyListeners();
  }

  void setReducedAnimations(bool value) {
    if (_reducedAnimations == value) return;
    _reducedAnimations = value;
    notifyListeners();
  }

  /// Applique en une fois les trois préférences d'un compte qui vient de se
  /// connecter (`AuthService.login`/`restoreSession`/`loginWithGoogle`/
  /// `setSession`) — évite trois notifications séparées au démarrage.
  void syncFrom({
    required bool isDarkMode,
    required bool isLargeText,
    required bool reducedAnimations,
  }) {
    if (_isDarkMode == isDarkMode &&
        _isLargeText == isLargeText &&
        _reducedAnimations == reducedAnimations) {
      return;
    }
    _isDarkMode = isDarkMode;
    _isLargeText = isLargeText;
    _reducedAnimations = reducedAnimations;
    notifyListeners();
  }

  /// Remet l'affichage par défaut — appelé à la déconnexion.
  void reset() => syncFrom(isDarkMode: false, isLargeText: false, reducedAnimations: false);
}
