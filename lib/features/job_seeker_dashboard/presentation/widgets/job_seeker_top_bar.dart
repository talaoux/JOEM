import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// Top bar of the Dashboard Chercheur d'emploi : logo JOEM, barre de
/// recherche, cloche de notification (badge) et avatar profil — sur une
/// seule ligne en large écran, repliée sur deux lignes en mobile (voir
/// maquette_employeur.png).
class JobSeekerTopBar extends StatelessWidget {
  const JobSeekerTopBar({
    super.key,
    required this.isWide,
    required this.userInitial,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onProfileTap,
    this.onFilterTap,
  });

  final bool isWide;
  final String userInitial;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset('assets/images/joem_logo.png', height: 40);
    final bell = _NotificationBell(count: notificationCount, onTap: onNotificationTap);
    final profile = _ProfileAvatar(initial: userInitial, onTap: onProfileTap);
    final search = _SearchField(onFilterTap: onFilterTap);

    if (isWide) {
      return Row(
        children: [
          logo,
          const SizedBox(width: 24),
          Expanded(child: search),
          const SizedBox(width: 16),
          bell,
          const SizedBox(width: 12),
          profile,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            logo,
            const Spacer(),
            bell,
            const SizedBox(width: 12),
            profile,
          ],
        ),
        const SizedBox(height: 16),
        search,
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({this.onFilterTap});

  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.dashboardSurfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.dashboardSearchBar),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.dashboardTextMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: AppTextStyles.interRegular.copyWith(
                fontSize: 14,
                color: AppColors.dashboardTextPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Rechercher un emploi, un secteur, une ville...',
                hintStyle: AppTextStyles.interRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.dashboardTextMuted,
                ),
              ),
            ),
          ),
        ],
      ),
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initial, this.onTap});

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