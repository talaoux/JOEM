import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_typography.dart';

import 'soft_ui.dart';

class AdviceCard extends StatelessWidget {
  final String title;
  final String text;

  /// Variante "nouveau design" (accueil recruteur) : bloc ambre pâle sans
  /// ombre, pastille blanche, titre serif. `false` = rendu d'origine
  /// (dashboard candidat, pas encore migré).
  final bool soft;

  /// Variante réduite de [soft] pour le panneau latéral candidat
  /// (`ProfileSidePanel`, sous "Profil complété") : marges, pastille et
  /// textes plus petits pour tenir dans sa largeur.
  final bool compact;

  const AdviceCard({
    super.key,
    required this.title,
    required this.text,
    this.soft = false,
    this.compact = false,
  });

  static const Color _amber = Color(0xFFC2780E);

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    if (soft || compact) return _buildSoft(colors);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          // Icône ampoule
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFFF59E0B),
              size: 26,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Contenu texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: colors.adviceTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: colors.adviceText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoft(AppSurfaceColors colors) {
    final amberInk = SoftUi.accentInk(colors, _amber);
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: SoftUi.isDark(colors) ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 32 : 44,
            height: compact ? 32 : 44,
            decoration: BoxDecoration(
              color: colors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: amberInk,
              size: compact ? 17 : 22,
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.frauncesBold.copyWith(
                    fontSize: compact ? 14.5 : 17,
                    color: colors.textPrimary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  text,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: compact ? 12 : 13,
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
