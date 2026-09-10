import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterTap;
  final bool showFilterButton;
  final ValueChanged<String>? onChanged;

  /// Appelé quand l'utilisateur valide la recherche (touche "Rechercher"
  /// du clavier) — distinct de [onChanged] (déclenché à chaque frappe) :
  /// utilisé pour enregistrer un historique de recherche réel sans le
  /// polluer d'entrées partielles à chaque lettre tapée.
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final VoidCallback? onTap;
  final bool readOnly;

  /// Texte d'indication affiché quand le champ est vide — par défaut
  /// orienté "offres" (candidat) ; le dashboard recruteur passe
  /// "Rechercher un candidat..." pour rester cohérent avec son contenu.
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onFilterTap,
    this.showFilterButton = true,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.onTap,
    this.readOnly = false,
    this.hintText = 'Rechercher un emploi...',
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.searchBarRadius,
        border: Border.all(
          color: colors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône loupe
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: Icon(
              Icons.search_rounded,
              color: colors.textTertiary,
              size: 24,
            ),
          ),

          // TextField
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              autofocus: autofocus,
              readOnly: readOnly,
              onTap: onTap,
              style: AppTypography.interRegular.copyWith(
                fontSize: 15,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.interRegular.copyWith(
                  fontSize: 15,
                  color: colors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
              ),
            ),
          ),

          // Bouton filtre
          if (showFilterButton)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                onPressed: onFilterTap,
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: AppSpacing.lg),
        ],
      ),
    );
  }
}