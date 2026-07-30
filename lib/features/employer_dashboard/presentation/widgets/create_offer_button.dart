import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radii.dart';
import 'package:joem/core/theme/app_text_styles.dart';

/// Big, full-width primary CTA: "Créer une offre" — mauve fill, 24px
/// radius, "+" leading icon.
class CreateOfferButton extends StatelessWidget {
  const CreateOfferButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dashboardMauve,
      borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.dashboardButton),
        onTap: onTap,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Créer une offre',
                style: AppTextStyles.interSemiBold.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}