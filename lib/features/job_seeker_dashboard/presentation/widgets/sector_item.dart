import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// Une case du bloc "Explorer par secteur" : icône badge + libellé.
class SectorItem extends StatelessWidget {
  const SectorItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.dashboardKpiCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.dashboardKpiCard),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.dashboardKpiCard),
              boxShadow: AppShadows.dashboardCard,
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.dashboardMauveLightest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.dashboardMauveDark, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.dashboardTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}