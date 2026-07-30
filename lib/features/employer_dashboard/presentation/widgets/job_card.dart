import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/dashboard_card.dart';

/// One row of "Mes offres récentes": title, city, salary, applicant
/// count, an "Active" badge and a "Modifier" button.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.title,
    required this.city,
    required this.salary,
    required this.candidateCount,
    required this.onEdit,
  });

  final String title;
  final String city;
  final String salary;
  final int candidateCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 16,
                    color: AppColors.dashboardTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ActiveBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _MetaChip(icon: Icons.location_on_outlined, label: city),
              _MetaChip(icon: Icons.people_outline_rounded, label: '$candidateCount candidats'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  salary,
                  style: AppTextStyles.interSemiBold.copyWith(
                    fontSize: 14,
                    color: AppColors.dashboardMauveDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dashboardMauveDark,
                  side: const BorderSide(color: AppColors.dashboardMauveLight),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
                  ),
                ),
                child: Text(
                  'Modifier',
                  style: AppTextStyles.interSemiBold.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.dashboardTextMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 13,
            color: AppColors.dashboardTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dashboardSuccess.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        'Active',
        style: AppTextStyles.interSemiBold.copyWith(
          fontSize: 11,
          color: AppColors.dashboardSuccess,
        ),
      ),
    );
  }
}