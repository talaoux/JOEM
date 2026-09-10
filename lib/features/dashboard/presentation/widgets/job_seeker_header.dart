import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/widgets/notification_badge.dart';
import 'search_bar_widget.dart';

class JobSeekerHeader extends StatelessWidget {
  final TextEditingController controller;
  final int notificationCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  /// Photo réellement choisie à l'inscription — prioritaire sur l'avatar
  /// par défaut quand elle est renseignée.
  final Uint8List? avatarBytes;

  const JobSeekerHeader({
    super.key,
    required this.controller,
    this.notificationCount = 0,
    this.onAvatarTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.avatarBytes,
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
          // Barre de recherche
          Expanded(
            child: SearchBarWidget(
              controller: controller,
              showFilterButton: false,
              readOnly: onSearchTap != null,
              onTap: onSearchTap,
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

          // Photo utilisateur
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 20,
              backgroundImage: avatarBytes != null
                  ? MemoryImage(avatarBytes!) as ImageProvider
                  : const AssetImage('assets/images/avatar_portfolio1.jpg'),
            ),
          ),
        ],
      ),
    );
  }
}
