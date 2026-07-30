import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  const DashboardHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeAreaHorizontal,
        vertical: AppSpacing.headerPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo JOEM
          Image.asset(
            'assets/images/joem_logo.png',
            height: 60,
            width: 150,
            fit: BoxFit.contain,
          ),

          // Actions à droite
          Row(
            children: [
              // Notification
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Photo utilisateur
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/avatar_portfolio1.jpg'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
