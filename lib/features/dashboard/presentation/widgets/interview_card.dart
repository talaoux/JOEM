import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';

import 'soft_ui.dart';

/// Carte d'entretien de l'accueil recruteur — style "nouveau design" (voir
/// `soft_ui.dart`) : pavé horaire en serif sur fond ambre pâle (même ambre
/// que la carte "Entretiens" du Tableau de bord), détails puis bouton
/// pilule doux "Voir", le tout sur une seule ligne.
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

  static const Color _amber = Color(0xFFC2780E);

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final amberInk = SoftUi.accentInk(colors, _amber);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: SoftUi.tint(colors, _amber),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        time,
                        style: AppTypography.frauncesBold.copyWith(
                          fontSize: 18,
                          color: amberInk,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: amberInk, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: AppTypography.interSemiBold
                          .copyWith(fontSize: 15, color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _detail(colors, Icons.calendar_today_outlined, date),
                    const SizedBox(height: 2),
                    _detail(colors, Icons.location_on_outlined, location),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Bouton sur la même ligne que le contenu (plutôt que
              // dessous) pour une carte plus basse — libellé court pour
              // laisser la place au nom/lieu.
              SoftPillButton(
                label: 'Voir',
                icon: Icons.arrow_forward_rounded,
                compact: true,
                onPressed: onViewDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(AppSurfaceColors colors, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: colors.textTertiary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTypography.interRegular.copyWith(fontSize: 12, color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
