import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// Grande bannière "Trouvez le job qui vous correspond" en haut du
/// Dashboard Chercheur d'emploi — dégradé mauve clair, badge cible,
/// et bouton "Explorer les offres" (voir maquette_employeur.png).
class HeroBannerCard extends StatelessWidget {
  const HeroBannerCard({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.dashboardCard),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.dashboardMauveLightest, Color(0xFFF3E9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                Icons.public_rounded,
                size: 200,
                color: AppColors.dashboardMauve.withValues(alpha: 0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      color: AppColors.dashboardMauveDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Trouvez le job\nqui vous correspond',
                    style: AppTextStyles.poppinsExtraBold.copyWith(
                      fontSize: 26,
                      height: 1.25,
                      color: AppColors.dashboardTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Des milliers d'offres d'emploi\npartout à Madagascar",
                    style: AppTextStyles.interRegular.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.dashboardTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Material(
                    color: AppColors.dashboardMauve,
                    borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
                      onTap: onExplore,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explorer les offres',
                              style: AppTextStyles.interSemiBold.copyWith(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}