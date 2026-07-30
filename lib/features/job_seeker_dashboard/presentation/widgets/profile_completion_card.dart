import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/dashboard_card.dart';

/// Carte "Complétez votre profil" avec barre de progression et
/// pourcentage (voir maquette_employeur.png).
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  /// Valeur entre 0.0 et 1.0.
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return DashboardCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.dashboardMauveLightest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.dashboardMauveDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complétez votre profil',
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 14,
                    color: AppColors.dashboardTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Un profil complet augmente vos chances de trouver le bon emploi',
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 12,
                    color: AppColors.dashboardTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.dashboardMauveLightest,
                          valueColor: const AlwaysStoppedAnimation(AppColors.dashboardMauve),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$percent%',
                      style: AppTextStyles.interSemiBold.copyWith(
                        fontSize: 12,
                        color: AppColors.dashboardMauveDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.dashboardTextMuted,
          ),
        ],
      ),
    );
  }
}