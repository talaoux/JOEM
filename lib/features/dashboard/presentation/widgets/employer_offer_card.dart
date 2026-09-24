import 'package:flutter/material.dart';

import '../../../../core/constants/job_categories.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/job_offer_repository.dart';
import 'soft_ui.dart';

/// Carte d'une offre publiée par le recruteur — partagée par la section
/// "Mes offres d'emploi" du `EmployerDashboard` et par `EmployerOffersScreen`.
/// Affiche le nombre réel de candidatures reçues sur l'offre et ouvre
/// `OfferApplicantsScreen` au tap ; le menu "..." permet de la modifier
/// et/ou de la supprimer (selon les callbacks fournis).
/// Style "nouveau design" (voir `soft_ui.dart`).
class EmployerOfferCard extends StatelessWidget {
  const EmployerOfferCard({
    super.key,
    required this.offer,
    required this.applicantCount,
    required this.onTap,
    this.categories = const [],
    this.onEdit,
    this.onDelete,
  });

  final JobOffer offer;
  final int applicantCount;
  final VoidCallback onTap;

  /// Catégories propres de l'offre (`job_offer_categories`) — vide pour une
  /// offre antérieure à v28, auquel cas rien n'est affiché.
  final List<String> categories;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Même vert que la carte "Candidatures" du Tableau de bord.
  static const Color _applicantsColor = Color(0xFF0F8A6E);

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: SoftUi.tint(colors, DashboardColors.accent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.work_outline_rounded, color: SoftUi.brandInk(colors), size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: AppTypography.interSemiBold
                      .copyWith(fontSize: 15, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    _iconText(colors, Icons.location_on_outlined, offer.location),
                    _iconText(colors, Icons.schedule_rounded, offer.publishedLabel),
                    if (categories.isNotEmpty)
                      _iconText(colors, Icons.category_outlined, categories.map((c) => offerCategoryLabel(c, offer.otherSector)).join(', ')),
                  ],
                ),
                const SizedBox(height: 10),
                SoftDotBadge(
                  label: applicantCount == 0
                      ? 'Aucune candidature'
                      : '$applicantCount candidature${applicantCount > 1 ? 's' : ''}',
                  color: applicantCount == 0 ? colors.textTertiary : _applicantsColor,
                ),
              ],
            ),
          ),
          if (onDelete != null || onEdit != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: colors.textTertiary),
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text("Modifier l'offre"),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text("Supprimer l'offre", style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
              ],
            )
          else
            Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
        ],
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
