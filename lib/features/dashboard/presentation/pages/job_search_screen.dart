import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/search_bar_widget.dart';

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Simulation de l'historique de recherche
  final List<String> _searchHistory = [
    'Développeur Flutter',
    'Designer UI/UX',
    'Chef de Projet',
    'CDI Antananarivo',
    'Comptable',
  ];

  void _removeHistoryItem(int index) {
    setState(() {
      _searchHistory.removeAt(index);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche + retour
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
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchController,
                      showFilterButton: false,
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),

            // Historique
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historiques',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Voir tout',
                      style: AppTypography.secondaryButton.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Expanded(
              child: _searchHistory.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.safeAreaHorizontal,
                      ),
                      itemCount: _searchHistory.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryItem(index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 20,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _searchHistory[index],
              style: AppTypography.interRegular.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _removeHistoryItem(index),
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun historique',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Vos recherches récentes apparaîtront ici.',
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
