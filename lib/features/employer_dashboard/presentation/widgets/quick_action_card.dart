import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/dashboard_card.dart';

/// One cell of the "Actions rapides" 2x2 grid: white card, mauve icon,
/// title (Publier une offre / Mes offres / Candidats / Calendrier).
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.dashboardMauveLightest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.dashboardMauveDark, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.interSemiBold.copyWith(
              fontSize: 14,
              color: AppColors.dashboardTextPrimary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}