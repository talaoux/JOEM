import 'package:flutter/material.dart';

/// Ombres de l'application JOEM
/// Système d'ombres cohérent et subtil
class AppShadows {
  // Ombre légère pour les cartes
  static const BoxShadow light = BoxShadow(
    color: Color(0x0A000000), // 4% opacity
    blurRadius: 8,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  // Ombre moyenne pour les cartes
  static const BoxShadow medium = BoxShadow(
    color: Color(0x14000000), // 8% opacity
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  // Ombre forte pour les éléments élevés
  static const BoxShadow strong = BoxShadow(
    color: Color(0x1F000000), // 12% opacity
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  // Ombre pour le bottom navigation
  static const BoxShadow bottomNav = BoxShadow(
    color: Color(0x14000000), // 8% opacity
    blurRadius: 20,
    offset: Offset(0, -4),
    spreadRadius: 0,
  );

  // Glow effect pour les boutons
  static const BoxShadow glow = BoxShadow(
    color: Color(0x406C63FF), // Violet avec 25% opacity
    blurRadius: 20,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );

  // Liste d'ombres pour les cartes
  static const List<BoxShadow> cardShadow = [light];
  static const List<BoxShadow> cardShadowMedium = [medium];
  static const List<BoxShadow> elevatedShadow = [strong];
  static const List<BoxShadow> bottomNavShadow = [bottomNav];
  static const List<BoxShadow> glowShadow = [glow];
}