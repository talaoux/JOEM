import 'package:flutter/material.dart';

/// Palette de l'accueil, de la connexion, des wizards d'inscription et du
/// splash — bleu océan, mêmes valeurs que `DashboardColors` (espaces
/// candidat/recruteur) et que le thème "Bleu océan" du Portfolio. Ancienne
/// palette violette : violet `0xFF7C3AED`, violetDeep `0xFF5B21B6`,
/// violetLight `0xFF8B5CF6`, lavender `0xFFEDE4FE`.
class OnboardingColors {
  const OnboardingColors._();

  /// Bleu nuit des textes forts et du début du dégradé du logo.
  static const Color navy = Color(0xFF0F1B3D);

  /// Bleu nuit (ancien `violetDeep`).
  static const Color accentDeep = Color(0xFF1E3A8A);

  /// Accent principal (ancien `violet`).
  static const Color accent = Color(0xFF3B82F6);

  /// Bleu clair (ancien `violetLight`).
  static const Color accentLight = Color(0xFF60A5FA);

  /// Texte des éléments teintés (pilules, étapes du wizard).
  static const Color ink = Color(0xFF1D4ED8);

  /// Teinte très pâle (ancien `lavender`).
  static const Color tint = Color(0xFFDBEAFE);

  static const Color bgTop = Color(0xFFF7FAFF);
  static const Color bgBottom = Color(0xFFEAF1FD);
  static const Color textMuted = Color(0xFF64748B);
  static const Color baseline = Color(0xFF475569);
}

/// Répartition verticale (en fraction de la hauteur disponible) de
/// l'écran d'onboarding. La somme des blocs fixes + le pied de page
/// (calculé en `Expanded`) fait 100 % de la hauteur, garantissant un
/// rendu sans scroll.
class OnboardingLayout {
  const OnboardingLayout._();

  static const double hero = 0.30;
  static const double heroToBrandGap = 0.006;
  static const double spacerXs = 0.019;
  static const double brandToTitleGap = 0.008;
  static const double brand = 0.106;
  static const double title = 0.115;
  static const double divider = 0.011;
  static const double description = 0.098;
  static const double spacerSm = 0.019;
  static const double card = 0.11;

  /// Largeur minimale (dp) sous laquelle les grilles de points sont masquées.
  static const double dotGridMinWidth = 360;
}