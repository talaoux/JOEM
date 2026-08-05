import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/widgets/notification_badge.dart';
import 'search_bar_widget.dart';

class JobSeekerHeader extends StatelessWidget {
  final TextEditingController controller;
  final int notificationCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearchTap;

  const JobSeekerHeader({
    super.key,
    required this.controller,
    this.notificationCount = 0,
    this.onAvatarTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
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
            child: const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(
                'assets/images/avatar_portfolio1.jpg',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
