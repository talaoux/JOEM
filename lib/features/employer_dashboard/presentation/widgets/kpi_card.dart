import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/mini_line_chart_painter.dart';

/// One KPI stat card: icon, big value, label and a mini trend graph.
/// Used in the 2x2 grid (Offres publiées, Candidatures reçues,
/// Entretiens, Embauches).
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
  });

  final IconData icon;
  final String value;
  final String label;
  final List<double> trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.dashboardKpiCard),
        boxShadow: AppShadows.dashboardCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.dashboardMauveLightest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.dashboardMauveDark, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: AppTextStyles.poppinsExtraBold.copyWith(
              fontSize: 26,
              color: AppColors.dashboardTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 13,
              color: AppColors.dashboardTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          MiniLineChart(values: trend, height: 28, strokeWidth: 2),
        ],
      ),
    );
  }
}