import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// Carte promotionnelle "Boostez vos opportunités" de la barre latérale.
class BoostCard extends StatelessWidget {
  const BoostCard({super.key, required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.dashboardCard),
        boxShadow: AppShadows.dashboardCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -6,
            child: Icon(
              Icons.rocket_launch_rounded,
              size: 90,
              color: AppColors.dashboardMauve.withValues(alpha: 0.16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boostez vos\nopportunités',
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 16,
                    height: 1.25,
                    color: AppColors.dashboardTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mettez en avant vos offres et toucher plus de candidats',
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.dashboardTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: AppColors.dashboardMauve,
                  borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
                    onTap: onDiscover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Text(
                        'Découvrir',
                        style: AppTextStyles.interSemiBold.copyWith(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
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