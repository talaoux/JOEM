import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/interview_repository.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Détail d'un entretien, vu par le candidat (lecture seule) — ouvert
/// depuis la notification "L'entreprise souhaite vous rencontrer" de
/// `JobNotificationsScreen`. Récapitule toutes les informations saisies
/// par le recruteur dans `ScheduleInterviewScreen`. Style "nouveau design"
/// (voir `soft_ui.dart`), ambre = couleur des entretiens.
class CandidateInterviewDetailScreen extends StatelessWidget {
  const CandidateInterviewDetailScreen({super.key, required this.interview});

  final Interview interview;

  static const Color _amber = Color(0xFFC2780E);

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final notes = interview.notes?.trim() ?? '';
    final amberInk = SoftUi.accentInk(colors, _amber);

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      appBar: const SoftAppBar(title: 'Entretien'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.safeAreaHorizontal,
            AppSpacing.sm,
            AppSpacing.safeAreaHorizontal,
            AppSpacing.xl,
          ),
          children: staggered([
            // Bloc teinté ambre : heure en gros chiffres serif (comme le
            // "48 messages reçus" de la maquette), date et contexte.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: SoftUi.isDark(colors) ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoftDotBadge(
                    label: interview.isModified
                        ? 'Entretien modifié par l\'entreprise'
                        : 'L\'entreprise souhaite vous rencontrer',
                    color: interview.isModified ? const Color(0xFFB45309) : _amber,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        interview.isDateToBeDefined ? 'À voir' : interview.timeLabel,
                        style: AppTypography.frauncesBold.copyWith(
                          fontSize: 40,
                          color: amberInk,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            interview.isDateToBeDefined
                                ? "Date à définir — l'entreprise vous la communiquera prochainement."
                                : interview.dateLabel,
                            style: AppTypography.interMedium.copyWith(
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (interview.offerTitle.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Pour le poste : ${interview.offerTitle.trim()}',
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (interview.isModified) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Les informations ci-dessous ont été mises à jour.',
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
              child: Column(
                children: [
                  _row(colors, Icons.calendar_today_rounded, 'Date', interview.dateLabel),
                  if (!interview.isDateToBeDefined)
                    _row(colors, Icons.access_time_rounded, 'Heure', interview.timeLabel),
                  _row(
                    colors,
                    interview.isVisio ? Icons.videocam_outlined : Icons.location_on_outlined,
                    interview.isVisio ? 'Mode' : 'Lieu',
                    interview.isVisio ? 'Visioconférence' : interview.locationLabel,
                  ),
                  if (interview.isVisio && (interview.location?.trim().isNotEmpty ?? false))
                    _row(colors, Icons.link_rounded, 'Lien / plateforme', interview.location!.trim()),
                ],
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: SoftSection(
                  title: 'Note du recruteur',
                  child: Text(
                    notes,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Préparez votre entretien · Soyez à l\'heure · Prévenez l\'entreprise en cas d\'empêchement',
              textAlign: TextAlign.center,
              style: AppTypography.interRegular.copyWith(
                fontSize: 12,
                color: colors.textTertiary,
                height: 1.4,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(AppSurfaceColors colors, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SoftUi.tint(colors, _amber),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: SoftUi.accentInk(colors, _amber)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.interRegular.copyWith(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.interSemiBold.copyWith(fontSize: 14.5, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
