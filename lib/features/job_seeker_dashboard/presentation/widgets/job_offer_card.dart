import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/widgets/dashboard_card.dart';

/// Une offre d'emploi recommandée : logo entreprise, titre, ville,
/// contrat/expérience/ancienneté, fourchette de salaire et bouton
/// "Postuler" (voir maquette_employeur.png).
class JobOfferCard extends StatelessWidget {
  const JobOfferCard({
    super.key,
    required this.company,
    required this.title,
    required this.city,
    required this.contractType,
    required this.experience,
    required this.postedAgo,
    required this.salaryRange,
    required this.onApply,
  });

  final String company;
  final String title;
  final String city;
  final String contractType;
  final String experience;
  final String postedAgo;
  final String salaryRange;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final initial = company.isNotEmpty ? company[0].toUpperCase() : '?';

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.dashboardMauveLightest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  initial,
                  style: AppTextStyles.poppinsExtraBold.copyWith(
                    fontSize: 20,
                    color: AppColors.dashboardMauveDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.poppinsSemiBold.copyWith(
                        fontSize: 16,
                        color: AppColors.dashboardTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$company · $city',
                      style: AppTextStyles.interRegular.copyWith(
                        fontSize: 13,
                        color: AppColors.dashboardTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _MetaChip(icon: Icons.description_outlined, label: contractType),
                        _MetaChip(icon: Icons.work_outline_rounded, label: experience),
                        _MetaChip(icon: Icons.schedule_rounded, label: postedAgo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  salaryRange,
                  style: AppTextStyles.interSemiBold.copyWith(
                    fontSize: 14,
                    color: AppColors.dashboardSuccess,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: AppColors.dashboardMauve,
                borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
                  onTap: onApply,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    child: Text(
                      'Postuler',
                      style: AppTextStyles.interSemiBold.copyWith(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
        Icon(icon, size: 14, color: AppColors.dashboardTextMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 12,
            color: AppColors.dashboardTextSecondary,
          ),
        ),
      ],
    );
  }
}