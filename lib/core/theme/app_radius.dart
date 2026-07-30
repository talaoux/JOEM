import 'package:flutter/material.dart';

/// Rayons de l'application JOEM
/// Valeurs cohérentes pour tous les coins
class AppRadius {
  // Rayons standards
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 22.0;
  static const double xl = 24.0;
  static const double xxl = 26.0;
  static const double xxxl = 28.0;

  // Rayons spécifiques
  static const double searchBar = 24.0;
  static const double card = 28.0;
  static const double categoryCard = 22.0;
  static const double statCard = 26.0;
  static const double bottomNavPill = 20.0;

  // Helper pour BorderRadius
  static BorderRadius get searchBarRadius => BorderRadius.circular(searchBar);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get categoryCardRadius => BorderRadius.circular(categoryCard);
  static BorderRadius get statCardRadius => BorderRadius.circular(statCard);
  static BorderRadius get bottomNavPillRadius => BorderRadius.circular(bottomNavPill);
}