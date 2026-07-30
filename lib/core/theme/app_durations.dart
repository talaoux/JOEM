import 'package:flutter/material.dart';

/// Durées et courbes d'animation de l'application JOEM
class AppDurations {
  // Durées standards
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration verySlow = Duration(milliseconds: 500);

  // Durées spécifiques selon la maquette
  static const Duration headerFade = Duration(milliseconds: 350);
  static const Duration searchBarSlide = Duration(milliseconds: 350);
  static const Duration heroFadeScale = Duration(milliseconds: 350);
  static const Duration statisticsStagger = Duration(milliseconds: 350);
  static const Duration categoriesFade = Duration(milliseconds: 350);
  static const Duration offersSlideUp = Duration(milliseconds: 350);
  static const Duration bottomNavFade = Duration(milliseconds: 350);
  static const Duration stepTransition = Duration(milliseconds: 350);

  // Courbes d'animation
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve easeOutQuad = Curves.easeOutQuad;
  static const Curve linear = Curves.linear;

  // Délais pour les animations stagger
  static const Duration staggerDelay = Duration(milliseconds: 50);
}