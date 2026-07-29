import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Reusable box-shadow recipes for the JOEM glassmorphism visuals.
class AppShadows {
  AppShadows._();

  /// Soft violet glow used behind primary buttons and active stepper circles.
  static List<BoxShadow> glow({Color color = AppColors.glowPrimary, double blurRadius = 20}) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: -4,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Soft black shadow used under glass cards/panels.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}
