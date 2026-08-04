import 'package:flutter/material.dart';

/// Palette de couleurs de l'écran d'onboarding JOEM.
class OnboardingColors {
  const OnboardingColors._();

  static const Color navy = Color(0xFF12143A);
  static const Color violetDeep = Color(0xFF5B21B6);
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetLight = Color(0xFF8B5CF6);
  static const Color lavender = Color(0xFFEDE4FE);
  static const Color bgTop = Color(0xFFFBFAFE);
  static const Color bgBottom = Color(0xFFF3EEFD);
  static const Color textMuted = Color(0xFF6B6B85);
  static const Color baseline = Color(0xFF4A4A68);
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
  static const double divider = 0.020;
  static const double description = 0.125;
  static const double spacerSm = 0.029;
  static const double card = 0.087;

  /// Largeur minimale (dp) sous laquelle les grilles de points sont masquées.
  static const double dotGridMinWidth = 360;
}