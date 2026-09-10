import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Palette de "chrome" (fond de page, fond de carte, texte) du parcours
/// chercheur d'emploi, dynamique selon le "Mode nuit" de
/// `JobSeekerSettingsScreen` — contrairement à `AppColors` (fixe, utilisée
/// par le reste de l'app : login, wizards, dashboard employeur), ces
/// valeurs sont attachées à `ThemeData.extensions` (voir `main.dart`) et se
/// relisent via [AppSurfaceColors.of], qui se met à jour automatiquement
/// partout où elle est utilisée dès que `ThemeModeController` bascule.
///
/// [light] reprend exactement les valeurs `AppColors.background/surface/
/// textPrimary/textSecondary` existantes : un écran qui passe de
/// `AppColors.x` à `AppSurfaceColors.of(context).x` ne change donc rien à
/// son rendu tant que le mode nuit est désactivé (le cas par défaut, et le
/// seul cas pour tout le reste de l'app qui ne lit jamais cette extension).
@immutable
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  const AppSurfaceColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });

  /// Fond des cartes/panneaux — `AppColors.background` en clair.
  final Color background;

  /// Fond de page — `AppColors.surface` en clair.
  final Color surface;

  final Color textPrimary;
  final Color textSecondary;

  /// `AppColors.textTertiary` en clair — libellés discrets (dates, méta-infos).
  final Color textTertiary;
  final Color divider;

  static const light = AppSurfaceColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF9FAFB),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    divider: Color(0xFFEDEDF3),
  );

  static const dark = AppSurfaceColors(
    background: Color(0xFF1C1C27),
    surface: Color(0xFF121218),
    textPrimary: Color(0xFFF2F2F5),
    textSecondary: Color(0xFFA3A3B0),
    textTertiary: Color(0xFF7D7D8C),
    divider: Color(0xFF2E2E3B),
  );

  /// Retombe sur [light] si aucune extension n'est attachée au thème actif
  /// (ne devrait pas arriver, `main.dart` en attache toujours une) plutôt
  /// que de lever une exception.
  static AppSurfaceColors of(BuildContext context) {
    return Theme.of(context).extension<AppSurfaceColors>() ?? light;
  }

  @override
  AppSurfaceColors copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
  }) {
    return AppSurfaceColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) return this;
    return AppSurfaceColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// Variantes des styles `AppTypography` avec la couleur de texte recalée
/// sur [AppSurfaceColors.textPrimary]/[AppSurfaceColors.textSecondary] —
/// évite de répéter `AppTypography.x.copyWith(color: colors.y)` à chaque
/// écran du parcours candidat qui bascule vers cette palette dynamique.
extension AppSurfaceTextStyles on AppSurfaceColors {
  TextStyle get dashboardTitle => AppTypography.dashboardTitle.copyWith(color: textPrimary);
  TextStyle get sectionTitle => AppTypography.sectionTitle.copyWith(color: textPrimary);
  TextStyle get cardTitle => AppTypography.cardTitle.copyWith(color: textPrimary);
  TextStyle get cardDescription => AppTypography.cardDescription.copyWith(color: textSecondary);
  TextStyle get statNumber => AppTypography.statNumber.copyWith(color: textPrimary);
  TextStyle get statLabel => AppTypography.statLabel.copyWith(color: textSecondary);
  TextStyle get categoryTitle => AppTypography.categoryTitle.copyWith(color: textPrimary);
  TextStyle get jobTitle => AppTypography.jobTitle.copyWith(color: textPrimary);
  TextStyle get companyName => AppTypography.companyName.copyWith(color: textSecondary);
  TextStyle get jobInfo => AppTypography.jobInfo.copyWith(color: textTertiary);
  TextStyle get adviceTitle => AppTypography.adviceTitle.copyWith(color: textPrimary);
  TextStyle get adviceText => AppTypography.adviceText.copyWith(color: textSecondary);
  TextStyle get navLabel => AppTypography.navLabel.copyWith(color: textTertiary);
  TextStyle get dashboardSubtitle => AppTypography.dashboardSubtitle.copyWith(color: textPrimary);
}
