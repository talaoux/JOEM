import 'package:flutter/material.dart';


/// Un thème de couleur pour le Portfolio candidat — pilote le dégradé
/// "hero" de `CandidateFullPortfolioScreen` (arrière-plan derrière l'avatar,
/// modifiable par le candidat via l'icône palette, en mode aperçu
/// uniquement) et les accents de `PortfolioScreen`/`CandidateFullPortfolioScreen`
/// (boutons, badges, icônes, puces de compétences/technologies...). [key]
/// est la valeur persistée (`job_seeker_profiles.portfolio_theme_color`,
/// `User.portfolioThemeColor`/`CandidateSearchResult.portfolioThemeColor`) —
/// le choix du candidat est donc visible à l'identique par un recruteur qui
/// consulte le même portfolio.
class PortfolioHeroTheme {
  const PortfolioHeroTheme({
    required this.key,
    required this.label,
    required this.gradient,
    required this.accent,
    required this.accentDeep,
    required this.tint,
  });

  final String key;
  final String label;

  /// Dégradé du hero, du plus sombre (haut/coin) au plus clair.
  final List<Color> gradient;

  /// Accent principal (ancien violet de l'onboarding).
  final Color accent;

  /// Accent plus sombre (ancien violet foncé de l'onboarding).
  final Color accentDeep;

  /// Teinte claire pour puces/badges (ancienne lavande de l'onboarding).
  final Color tint;

  static const PortfolioHeroTheme violet = PortfolioHeroTheme(
    key: 'violet',
    label: 'Violet',
    // Valeurs figées : l'app est passée au bleu océan, mais ce thème reste
    // un vrai violet (ancienne palette `OnboardingColors`).
    gradient: [Color(0xFF12143A), Color(0xFF5B21B6), Color(0xFF7C3AED)],
    accent: Color(0xFF7C3AED),
    accentDeep: Color(0xFF5B21B6),
    tint: Color(0xFFEDE4FE),
  );

  static const PortfolioHeroTheme ocean = PortfolioHeroTheme(
    key: 'ocean',
    label: 'Bleu océan',
    gradient: [Color(0xFF0B1220), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    accent: Color(0xFF3B82F6),
    accentDeep: Color(0xFF1E3A8A),
    tint: Color(0xFFDBEAFE),
  );

  static const PortfolioHeroTheme emerald = PortfolioHeroTheme(
    key: 'emerald',
    label: 'Vert émeraude',
    gradient: [Color(0xFF042F2A), Color(0xFF047857), Color(0xFF10B981)],
    accent: Color(0xFF10B981),
    accentDeep: Color(0xFF047857),
    tint: Color(0xFFD1FAE5),
  );

  static const PortfolioHeroTheme amber = PortfolioHeroTheme(
    key: 'amber',
    label: 'Ambre',
    gradient: [Color(0xFF451A03), Color(0xFFC2410C), Color(0xFFF97316)],
    accent: Color(0xFFF97316),
    accentDeep: Color(0xFFC2410C),
    tint: Color(0xFFFFEDD5),
  );

  static const PortfolioHeroTheme rose = PortfolioHeroTheme(
    key: 'rose',
    label: 'Rose',
    gradient: [Color(0xFF500724), Color(0xFFBE185D), Color(0xFFEC4899)],
    accent: Color(0xFFEC4899),
    accentDeep: Color(0xFFBE185D),
    tint: Color(0xFFFCE7F3),
  );

  static const PortfolioHeroTheme graphite = PortfolioHeroTheme(
    key: 'graphite',
    label: 'Graphite',
    gradient: [Color(0xFF0B0F19), Color(0xFF374151), Color(0xFF6B7280)],
    accent: Color(0xFF6B7280),
    accentDeep: Color(0xFF374151),
    tint: Color(0xFFE5E7EB),
  );

  static const List<PortfolioHeroTheme> all = [
    violet,
    ocean,
    emerald,
    amber,
    rose,
    graphite,
  ];

  /// Résout un thème depuis sa clé persistée — `null`/inconnue retombe sur
  /// [violet] (comportement historique de `CandidateFullPortfolioScreen`
  /// avant l'ajout de ce choix).
  static PortfolioHeroTheme resolve(String? key) {
    // Bleu océan par défaut : couleur de toute l'app côté dashboards.
    if (key == null) return ocean;
    return all.firstWhere((theme) => theme.key == key, orElse: () => ocean);
  }

  LinearGradient toLinearGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(begin: begin, end: end, colors: gradient);
  }
}
