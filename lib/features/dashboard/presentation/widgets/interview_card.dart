import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/theme/app_shadows.dart';

class InterviewCard extends StatelessWidget {
  final String company;
  final String date;
  final String time;
  final String location;
  final VoidCallback onViewDetails;

  const InterviewCard({
    super.key,
    required this.company,
    required this.date,
    required this.time,
    required this.location,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entreprise
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  company,
                  style: AppTypography.interviewCompany,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Date et heure
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                date,
                style: AppTypography.interviewDetail,
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                time,
                style: AppTypography.interviewDetail,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Lieu
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  location,
                  style: AppTypography.interviewDetail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Bouton Voir
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Voir',
                style: AppTypography.secondaryButton.copyWith(
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}