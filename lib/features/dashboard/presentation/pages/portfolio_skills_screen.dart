import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'edit_job_seeker_profile_screen.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Sous-écran "Compétences" du Portfolio candidat — mêmes compétences que
/// `EditJobSeekerProfileScreen`/`JobProfileScreen` (`job_seeker_skills`), en
/// lecture seule ici (icône stylo pour les modifier). Un seul type de
/// compétence existe dans le modèle de données actuel (pas de distinction
/// technique/soft skill en base) : toutes s'affichent donc dans la même
/// section, sous forme de badges plutôt que de barres de progression.
class PortfolioSkillsScreen extends StatefulWidget {
  const PortfolioSkillsScreen({super.key});

  @override
  State<PortfolioSkillsScreen> createState() => _PortfolioSkillsScreenState();
}

class _PortfolioSkillsScreenState extends State<PortfolioSkillsScreen> {
  final AuthService _authService = AuthService();

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditJobSeekerProfileScreen()),
    );
    if (!mounted || updated != true) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final skills = _authService.currentUser?.skills ?? const [];

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                  vertical: AppSpacing.headerPadding,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                    ),
                    Expanded(child: SerifSectionTitle('Compétences')),
                    IconButton(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.edit_outlined, color: DashboardColors.accent),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SerifSectionTitle('Compétences techniques', fontSize: 18),
                    const SizedBox(height: AppSpacing.md),
                    if (skills.isEmpty)
                      const SoftEmptyState(
                        icon: Icons.stars_rounded,
                        text: 'Aucune compétence renseignée pour le moment.',
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: skills.map(_buildSkillChip).toList(),
                      ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Compétence : pilule blanche à fine bordure avec un point violet.
  Widget _buildSkillChip(String label) {
    final colors = AppSurfaceColors.of(context);
    final ink = SoftUi.brandInk(colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.interSemiBold.copyWith(
              fontSize: 13,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
