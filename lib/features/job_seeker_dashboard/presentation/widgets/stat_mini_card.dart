import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/mini_line_chart_painter.dart';

/// Carte de statistique compacte de la barre latérale (Candidatures,
/// Favoris, Entretiens, Vues de profil) — titre + badge icône en haut,
/// grande valeur et libellé en dessous, avec une mini-courbe optionnelle.
class StatMiniCard extends StatelessWidget {
  const StatMiniCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.label,
    this.trend,
  });

  final IconData icon;
  final String title;
  final String value;
  final String label;
  final List<double>? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.dashboardKpiCard),
        boxShadow: AppShadows.dashboardCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 13,
                    color: AppColors.dashboardTextSecondary,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.dashboardMauveLightest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.dashboardMauveDark, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.poppinsExtraBold.copyWith(
              fontSize: 24,
              color: AppColors.dashboardTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 12,
              color: AppColors.dashboardTextMuted,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 10),
            MiniLineChart(values: trend!, height: 28, strokeWidth: 2),
          ],
        ],
      ),
    );
  }
}