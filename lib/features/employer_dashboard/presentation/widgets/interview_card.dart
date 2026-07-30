import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// One row inside the "Entretiens aujourd'hui" card: time, candidate
/// name and job title.
class InterviewCard extends StatelessWidget {
  const InterviewCard({
    super.key,
    required this.time,
    required this.candidateName,
    required this.jobTitle,
  });

  final String time;
  final String candidateName;
  final String jobTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.dashboardMauveLightest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            time,
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 13,
              color: AppColors.dashboardMauveDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidateName,
                style: AppTextStyles.interSemiBold.copyWith(
                  fontSize: 14,
                  color: AppColors.dashboardTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                jobTitle,
                style: AppTextStyles.interRegular.copyWith(
                  fontSize: 12,
                  color: AppColors.dashboardTextSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}