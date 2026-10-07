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
  double _textScale = 1.0;
  bool _reducedAnimations = false;

  bool get isDarkMode => _isDarkMode;
  double get textScale => _textScale;
  bool get reducedAnimations => _reducedAnimations;

  /// Pour compatibilité avec le code existant
  bool get isLargeText => _textScale > 1.0;
  double get largeTextScaleFactor => _textScale;

  /// Plage de valeurs pour le curseur de taille de texte (0.85 à 1.3)
  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.3;
  static const double defaultTextScale = 1.0;

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }

  void setTextScale(double value) {
    if (_textScale == value) return;
    _textScale = value.clamp(minTextScale, maxTextScale);
    notifyListeners();
  }

  /// Pour compatibilité avec le code existant
  void setLargeText(bool value) {
    setTextScale(value ? 1.15 : 1.0);
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
    required double textScale,
    required bool reducedAnimations,
  }) {
    if (_isDarkMode == isDarkMode &&
        _textScale == textScale &&
        _reducedAnimations == reducedAnimations) {
      return;
    }
    _isDarkMode = isDarkMode;
    _textScale = textScale.clamp(minTextScale, maxTextScale);
    _reducedAnimations = reducedAnimations;
    notifyListeners();
  }

  /// Remet l'affichage par défaut — appelé à la déconnexion.
  void reset() => syncFrom(isDarkMode: false, textScale: defaultTextScale, reducedAnimations: false);
}
