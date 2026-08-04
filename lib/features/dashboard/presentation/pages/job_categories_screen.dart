import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/category_card.dart';

class JobCategoriesScreen extends StatelessWidget {
  const JobCategoriesScreen({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'title': 'Informatique', 'icon': Icons.computer_rounded},
    {'title': 'Commerce', 'icon': Icons.shopping_bag_rounded},
    {'title': 'Santé', 'icon': Icons.medical_services_rounded},
    {'title': 'BTP', 'icon': Icons.construction_rounded},
    {'title': 'Finance', 'icon': Icons.account_balance_rounded},
    {'title': 'Marketing', 'icon': Icons.campaign_rounded},
    {'title': 'Education', 'icon': Icons.school_rounded},
    {'title': 'Industrie', 'icon': Icons.precision_manufacturing_rounded},
    {'title': 'Transport', 'icon': Icons.local_shipping_rounded},
    {'title': 'Tourisme', 'icon': Icons.hotel_rounded},
    {'title': 'Agriculture', 'icon': Icons.agriculture_rounded},
    {'title': 'Juridique', 'icon': Icons.gavel_rounded},
    {'title': 'Ressources Humaines', 'icon': Icons.groups_rounded},
    {'title': 'Communication', 'icon': Icons.record_voice_over_rounded},
    {'title': 'Artisanat', 'icon': Icons.handyman_rounded},
    {'title': 'Sécurité', 'icon': Icons.security_rounded},
    {'title': 'Restauration', 'icon': Icons.restaurant_rounded},
    {'title': 'Textile', 'icon': Icons.checkroom_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
                vertical: AppSpacing.headerPadding,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text('Catégories', style: AppTypography.sectionTitle),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return CategoryCard(
                    title: category['title'],
                    icon: category['icon'],
                    onTap: () {},
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}