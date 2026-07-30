import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';

import 'package:joem/core/widgets/dashboard_card.dart';
import 'package:joem/core/widgets/mini_line_chart_painter.dart';

/// Sidebar "Évolution des candidatures" card: white card, title, mauve
/// curve on a white background.
class StatisticsChartCard extends StatelessWidget {
  const StatisticsChartCard({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution des candidatures',
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 15,
              color: AppColors.dashboardTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          MiniLineChart(values: values, height: 90, filled: true, strokeWidth: 3),
        ],
      ),
    );
  }
}