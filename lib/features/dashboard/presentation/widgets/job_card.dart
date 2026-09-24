import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'soft_ui.dart';

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

  /// `true` si le chercheur d'emploi connecté a déjà postulé à cette
  /// offre (`JobOfferRepository.hasApplied`) — le bouton devient
  /// "Candidature envoyée", désactivé.
  final bool hasApplied;

  /// Ouvre le détail de l'offre — tap sur la carte en dehors des boutons
  /// "Postuler"/favori. `null` désactive l'interaction (carte statique).
  final VoidCallback? onTap;

  /// Logo de l'entreprise (pris au moment de la publication de l'offre) —
  /// remplace l'icône générique quand renseigné.
  final Uint8List? companyLogo;

  /// Heure/date de publication réelle (ex. "Aujourd'hui à 14:32"),
  /// affichée sous le nom de l'entreprise — `null` masque la ligne.
  final String? publishedLabel;

  const JobCard({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.salary,
    required this.contractType,
    this.isNew = false,
    this.isFavorite = false,
    this.hasApplied = false,
    required this.onApply,
    required this.onFavoriteTap,
    this.companyLogo,
    this.publishedLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
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
                  color: DashboardColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: companyLogo != null
                      ? DecorationImage(
                          image: MemoryImage(companyLogo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: companyLogo == null
                    ? Icon(
                        Icons.business_rounded,
                        color: DashboardColors.accent,
                        size: 24,
                      )
                    : null,
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
                              color: DashboardColors.accent,
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
                    if (publishedLabel != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            publishedLabel!,
                            style: AppTypography.jobInfo.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
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

          // Bouton Postuler / Candidature envoyée
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasApplied ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasApplied ? const Color(0xFFE5E7EB) : DashboardColors.accent,
                foregroundColor:
                    hasApplied ? const Color(0xFF6B7280) : Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasApplied) ...[
                    const Icon(Icons.check_circle_rounded, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    hasApplied ? 'Candidature envoyée' : 'Postuler',
                    style: AppTypography.primaryButton.copyWith(
                      fontSize: 14,
                      color: hasApplied ? const Color(0xFF6B7280) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}