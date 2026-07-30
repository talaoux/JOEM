import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';

class GreetingSection extends StatelessWidget {
  final String firstName;
  const GreetingSection({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeAreaHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour $firstName 👋',
            style: AppTypography.greeting,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bienvenue sur votre espace emploi',
            style: AppTypography.welcomeMessage,
          ),
        ],
      ),
    );
  }
}