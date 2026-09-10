import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/job_offer_repository.dart';

/// Carte d'une offre publiée par le recruteur — partagée par la section
/// "Mes offres d'emploi" du `EmployerDashboard` et par `EmployerOffersScreen`.
/// Affiche le nombre réel de candidatures reçues sur l'offre et ouvre
/// `OfferApplicantsScreen` au tap ; le menu "..." permet de la supprimer.
class EmployerOfferCard extends StatelessWidget {
  const EmployerOfferCard({
    super.key,
    required this.offer,
    required this.applicantCount,
    required this.onTap,
    this.onDelete,
  });

  final JobOffer offer;
  final int applicantCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLightest, AppColors.primaryLighter],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    style: AppTypography.jobTitle
                        .copyWith(fontSize: 15, color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    children: [
                      _iconText(colors, Icons.location_on_outlined, offer.location),
                      _iconText(colors, Icons.schedule_rounded, offer.publishedLabel),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          applicantCount == 0
                              ? 'Aucune candidature'
                              : '$applicantCount candidature${applicantCount > 1 ? 's' : ''}',
                          style: AppTypography.interSemiBold.copyWith(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: colors.textTertiary),
                onSelected: (value) {
                  if (value == 'delete') onDelete!();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Supprimer l\'offre', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              )
            else
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _iconText(AppSurfaceColors colors, IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textTertiary),
        const SizedBox(width: 4),
        Text(text, style: colors.jobInfo.copyWith(fontSize: 12)),
      ],
    );
  }
}
