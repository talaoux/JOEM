import 'package:flutter/material.dart';

/// Couleurs de l'application JOEM
/// Design System cohérent et réutilisable
class AppColors {
  // Couleur principale - Mauve doux JOEM
  static const Color primary = Color(0xFFA855F7);
  static const Color primaryLight = Color(0xFFC58AF9);
  static const Color primaryLighter = Color(0xFFD8B4FE);
  static const Color primaryLightest = Color(0xFFEAD8FF);
  static const Color primaryDark = Color(0xFF9333EA);
  static const Color secondary = Color(0xFFC58AF9);

  // Couleurs de fond (thème clair pour dashboard)
  static const Color background = Color(0xFFFFFFFF); // Blanc pur
  static const Color surface = Color(0xFFF9FAFB);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Couleurs de texte (thème clair)
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Couleurs d'overlay
  static const Color overlayTop = Color(0x73000000); // opacity 0.45
  static const Color overlayCenter = Color(0x33000000); // opacity 0.20
  static const Color overlayBottom = Color(0xD9000000); // opacity 0.85

  // Couleurs de glassmorphism
  static const Color glassBackground = Color(0x1AFFFFFF); // 10% opacity
  static const Color glassBorder = Color(0x33FFFFFF); // 20% opacity
  static const Color glassShadow = Color(0x406C63FF); // Violet avec 25% opacity
  static const Color glowPrimary = Color(0x406C63FF); // Violet glow
  static const Color glassFill = Color(0x1AFFFFFF); // 10% opacity

  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFC107);

  // Couleurs d'accentuation
  static const Color accentCyan = Color(0xFF00D9FF);
  static const Color accentPink = Color(0xFFFF6B9D);


  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      overlayTop,
      overlayCenter,
      overlayBottom,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Glassmorphism border
  static BorderRadius get glassBorderRadius => BorderRadius.circular(30);

  // Glassmorphism decoration
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: glassBackground,
    borderRadius: glassBorderRadius,
    border: Border.all(color: glassBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: glassShadow,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}