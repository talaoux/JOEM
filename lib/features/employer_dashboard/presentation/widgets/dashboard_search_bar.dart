import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// Large rounded search bar: "Rechercher une offre, un candidat..." with
/// a search icon and a filter icon.
class DashboardSearchBar extends StatelessWidget {
  const DashboardSearchBar({super.key, this.onFilterTap});

  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.dashboardSurfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.dashboardSearchBar),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.dashboardTextMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: AppTextStyles.interRegular.copyWith(
                fontSize: 15,
                color: AppColors.dashboardTextPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Rechercher une offre, un candidat...',
                hintStyle: AppTextStyles.interRegular.copyWith(
                  fontSize: 15,
                  color: AppColors.dashboardTextMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.tune_rounded,
                color: AppColors.dashboardMauveDark,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}