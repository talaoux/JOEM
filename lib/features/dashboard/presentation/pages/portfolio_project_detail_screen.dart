import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Détail d'un projet du Portfolio, en lecture seule — image de couverture,
/// technologies, description, rôle du candidat, fonctionnalités principales
/// et liens (générique/GitHub/démo). Ouvert depuis `PortfolioProjectsScreen`
/// (candidat) et `CandidateProfileViewScreen` (recruteur, même écran :
/// [readOnly] masque uniquement les actions qui n'ont de sens que pour le
/// propriétaire — ici, aucune, tout y est déjà en lecture seule).
class PortfolioProjectDetailScreen extends StatelessWidget {
  const PortfolioProjectDetailScreen({super.key, required this.project});

  final PortfolioProject project;

  Future<void> _openLink(BuildContext context, String rawLink) async {
    final trimmed = rawLink.trim();
    var uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://$trimmed');
    }
    if (uri == null) return;

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir ce lien.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final hasImage = project.imageBytes != null;
    final hasDescription = (project.description ?? '').trim().isNotEmpty;
    final hasRole = (project.role ?? '').trim().isNotEmpty;
    final genericLink = (project.link ?? '').trim();
    final githubLink = (project.githubLink ?? '').trim();
    final demoLink = (project.demoLink ?? '').trim();

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              Stack(
                children: [
                  hasImage
                      ? Image.memory(
                          project.imageBytes!,
                          width: double.infinity,
                          height: 210,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 210,
                          color: DashboardColors.accent.withValues(alpha: SoftUi.isDark(colors) ? 0.22 : 0.12),
                          child: Icon(
                            Icons.collections_bookmark_rounded,
                            color: SoftUi.brandInk(colors),
                            size: 52,
                          ),
                        ),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.sm,
                    child: Material(
                      color: colors.background.withValues(alpha: 0.9),
                      shape: CircleBorder(side: BorderSide(color: colors.divider)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: AppTypography.frauncesBold.copyWith(
                        fontSize: 26,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    if (project.technologies.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: project.technologies.map((tech) {
                          return SoftDotBadge(label: tech, color: DashboardColors.accent);
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (hasDescription) ...[
                      _buildSectionCard(
                        colors,
                        icon: Icons.info_outline_rounded,
                        title: 'À propos du projet',
                        child: Text(
                          project.description!,
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 13.5,
                            height: 1.6,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (hasRole) ...[
                      _buildSectionCard(
                        colors,
                        icon: Icons.person_outline_rounded,
                        title: 'Mon rôle',
                        child: Text(
                          project.role!,
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 13.5,
                            height: 1.6,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (project.features.isNotEmpty) ...[
                      _buildSectionCard(
                        colors,
                        icon: Icons.checklist_rounded,
                        title: 'Fonctionnalités principales',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final feature in project.features)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: DashboardColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: AppTypography.interRegular.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (githubLink.isNotEmpty || demoLink.isNotEmpty || genericLink.isNotEmpty)
                      Row(
                        children: [
                          if (githubLink.isNotEmpty)
                            Expanded(
                              child: _buildLinkButton(
                                colors,
                                label: 'Voir sur GitHub',
                                icon: Icons.integration_instructions_outlined,
                                background: const Color(0xFF1A1A2E),
                                onTap: () => _openLink(context, githubLink),
                              ),
                            ),
                          if (githubLink.isNotEmpty && (demoLink.isNotEmpty || genericLink.isNotEmpty))
                            const SizedBox(width: 10),
                          if (demoLink.isNotEmpty || genericLink.isNotEmpty)
                            Expanded(
                              child: _buildLinkButton(
                                colors,
                                label: 'Voir la démo',
                                icon: Icons.play_circle_outline_rounded,
                                background: DashboardColors.accent,
                                onTap: () => _openLink(
                                  context,
                                  demoLink.isNotEmpty ? demoLink : genericLink,
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildSectionCard(
    AppSurfaceColors colors, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: SoftUi.brandInk(colors)),
              const SizedBox(width: 8),
              SerifSectionTitle(title, fontSize: 18),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildLinkButton(
    AppSurfaceColors colors, {
    required String label,
    required IconData icon,
    required Color background,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        // Pilule à teinte pâle de la couleur du lien (GitHub / démo), plus
        // de fond plein.
        style: ElevatedButton.styleFrom(
          backgroundColor: SoftUi.tint(colors, background),
          foregroundColor: SoftUi.accentInk(colors, background),
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
