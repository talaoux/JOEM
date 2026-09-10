import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/interview_repository.dart';

/// Détail d'un entretien, vu par le candidat (lecture seule) — ouvert
/// depuis la notification "L'entreprise souhaite vous rencontrer" de
/// `JobNotificationsScreen`. Récapitule toutes les informations saisies
/// par le recruteur dans `ScheduleInterviewScreen`.
class CandidateInterviewDetailScreen extends StatelessWidget {
  const CandidateInterviewDetailScreen({super.key, required this.interview});

  final Interview interview;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final notes = interview.notes?.trim() ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        title: Text('Entretien', style: colors.sectionTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: OnboardingColors.violet.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        interview.isModified
                            ? Icons.edit_calendar_rounded
                            : Icons.event_available_rounded,
                        color: OnboardingColors.violet,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          interview.isModified
                              ? 'Entretien modifié par l\'entreprise'
                              : 'L\'entreprise souhaite vous rencontrer',
                          style: colors.cardTitle.copyWith(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  if (interview.isModified) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Les informations ci-dessous ont été mises à jour.',
                      style: colors.cardDescription.copyWith(fontSize: 12),
                    ),
                  ],
                  if (interview.offerTitle.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pour le poste : ${interview.offerTitle.trim()}',
                      style: colors.cardDescription.copyWith(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _row(colors, Icons.calendar_today_rounded, 'Date', interview.dateLabel),
            _row(colors, Icons.access_time_rounded, 'Heure', interview.time),
            _row(
              colors,
              interview.isVisio ? Icons.videocam_outlined : Icons.location_on_outlined,
              interview.isVisio ? 'Mode' : 'Lieu',
              interview.isVisio ? 'Visioconférence' : interview.locationLabel,
            ),
            if (interview.isVisio && (interview.location?.trim().isNotEmpty ?? false))
              _row(colors, Icons.link_rounded, 'Lien / plateforme', interview.location!.trim()),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Note du recruteur', style: colors.cardTitle.copyWith(fontSize: 14)),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(notes, style: colors.cardDescription),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pensez à préparer votre entretien et à être disponible à l\'heure indiquée. '
              'En cas d\'empêchement, recontactez l\'entreprise au plus tôt.',
              style: AppTypography.interRegular.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AppSurfaceColors colors, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: OnboardingColors.violet),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: colors.cardDescription.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: colors.cardTitle.copyWith(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
