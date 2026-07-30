import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// "Section title" + optional trailing link (e.g. "Voir tout"), reused
/// above the offers list, candidates list, etc.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailingLabel, this.onTrailingTap});

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 18,
              color: AppColors.dashboardTextPrimary,
            ),
          ),
        ),
        if (trailingLabel != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                trailingLabel!,
                style: AppTextStyles.interSemiBold.copyWith(
                  fontSize: 14,
                  color: AppColors.dashboardMauveDark,
                ),
              ),
            ),
          ),
      ],
    );
  }
}