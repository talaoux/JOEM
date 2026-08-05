import 'package:flutter/material.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';

class HeroCard extends StatelessWidget {
  final VoidCallback onFindJobTap;

  const HeroCard({super.key, required this.onFindJobTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [OnboardingColors.lavender, OnboardingColors.violetLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            // Contenu texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trouvez votre prochain emploi',
                    style: AppTypography.dashboardTitle.copyWith(
                      fontSize: 22,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Découvrez les meilleures opportunités adaptées à votre profil.',
                    style: AppTypography.cardDescription.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: onFindJobTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OnboardingColors.violet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Trouver un emploi',
                      style: AppTypography.primaryButton.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Illustration discrète
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 60,
                color: OnboardingColors.violet.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}