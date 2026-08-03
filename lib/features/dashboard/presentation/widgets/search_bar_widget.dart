import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterTap;
  final bool showFilterButton;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onFilterTap,
    this.showFilterButton = true,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.searchBarRadius,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
              color: const Color(0xFF9CA3AF),
              size: 24,
            ),
          ),

          // TextField
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              style: AppTypography.interRegular.copyWith(
                fontSize: 15,
                color: const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un emploi...',
                hintStyle: AppTypography.interRegular.copyWith(
                  fontSize: 15,
                  color: const Color(0xFF9CA3AF),
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