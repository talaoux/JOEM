import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/theme/app_shadows.dart';

class AdviceCard extends StatelessWidget {
  final String title;
  final String text;

  const AdviceCard({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
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
                  style: AppTypography.adviceTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: AppTypography.adviceText,
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
}