import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// Top bar of the Espace Employeur dashboard: JOEM logo on the left,
/// notification bell (with unread badge) and user avatar/menu on the
/// right — same logo, size and position as the Welcome Screen.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userInitial,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onProfileTap,
  });

  final String userInitial;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/images/joem_logo.png', height: 40),
        const Spacer(),
        _NotificationBell(count: notificationCount, onTap: onNotificationTap),
        const SizedBox(width: 12),
        _ProfileMenu(initial: userInitial, onTap: onProfileTap),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dashboardSurfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.dashboardTextPrimary,
                size: 22,
              ),
              if (count > 0)
                Positioned(
                  top: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.dashboardMauveDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.interSemiBold.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.initial, this.onTap});

  final String initial;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/avatar_portfolio1.jpg'),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.dashboardTextMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}