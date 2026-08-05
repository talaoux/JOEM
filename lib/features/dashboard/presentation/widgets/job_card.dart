import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/theme/app_shadows.dart';

class JobCard extends StatelessWidget {
  final String jobTitle;
  final String company;
  final String location;
  final String salary;
  final String contractType;
  final bool isNew;
  final bool isFavorite;
  final VoidCallback onApply;
  final VoidCallback onFavoriteTap;

  const JobCard({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.salary,
    required this.contractType,
    this.isNew = false,
    this.isFavorite = false,
    required this.onApply,
    required this.onFavoriteTap,
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
          // Header avec logo et favori
          Row(
            children: [
              // Logo entreprise
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: OnboardingColors.violet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: OnboardingColors.violet,
                  size: 24,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Infos principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            jobTitle,
                            style: AppTypography.jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: OnboardingColors.violet,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nouveau',
                              style: AppTypography.badge,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      company,
                      style: AppTypography.companyName,
                    ),
                  ],
                ),
              ),

              // Bouton favori
              IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : const Color(0xFF9CA3AF),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Informations
          Row(
            children: [
              // Ville
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  location,
                  style: AppTypography.jobInfo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Salaire
              Icon(
                Icons.attach_money_rounded,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                salary,
                style: AppTypography.jobInfo,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Type de contrat
          Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                contractType,
                style: AppTypography.jobInfo,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Bouton Postuler
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: OnboardingColors.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Postuler',
                style: AppTypography.primaryButton.copyWith(
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