import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_search_repository.dart';
import '../widgets/portfolio_hero_theme.dart';
import 'portfolio_project_detail_screen.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Portfolio complet d'un candidat, tel que consulté par un recruteur — une
/// seule page immersive façon "site portfolio personnel" (hero + sections
/// qui s'enchaînent), plutôt que la liste de cartes compactes de
/// `CandidateProfileViewScreen`. Ouverte depuis le bouton "Voir tout" de la
/// section "Portfolio" de cet écran. Purement en lecture seule côté
/// recruteur, mêmes données que [CandidateSearchResult] (aucune requête
/// supplémentaire) — à l'exception de la couleur du thème (icône palette),
/// modifiable uniquement par le candidat lui-même en mode aperçu (voir
/// [isPreview]).
class CandidateFullPortfolioScreen extends StatefulWidget {
  const CandidateFullPortfolioScreen({
    super.key,
    required this.candidate,
    this.isPreview = false,
  });

  final CandidateSearchResult candidate;

  /// `true` quand c'est le candidat lui-même qui consulte cet écran depuis
  /// `PortfolioScreen` ("Aperçu recruteur") plutôt qu'un recruteur — affiche
  /// un bandeau explicatif et l'icône palette pour changer la couleur du
  /// thème. Le reste du rendu est identique (c'est justement le but :
  /// montrer ce qu'un recruteur voit).
  final bool isPreview;

  @override
  State<CandidateFullPortfolioScreen> createState() => _CandidateFullPortfolioScreenState();
}

class _CandidateFullPortfolioScreenState extends State<CandidateFullPortfolioScreen> {
  late String? _themeKey = widget.candidate.portfolioThemeColor;

  CandidateSearchResult get candidate => widget.candidate;
  bool get isPreview => widget.isPreview;
  PortfolioHeroTheme get _theme => PortfolioHeroTheme.resolve(_themeKey);

  Future<void> _openThemePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ThemePickerSheet(selectedKey: _theme.key),
    );
    if (selected == null || selected == _themeKey) return;

    setState(() => _themeKey = selected);
    await AuthService().updatePortfolioThemeColor(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lavande très pâle du nouveau design (écran toujours en clair).
      backgroundColor: DashboardColors.page,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: staggered([
            _buildHero(context),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.safeAreaHorizontal,
                  AppSpacing.xxl,
                  AppSpacing.safeAreaHorizontal,
                  AppSpacing.sectionSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    _buildAboutSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSkillsSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildExperienceSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildFormationsSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildProjectsSection(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCertificationsSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLinksSection(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildContactSection(),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ===== Hero =====

  Widget _buildHero(BuildContext context) {
    final fullName = candidate.fullName.isEmpty ? 'Candidat' : candidate.fullName;
    final position = candidate.position?.trim() ?? '';
    final location = candidate.localisation?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(gradient: _theme.toLinearGradient()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.safeAreaHorizontal,
          AppSpacing.sm,
          AppSpacing.safeAreaHorizontal,
          56,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                if (isPreview) ...[
                  _buildRoundIconButton(
                    icon: Icons.palette_outlined,
                    onTap: _openThemePicker,
                    tooltip: 'Changer la couleur du portfolio',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                const _PortfolioBadge(),
              ],
            ),
            if (isPreview) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 15, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aperçu — voici ce que voient les recruteurs de votre portfolio.',
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  backgroundImage: candidate.photo != null ? MemoryImage(candidate.photo!) : null,
                  child: candidate.photo == null
                      ? const Icon(Icons.person_rounded, color: Colors.white, size: 44)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                fullName,
                textAlign: TextAlign.center,
                style: AppTypography.poppinsExtraBold.copyWith(
                  fontSize: 22,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            if (position.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  position,
                  textAlign: TextAlign.center,
                  style: AppTypography.interMedium.copyWith(
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withValues(alpha: 0.75)),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (candidate.professionalLinks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: candidate.professionalLinks
                      .map((link) => _buildRoundIconButton(
                            icon: _iconForLink(link.url),
                            onTap: () => _openLink(context, link.url),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  // ===== Sections =====

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatTile('${candidate.portfolioProjects.length}', 'Projets')),
        _buildStatDivider(),
        Expanded(child: _buildStatTile('${candidate.skills.length}', 'Compétences')),
        _buildStatDivider(),
        Expanded(child: _buildStatTile('${candidate.certifications.length}', 'Certifications')),
      ],
    );
  }

  Widget _buildStatDivider() => Container(width: 1, height: 32, color: const Color(0xFFF0F0F3));

  Widget _buildStatTile(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.frauncesBold.copyWith(fontSize: 24, color: _theme.accentDeep, height: 1.0),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.interRegular.copyWith(fontSize: 11.5, color: const Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final about = candidate.presentation?.trim() ?? '';
    final objectifs = candidate.objectifs?.trim() ?? '';
    if (about.isEmpty && objectifs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (about.isNotEmpty) ...[
          _buildSectionTitle('À propos'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            about,
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
        if (objectifs.isNotEmpty) ...[
          SizedBox(height: about.isNotEmpty ? AppSpacing.lg : 0),
          _buildSectionTitle('Objectifs'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            objectifs,
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    if (candidate.skills.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Compétences'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: candidate.skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: _theme.tint.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                skill,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: _theme.accentDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    if (candidate.experiences.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Expérience professionnelle'),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < candidate.experiences.length; i++)
          _buildTimelineRow(
            icon: Icons.work_outline_rounded,
            isLast: i == candidate.experiences.length - 1,
            child: _buildExperienceContent(candidate.experiences[i]),
          ),
      ],
    );
  }

  Widget _buildExperienceContent(JobExperience experience) {
    final period = experience.enCours
        ? '${experience.dateDebut} - Aujourd\'hui'
        : (experience.dateFin != null && experience.dateFin!.isNotEmpty)
            ? '${experience.dateDebut} - ${experience.dateFin}'
            : experience.dateDebut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          experience.poste,
          style: AppTypography.interRegular.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          experience.entreprise,
          style: AppTypography.interRegular.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _theme.accentDeep,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          period,
          style: AppTypography.interRegular.copyWith(fontSize: 12, color: const Color(0xFF9CA3AF)),
        ),
        if ((experience.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            experience.description!,
            style: AppTypography.interRegular.copyWith(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormationsSection() {
    if (candidate.formations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Formation'),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < candidate.formations.length; i++)
          _buildTimelineRow(
            icon: Icons.school_outlined,
            isLast: i == candidate.formations.length - 1,
            child: _buildFormationContent(candidate.formations[i]),
          ),
      ],
    );
  }

  Widget _buildFormationContent(Formation formation) {
    final period = (formation.dateFin != null && formation.dateFin!.isNotEmpty)
        ? '${formation.dateDebut} — ${formation.dateFin}'
        : formation.dateDebut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formation.etablissement,
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        if ((formation.filiere ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            formation.filiere!,
            style: AppTypography.interRegular.copyWith(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          period,
          style: AppTypography.interRegular.copyWith(fontSize: 12, color: const Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({required IconData icon, required bool isLast, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _theme.tint.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: _theme.accentDeep, size: 18),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  color: const Color(0xFFF0F0F3),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsSection(BuildContext context) {
    if (candidate.portfolioProjects.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Projets réalisés'),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < candidate.portfolioProjects.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _buildProjectCard(context, candidate.portfolioProjects[i]),
        ],
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, PortfolioProject project) {
    final hasImage = project.imageBytes != null;
    final hasDescription = (project.description ?? '').trim().isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PortfolioProjectDetailScreen(project: project)),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDEDF3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hasImage
                ? Image.memory(project.imageBytes!, width: double.infinity, height: 140, fit: BoxFit.cover)
                : Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_theme.accent, _theme.accentDeep],
                      ),
                    ),
                    child: const Icon(Icons.collections_bookmark_rounded, color: Colors.white, size: 40),
                  ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      project.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 12.5,
                        color: const Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (project.technologies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: project.technologies.map((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _theme.tint.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tech,
                            style: AppTypography.interRegular.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _theme.accentDeep,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection() {
    if (candidate.certifications.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Certifications'),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < candidate.certifications.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _buildCertificationCard(candidate.certifications[i]),
        ],
      ],
    );
  }

  Widget _buildCertificationCard(Certification certification) {
    final hasImage = certification.imageBytes != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? Image.memory(certification.imageBytes!, width: 44, height: 44, fit: BoxFit.cover)
                : Container(
                    width: 44,
                    height: 44,
                    color: _theme.tint.withValues(alpha: 0.6),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: _theme.accentDeep,
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
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                if ((certification.organism ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    certification.organism!,
                    style: AppTypography.interRegular.copyWith(fontSize: 13, color: const Color(0xFF6B7280)),
                  ),
                ],
                if ((certification.date ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    certification.date!,
                    style: AppTypography.interRegular.copyWith(fontSize: 12, color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    if (candidate.professionalLinks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Mes liens'),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDEDF3)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < candidate.professionalLinks.length; i++) ...[
                if (i > 0) const Divider(height: 24, color: Color(0xFFF0F0F3)),
                _buildLinkRow(context, candidate.professionalLinks[i]),
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
              color: _theme.tint.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForLink(link.url), color: _theme.accentDeep, size: 16),
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
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.interRegular.copyWith(fontSize: 12, color: _theme.accent),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: Color(0xFF9CA3AF), size: 16),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    final telephone = candidate.telephone?.trim() ?? '';
    final location = candidate.localisation?.trim() ?? '';
    if (telephone.isEmpty && location.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Coordonnées'),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDEDF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (telephone.isNotEmpty) ...[
                _buildContactRow(Icons.call_rounded, telephone),
                if (location.isNotEmpty) const SizedBox(height: AppSpacing.sm),
              ],
              if (location.isNotEmpty) _buildContactRow(Icons.location_on_outlined, location),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _theme.accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppTypography.interRegular.copyWith(fontSize: 14, color: const Color(0xFF1A1A2E)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.frauncesBold.copyWith(
        fontSize: 21,
        color: const Color(0xFF1A1A2E),
        height: 1.2,
      ),
    );
  }

  IconData _iconForLink(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('github')) return Icons.integration_instructions_outlined;
    if (lower.contains('linkedin')) return Icons.business_center_outlined;
    if (lower.contains('behance') || lower.contains('dribbble')) return Icons.palette_outlined;
    return Icons.public_rounded;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir ce lien.")),
      );
    }
  }
}

class _PortfolioBadge extends StatelessWidget {
  const _PortfolioBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Portfolio',
        style: AppTypography.interSemiBold.copyWith(fontSize: 12, color: Colors.white),
      ),
    );
  }
}

/// Feuille de choix de couleur du thème du Portfolio (icône palette du
/// hero, mode aperçu candidat uniquement) — une puce par [PortfolioHeroTheme],
/// coche celle actuellement sélectionnée. Le choix est persisté par
/// l'appelant (`AuthService.updatePortfolioThemeColor`), cette feuille ne
/// fait que renvoyer la clé choisie.
class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet({required this.selectedKey});

  final String selectedKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.safeAreaHorizontal,
        AppSpacing.md,
        AppSpacing.safeAreaHorizontal,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            'Couleur du portfolio',
            style: AppTypography.frauncesBold.copyWith(fontSize: 21, color: const Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text(
            "Cette couleur s'applique à l'arrière-plan de votre portfolio et sera visible par les recruteurs.",
            style: AppTypography.interRegular.copyWith(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: PortfolioHeroTheme.all.map((theme) {
              final selected = theme.key == selectedKey;
              return GestureDetector(
                onTap: () => Navigator.pop(context, theme.key),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: theme.toLinearGradient(),
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: theme.accent, width: 3)
                            : Border.all(color: Colors.transparent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: theme.accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      theme.label,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 11.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
