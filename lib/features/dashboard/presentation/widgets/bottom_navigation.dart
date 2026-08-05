import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/widgets/notification_badge.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int notificationCount;

  /// Surcharge la couleur d'accent par défaut (`AppColors.primary`, mauve
  /// dashboard) — le dashboard chercheur d'emploi lui passe le violet de
  /// l'onboarding, le dashboard employeur ne passe rien et garde le mauve.
  final Color? accentColor;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
    this.accentColor,
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
    if (_isSmallScreen(context)) return 20;
    if (_isMediumScreen(context)) return 22;
    return 24;
  }
  
  /// Taille de police pour le label responsive
  double _getLabelFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 9;
    if (_isMediumScreen(context)) return 10;
    return 11;
  }
  
  /// Padding horizontal responsive pour les items
  double _getItemHorizontalPadding(BuildContext context) {
    if (_isSmallScreen(context)) return 8;
    if (_isMediumScreen(context)) return 10;
    return 12;
  }
  
  /// Padding vertical responsive pour les items
  double _getItemVerticalPadding(BuildContext context) {
    if (_isSmallScreen(context)) return 6;
    if (_isMediumScreen(context)) return 8;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = _getIconSize(context);
        final labelFontSize = _getLabelFontSize(context);
        final itemHorizontalPadding = _getItemHorizontalPadding(context);
        final itemVerticalPadding = _getItemVerticalPadding(context);
        
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: AppShadows.bottomNavShadow,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Accueil',
                    index: 0,
                    isActive: currentIndex == 0,
                    iconSize: iconSize,
                    labelFontSize: labelFontSize,
                    itemHorizontalPadding: itemHorizontalPadding,
                    itemVerticalPadding: itemVerticalPadding,
                  ),
                  _buildNavItem(
                    icon: Icons.category_rounded,
                    label: 'Catégorie',
                    index: 1,
                    isActive: currentIndex == 1,
                    iconSize: iconSize,
                    labelFontSize: labelFontSize,
                    itemHorizontalPadding: itemHorizontalPadding,
                    itemVerticalPadding: itemVerticalPadding,
                  ),
                  _buildNavItem(
                    icon: Icons.post_add_rounded,
                    label: 'Publier',
                    index: 2,
                    isActive: currentIndex == 2,
                    iconSize: iconSize,
                    labelFontSize: labelFontSize,
                    itemHorizontalPadding: itemHorizontalPadding,
                    itemVerticalPadding: itemVerticalPadding,
                  ),
                  _buildNavItem(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    index: 3,
                    isActive: currentIndex == 3,
                    iconSize: iconSize,
                    labelFontSize: labelFontSize,
                    itemHorizontalPadding: itemHorizontalPadding,
                    itemVerticalPadding: itemVerticalPadding,
                    badgeCount: notificationCount,
                  ),
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    index: 4,
                    isActive: currentIndex == 4,
                    iconSize: iconSize,
                    labelFontSize: labelFontSize,
                    itemHorizontalPadding: itemHorizontalPadding,
                    itemVerticalPadding: itemVerticalPadding,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required double iconSize,
    required double labelFontSize,
    required double itemHorizontalPadding,
    required double itemVerticalPadding,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: itemHorizontalPadding,
          vertical: itemVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (accentColor ?? AppColors.primary).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: AppRadius.bottomNavPillRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotificationBadge(
              count: badgeCount,
              child: Icon(
                icon,
                color: isActive ? (accentColor ?? AppColors.primary) : const Color(0xFF9CA3AF),
                size: iconSize,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: isActive
                  ? AppTypography.navLabelActive.copyWith(fontSize: labelFontSize)
                  : AppTypography.navLabel.copyWith(fontSize: labelFontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}