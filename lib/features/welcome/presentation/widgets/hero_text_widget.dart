import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Section Hero Text avec slogan principal
/// Animation: Slide Up + Fade
class HeroTextWidget extends StatelessWidget {
  final Animation<double> animation;

  const HeroTextWidget({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Animation Slide Up + Fade
        final slideValue = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ).drive(Tween<double>(begin: 30, end: 0));

        final fadeValue = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ).drive(Tween<double>(begin: 0.0, end: 1.0));

        return FadeTransition(
          opacity: fadeValue,
          child: Transform.translate(
            offset: Offset(0, slideValue.value),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Slogan principal - centré
          SizedBox(
            width: double.infinity,
            child: Text(
              'Une application qui\nconnecte tout le marché\nde l\'emploi malgache',
              style: AppTextStyles.heroTitle.copyWith(
                fontSize: 26,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Petit trait divider - centré
          Center(
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Description - centrée
          SizedBox(
            width: double.infinity,
            child: Text(
              'Bienvenue sur JOEM (Job Mada).\n'
              'L\'application exclusive pour l\'emploi à Madagascar.',
              style: AppTextStyles.description,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          // Tagline colorée - centrée
          SizedBox(
            width: double.infinity,
            child: Text(
              'Trouvez. Postulez. Réussissez.',
              style: AppTextStyles.tagline,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
