import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/widgets/notification_badge.dart';
import 'search_bar_widget.dart';
import 'soft_ui.dart';

/// En-tête du dashboard recruteur : barre de recherche de candidats +
/// notification + logo entreprise — équivalent recruteur de
/// `JobSeekerHeader`, mais qui cherche des profils, pas des offres.
class EmployerHeader extends StatelessWidget {
  final TextEditingController controller;
  final int notificationCount;
  final VoidCallback? onLogoTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  /// Logo réellement choisi à l'inscription — prioritaire sur l'icône par
  /// défaut quand il est renseigné.
  final Uint8List? logoBytes;

  const EmployerHeader({
    super.key,
    required this.controller,
    this.notificationCount = 0,
    this.onLogoTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.logoBytes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeAreaHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Barre de recherche de candidats
          Expanded(
            child: SearchBarWidget(
              controller: controller,
              showFilterButton: false,
              readOnly: onSearchTap != null,
              onTap: onSearchTap,
              hintText: 'Rechercher un candidat...',
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Notification
          NotificationBadge(
            count: notificationCount,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.background,
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider, width: 1),
              ),
              child: IconButton(
                onPressed: onNotificationTap,
                icon: Icon(
                  Icons.notifications_outlined,
                  color: colors.textPrimary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Logo entreprise
          GestureDetector(
            onTap: onLogoTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: SoftUi.tint(colors, DashboardColors.accent),
              backgroundImage: logoBytes != null
                  ? MemoryImage(logoBytes!) as ImageProvider
                  : null,
              child: logoBytes == null
                  ? Icon(
                      Icons.business_rounded,
                      color: SoftUi.brandInk(colors),
                      size: 20,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
