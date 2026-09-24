import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_search_repository.dart';
import '../widgets/soft_ui.dart';
import 'candidate_full_portfolio_screen.dart';
import 'portfolio_project_detail_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Profil d'un candidat trouvé via `CandidateSearchScreen` (recherche
/// recruteur) — même identité visuelle que `JobProfileScreen` (le profil du
/// candidat connecté), mais en lecture seule : pas d'édition de photo, pas
/// d'ajout/suppression d'expérience, pas de carte "Profil complété" (elle
/// n'a de sens que pour son propriétaire).
class CandidateProfileViewScreen extends StatefulWidget {
  const CandidateProfileViewScreen({super.key, required this.candidate});

  final CandidateSearchResult candidate;

  @override
  State<CandidateProfileViewScreen> createState() => _CandidateProfileViewScreenState();
}

/// State uniquement pour lire les couleurs du thème (mode nuit) dans tous
/// les helpers — aucune donnée mutable ici.
class _CandidateProfileViewScreenState extends State<CandidateProfileViewScreen> {
  CandidateSearchResult get candidate => widget.candidate;

  AppSurfaceColors get _c => AppSurfaceColors.of(context);

  static const double _bannerHeight = 130;
  static const double _avatarOverflow = 45;
  static const double _avatarBoxSize = 98;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(_c),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              _buildBannerAndAvatar(context),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: _buildIdentitySection(),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'À propos',
                      child: _buildAbout(),
                    ),
                    if ((candidate.objectifs ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildSectionCard(
                        title: 'Objectifs',
                        child: Text(
                          candidate.objectifs!.trim(),
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 14,
                            color: _c.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Expérience',
                      child: candidate.experiences.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucune expérience renseignée pour le moment.",
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < candidate.experiences.length; i++) ...[
                                  if (i > 0) Divider(height: 24, color: _c.divider),
                                  _buildExperienceRow(candidate.experiences[i]),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Portfolio',
                      trailingLabel: 'Voir tout',
                      onTitleTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CandidateFullPortfolioScreen(candidate: candidate),
                        ),
                      ),
                      child: candidate.portfolioProjects.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucun projet ajouté pour le moment.",
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < candidate.portfolioProjects.length; i++) ...[
                                  if (i > 0) Divider(height: 24, color: _c.divider),
                                  _buildPortfolioProjectRow(context, candidate.portfolioProjects[i]),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Formations',
                      child: candidate.formations.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucune formation renseignée pour le moment.",
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < candidate.formations.length; i++) ...[
                                  if (i > 0) Divider(height: 24, color: _c.divider),
                                  _buildFormationRow(candidate.formations[i]),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Certifications',
                      child: candidate.certifications.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucune certification ajoutée pour le moment.",
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < candidate.certifications.length; i++) ...[
                                  if (i > 0) Divider(height: 24, color: _c.divider),
                                  _buildCertificationRow(candidate.certifications[i]),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Mes liens',
                      child: candidate.professionalLinks.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucun lien professionnel renseigné pour le moment.",
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < candidate.professionalLinks.length; i++) ...[
                                  if (i > 0) Divider(height: 24, color: _c.divider),
                                  _buildLinkRow(context, candidate.professionalLinks[i]),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Compétences',
                      child: candidate.skills.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucune compétence renseignée pour le moment.",
                            )
                          : Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: candidate.skills.map(_buildSkillChip).toList(),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Coordonnées',
                      child: _buildContactInfo(),
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

  Widget _buildBannerAndAvatar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const SizedBox(height: _bannerHeight + _avatarOverflow, width: double.infinity),
        Container(
          height: _bannerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: DashboardColors.accent.withValues(alpha: SoftUi.isDark(_c) ? 0.22 : 0.12),
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: Material(
            color: _c.background.withValues(alpha: 0.9),
            shape: CircleBorder(side: BorderSide(color: _c.divider)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back_rounded, color: _c.textPrimary, size: 18),
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.safeAreaHorizontal,
          top: _bannerHeight + _avatarOverflow - _avatarBoxSize,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SoftUi.pageBackground(_c),
              shape: BoxShape.circle,
            ),
            child: SoftAvatar(
              name: candidate.fullName,
              size: 90,
              photo: candidate.photo != null ? MemoryImage(candidate.photo!) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitySection() {
    final fullName = candidate.fullName.isEmpty ? 'Candidat' : candidate.fullName;
    final position = candidate.position?.trim() ?? '';
    final subtitle = position.isNotEmpty ? '$position · Chercheur d\'emploi' : 'Chercheur d\'emploi';
    final location = candidate.localisation?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          style: AppTypography.frauncesBold.copyWith(
            fontSize: 26,
            color: _c.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            color: _c.textSecondary,
          ),
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                location,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: _c.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAbout() {
    final about = candidate.presentation?.trim() ?? '';
    if (about.isEmpty) {
      return _buildEmptyPlaceholder("Ce candidat n'a pas encore ajouté de présentation.");
    }
    return Text(
      about.isNotEmpty ? about : "Ce candidat n'a pas encore ajouté de présentation.",
      style: AppTypography.interRegular.copyWith(
        fontSize: 14,
        fontStyle: about.isNotEmpty ? FontStyle.normal : FontStyle.italic,
        color: _c.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildContactInfo() {
    final telephone = candidate.telephone?.trim() ?? '';
    final location = candidate.localisation?.trim() ?? '';

    if (telephone.isEmpty && location.isEmpty) {
      return _buildEmptyPlaceholder("Aucune coordonnée renseignée pour le moment.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (telephone.isNotEmpty) ...[
          _buildContactRow(Icons.call_rounded, telephone),
          if (location.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        ],
        if (location.isNotEmpty) _buildContactRow(Icons.location_on_outlined, location),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DashboardColors.accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              color: _c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    String? trailingLabel,
    VoidCallback? onTitleTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: SoftSection(
        title: title,
        trailing: trailingLabel != null && onTitleTap != null
            ? SoftPillButton(
                label: trailingLabel,
                icon: Icons.arrow_forward_rounded,
                compact: true,
                onPressed: onTitleTap,
              )
            : null,
        child: child,
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return SoftEmptyState(text: message);
  }

  Widget _buildExperienceRow(JobExperience experience) {
    final period = experience.enCours
        ? '${experience.dateDebut} - Aujourd\'hui'
        : (experience.dateFin != null && experience.dateFin!.isNotEmpty)
            ? '${experience.dateDebut} - ${experience.dateFin}'
            : experience.dateDebut;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: SoftUi.tint(_c, DashboardColors.accent),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.work_outline_rounded, color: SoftUi.brandInk(_c), size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                experience.poste,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _c.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                experience.entreprise,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: _c.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                period,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 12,
                  color: _c.textTertiary,
                ),
              ),
              if (experience.description != null && experience.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  experience.description!,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13,
                    color: _c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioProjectRow(BuildContext context, PortfolioProject project) {
    final hasImage = project.imageBytes != null;
    final hasDescription = (project.description ?? '').trim().isNotEmpty;
    final hasLink = (project.link ?? '').trim().isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PortfolioProjectDetailScreen(project: project)),
      ),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImage
              ? Image.memory(
                  project.imageBytes!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: SoftUi.tint(_c, DashboardColors.accent),
                  child: Icon(
                    Icons.collections_bookmark_rounded,
                    color: SoftUi.brandInk(_c),
                    size: 22,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _c.textPrimary,
                ),
              ),
              if (hasDescription) ...[
                const SizedBox(height: 2),
                Text(
                  project.description!,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13,
                    color: _c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (hasLink) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openLink(context, project.link!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_rounded, size: 14, color: DashboardColors.accent),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          project.link!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 12,
                            color: SoftUi.brandInk(_c),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildFormationRow(Formation formation) {
    final period = (formation.dateFin != null && formation.dateFin!.isNotEmpty)
        ? '${formation.dateDebut} — ${formation.dateFin}'
        : formation.dateDebut;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: SoftUi.tint(_c, DashboardColors.accent),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school_outlined, color: SoftUi.brandInk(_c), size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formation.etablissement,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _c.textPrimary,
                ),
              ),
              if ((formation.filiere ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  formation.filiere!,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13,
                    color: _c.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                period,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 12,
                  color: _c.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationRow(Certification certification) {
    final hasImage = certification.imageBytes != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImage
              ? Image.memory(certification.imageBytes!, width: 44, height: 44, fit: BoxFit.cover)
              : Container(
                  width: 44,
                  height: 44,
                  color: SoftUi.tint(_c, DashboardColors.accent),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: SoftUi.brandInk(_c),
                    size: 20,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                certification.name,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _c.textPrimary,
                ),
              ),
              if ((certification.organism ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  certification.organism!,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13,
                    color: _c.textSecondary,
                  ),
                ),
              ],
              if ((certification.date ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  certification.date!,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 12,
                    color: _c.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkRow(BuildContext context, ProfessionalLink link) {
    return GestureDetector(
      onTap: () => _openLink(context, link.url),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SoftUi.tint(_c, DashboardColors.accent),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.public_rounded, color: SoftUi.brandInk(_c), size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.label,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _c.textPrimary,
                  ),
                ),
                Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 12,
                    color: SoftUi.brandInk(_c),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildSkillChip(String label) {
    return SoftDotBadge(label: label, color: DashboardColors.accent);
  }
}
