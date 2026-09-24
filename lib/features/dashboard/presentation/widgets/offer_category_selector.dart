import 'package:flutter/material.dart';

import '../../../../core/constants/job_categories.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'soft_ui.dart';

/// Sélection multiple des catégories d'une offre (`kOfferCategories` :
/// `kJobCategories` + "Autres") — puces dans le même style que le
/// sélecteur de contrat de `JobOfferPublishScreen` (bordure + fond teinté
/// si choisie), utilisé en publication comme en modification d'une offre.
/// Le champ "Précisez le secteur" qui accompagne "Autres" vit dans
/// `JobOfferPublishScreen`.
class OfferCategorySelector extends StatelessWidget {
  const OfferCategorySelector({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final ink = SoftUi.brandInk(colors);
    final count = selected.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Catégories de l\'offre',
                style: AppTypography.interMedium.copyWith(
                  fontSize: 13,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Text(
              count == 0 ? 'Au moins une' : '$count sélectionnée${count > 1 ? 's' : ''}',
              style: AppTypography.interRegular.copyWith(
                fontSize: 12,
                color: count == 0 ? colors.textTertiary : ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Votre offre apparaîtra dans chaque catégorie choisie côté candidat.',
          style: AppTypography.interRegular.copyWith(
            fontSize: 12,
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in kOfferCategories) _buildChip(colors, category),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(AppSurfaceColors colors, String category) {
    final isSelected = selected.contains(category);
    final ink = SoftUi.brandInk(colors);
    return Material(
      color: isSelected
          ? SoftUi.tint(colors, DashboardColors.accent)
          : (SoftUi.isDark(colors) ? colors.surface : DashboardColors.segment),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? ink : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onToggle(category),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_rounded, size: 16, color: ink),
                const SizedBox(width: 4),
              ],
              Text(
                category,
                style: AppTypography.interSemiBold.copyWith(
                  fontSize: 12.5,
                  color: isSelected ? ink : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
