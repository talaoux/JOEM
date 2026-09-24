import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';

import 'soft_ui.dart';

/// Tuile de catégorie — style "nouveau design" : carte blanche à fine
/// bordure, pastille ronde teintée, libellé discret.
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

  bool _isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 360;

  bool _isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 390;
  }

  double _getIconSize(BuildContext context) {
    if (_isSmallScreen(context)) return 18;
    if (_isMediumScreen(context)) return 20;
    return 21;
  }

  double _getIconContainerSize(BuildContext context) {
    if (_isSmallScreen(context)) return 36;
    if (_isMediumScreen(context)) return 40;
    return 42;
  }

  double _getTitleFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 9.5;
    if (_isMediumScreen(context)) return 10.5;
    return 11;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final iconContainerSize = _getIconContainerSize(context);
    return SoftCard(
      radius: 20,
      padding: EdgeInsets.all(_isSmallScreen(context) ? 6 : 8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: SoftUi.tint(colors, DashboardColors.accent),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SoftUi.brandInk(colors), size: _getIconSize(context)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTypography.interMedium.copyWith(
              fontSize: _getTitleFontSize(context),
              color: colors.textPrimary,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            // 2 lignes pour les noms longs ("BPO & Centres d'appels",
            // "Ressources Humaines"...) ; les noms courts restent sur une.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
