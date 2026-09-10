import 'package:flutter/material.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_shadows.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  /// Retourne true si l'écran est petit (< 360px)
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// Retourne true si l'écran est moyen (360-390px)
  bool _isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 390;
  }
  
  /// Taille d'icône responsive
  double _getIconSize(BuildContext context) {
    if (_isSmallScreen(context)) return 18;
    if (_isMediumScreen(context)) return 20;
    return 22;
  }
  
  /// Taille du conteneur d'icône responsive
  double _getIconContainerSize(BuildContext context) {
    if (_isSmallScreen(context)) return 36;
    if (_isMediumScreen(context)) return 40;
    return 44;
  }
  
  /// Taille de police pour le titre responsive
  double _getTitleFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 9;
    if (_isMediumScreen(context)) return 10;
    return 11;
  }
  
  /// Padding responsive
  double _getCardPadding(BuildContext context) {
    if (_isSmallScreen(context)) return 8;
    if (_isMediumScreen(context)) return 12;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = AppSurfaceColors.of(context);
        final iconSize = _getIconSize(context);
        final iconContainerSize = _getIconContainerSize(context);
        final titleFontSize = _getTitleFontSize(context);
        final cardPadding = _getCardPadding(context);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: AppRadius.categoryCardRadius,
              boxShadow: AppShadows.cardShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: OnboardingColors.violet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(iconContainerSize * 0.3),
                  ),
                  child: Icon(
                    icon,
                    color: OnboardingColors.violet,
                    size: iconSize,
                  ),
                ),

                const SizedBox(height: 4),

                // Titre
                Text(
                  title,
                  style: colors.categoryTitle.copyWith(
                    fontSize: titleFontSize,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}