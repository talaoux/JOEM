import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/theme/app_shadows.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? miniChart;

  /// Ouvre l'écran de détail du chiffre (`EmployerDashboard` : "Tableau de
  /// bord"). `null` = carte non cliquable.
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.miniChart,
    this.onTap,
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
    if (_isSmallScreen(context)) return 16;
    if (_isMediumScreen(context)) return 18;
    return 20;
  }
  
  /// Taille du conteneur d'icône responsive
  double _getIconContainerSize(BuildContext context) {
    if (_isSmallScreen(context)) return 28;
    if (_isMediumScreen(context)) return 32;
    return 36;
  }
  
  /// Taille de police pour la valeur responsive
  double _getValueFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 18;
    if (_isMediumScreen(context)) return 20;
    return 22;
  }
  
  /// Taille de police pour le titre responsive
  double _getTitleFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 9;
    if (_isMediumScreen(context)) return 10;
    return 11;
  }
  
  /// Taille de police pour le mini chart responsive
  double _getMiniChartFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 8;
    if (_isMediumScreen(context)) return 9;
    return 10;
  }
  
  /// Padding responsive
  double _getCardPadding(BuildContext context) {
    if (_isSmallScreen(context)) return 12;
    if (_isMediumScreen(context)) return 16;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = _getIconSize(context);
        final iconContainerSize = _getIconContainerSize(context);
        final valueFontSize = _getValueFontSize(context);
        final titleFontSize = _getTitleFontSize(context);
        final miniChartFontSize = _getMiniChartFontSize(context);
        final cardPadding = _getCardPadding(context);
        final colors = AppSurfaceColors.of(context);

        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: AppRadius.statCardRadius,
            boxShadow: AppShadows.cardShadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: AppRadius.statCardRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icône et valeur sur la même ligne pour économiser l'espace
              Row(
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(iconContainerSize * 0.3),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: colors.statNumber.copyWith(
                        fontSize: valueFontSize,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Titre
              Text(
                title,
                style: colors.statLabel.copyWith(
                  fontSize: titleFontSize,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Mini graphique (optionnel)
              if (miniChart != null) ...[
                const SizedBox(height: 2),
                Text(
                  miniChart!,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: miniChartFontSize,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}