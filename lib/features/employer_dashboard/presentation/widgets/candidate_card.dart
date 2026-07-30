import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/dashboard_card.dart';

/// One row of "Nouveaux candidats": round avatar (initial), name, job
/// title, city, experience and a "Voir profil" button.
class CandidateCard extends StatelessWidget {
  const CandidateCard({
    super.key,
    required this.name,
    required this.jobTitle,
    required this.city,
    required this.experience,
    required this.onViewProfile,
  });

  final String name;
  final String jobTitle;
  final String city;
  final String experience;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage('assets/images/avatar_portfolio1.jpg'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 15,
                    color: AppColors.dashboardTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  jobTitle,
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 13,
                    color: AppColors.dashboardTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$city · $experience',
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 12,
                    color: AppColors.dashboardTextMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onViewProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dashboardMauveDark,
              side: const BorderSide(color: AppColors.dashboardMauveLight),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
              ),
            ),
            child: Text(
              'Voir profil',
              style: AppTextStyles.interSemiBold.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}