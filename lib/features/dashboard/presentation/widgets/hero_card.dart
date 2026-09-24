import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'soft_ui.dart';

/// Bannière "Trouvez votre prochain emploi" de l'accueil candidat — style
/// "nouveau design" (voir `soft_ui.dart`) : carte blanche, titre serif,
/// bouton pilule à teinte pâle aligné à droite (même composition que la
/// carte "Publier une offre" de l'accueil recruteur).
class HeroCard extends StatelessWidget {
  final VoidCallback onFindJobTap;

  const HeroCard({super.key, required this.onFindJobTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return SoftCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Trouvez votre prochain emploi',
                  style: AppTypography.frauncesBold.copyWith(
                    fontSize: 23,
                    color: colors.textPrimary,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SoftUi.tint(colors, DashboardColors.accent),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  size: 22,
                  color: SoftUi.brandInk(colors),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Découvrez les meilleures opportunités adaptées à votre profil.',
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: SoftPillButton(
              label: 'Trouver un emploi',
              icon: Icons.arrow_forward_rounded,
              onPressed: onFindJobTap,
            ),
          ),
        ],
      ),
    );
  }
}
