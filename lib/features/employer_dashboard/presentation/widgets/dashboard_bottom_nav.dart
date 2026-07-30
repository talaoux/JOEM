import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';

class DashboardNavItem {
  const DashboardNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const List<DashboardNavItem> kDashboardNavItems = [
  DashboardNavItem(icon: Icons.home_rounded, label: 'Accueil'),
  DashboardNavItem(icon: Icons.work_outline_rounded, label: 'Offres'),
  DashboardNavItem(icon: Icons.people_outline_rounded, label: 'Candidats'),
  DashboardNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
  DashboardNavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
];

/// Bottom navigation bar with 5 tabs: Accueil, Offres, Candidats,
/// Messages, Profil. The active tab is shown as a filled mauve pill.
class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < kDashboardNavItems.length; i++)
            _NavTab(
              item: kDashboardNavItems[i],
              isActive: i == currentIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.isActive, required this.onTap});

  final DashboardNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.dashboardMauve : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isActive ? Colors.white : AppColors.dashboardTextMuted,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: AppTextStyles.interSemiBold.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}