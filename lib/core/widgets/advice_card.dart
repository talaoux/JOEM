import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/dashboard_card.dart';

/// "Conseil du jour" card: lightbulb icon, title and advice text.
class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.dashboardMauveLightest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.dashboardMauveDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conseil du jour',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 15,
                    color: AppColors.dashboardTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 13,
              color: AppColors.dashboardTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}