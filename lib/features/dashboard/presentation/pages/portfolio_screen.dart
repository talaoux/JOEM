import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/portfolio_hero_theme.dart';
import 'candidate_full_portfolio_screen.dart';
import 'edit_job_seeker_profile_screen.dart';
import 'job_categories_screen.dart';
import 'job_notifications_screen.dart';
import 'job_profile_screen.dart';
import 'job_seeker_settings_screen.dart';
import 'portfolio_about_screen.dart';
import 'portfolio_certifications_screen.dart';
import 'portfolio_experience_screen.dart';
import 'portfolio_projects_screen.dart';
import 'portfolio_skills_screen.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Écran principal du Portfolio candidat — vitrine professionnelle réelle
/// (pas un simple CV) : carte d'identité, indicateur de complétion et accès
/// aux 6 sous-écrans détaillés (`PortfolioAboutScreen`, `PortfolioSkillsScreen`,
/// `PortfolioExperienceScreen`, `PortfolioProjectsScreen`,
/// `PortfolioCertificationsScreen` — "Formations" pointe vers
/// `PortfolioExperienceScreen`, qui porte la section "Parcours"). Toutes ces
/// données réapparaissent en lecture seule sur `CandidateProfileViewScreen`
/// pour un recruteur. Remplace l'ancien onglet "Publier" (composeur de post
/// social mocké, jamais persisté).
///
/// Tant qu'aucune des 6 sections n'est renseignée (`User.portfolioCompletion
/// == 0`), l'écran affiche un état vide/onboarding sombre plutôt qu'une
/// vitrine sans contenu — voir [_PortfolioEmptyState]. "Plus tard" ne fait
/// que masquer cet état pour la session en cours (pas de table dédiée pour
/// retenir ce choix durablement) ; il réapparaît tant que le portfolio reste
/// entièrement vide.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final AuthService _authService = AuthService();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  final InterviewRepository _interviewRepository = const InterviewRepository();
  final AccountSearchRepository _accountSearchRepository = const AccountSearchRepository();

  int _notificationCount = 0;
  int _profileViews = 0;
  bool _emptyStateDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _loadProfileViews();
  }

  Future<void> _loadNotificationCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final offersMuted = _authService.currentUser?.notificationsEnabled == false;
    final offerCount = offersMuted
        ? 0
        : await _jobOfferRepository.countUnreadNotificationsForJobSeeker(userId);
    final interviewCount =
        await _interviewRepository.countUnreadNotificationsForJobSeeker(userId);
    final decisionCount =
        await _jobOfferRepository.countUnreadDecisionNotificationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() => _notificationCount = offerCount + interviewCount + decisionCount);
  }

  Future<void> _loadProfileViews() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final count = await _accountSearchRepository.countProfileViews(userId);
    if (!mounted) return;
    setState(() => _profileViews = count);
  }

  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    late final Widget screen;
    switch (index) {
      case 1:
        screen = const JobCategoriesScreen();
        break;
      case 3:
        screen = const JobNotificationsScreen();
        break;
      default:
        screen = const JobProfileScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openSection(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    setState(() {});
  }

  /// Ouvre le portfolio complet tel qu'un recruteur le voit
  /// (`CandidateFullPortfolioScreen`, `CandidateProfileViewScreen` →
  /// "Voir tout"), mais à partir du compte candidat lui-même — jusqu'ici le
  /// seul moyen de voir ce rendu était d'être un recruteur consultant le
  /// profil depuis `CandidateSearchScreen`.
  void _openPreview() {
    final user = _authService.currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateFullPortfolioScreen(
          candidate: CandidateSearchResult.fromUser(user),
          isPreview: true,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JobSeekerSettingsScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user != null && user.portfolioCompletion == 0 && !_emptyStateDismissed) {
      return _PortfolioEmptyState(
        onComplete: () => _openSection(const PortfolioAboutScreen()),
        onDismiss: () => setState(() => _emptyStateDismissed = true),
      );
    }

    final colors = AppSurfaceColors.of(context);
    final theme = PortfolioHeroTheme.resolve(user?.portfolioThemeColor);

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.safeAreaHorizontal,
              vertical: AppSpacing.headerPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: staggered([
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Portfolio',
                        style: AppTypography.frauncesBold.copyWith(
                          fontSize: 28,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
                    ),
                  ],
                ),
                Text(
                  'Votre vitrine professionnelle',
                  style: AppTypography.interSemiBold.copyWith(
                    fontSize: 15,
                    color: theme.accentDeep,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Présentez vos compétences, vos réalisations et votre parcours "
                  "pour attirer l'attention des recruteurs.",
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildProfileCard(colors, user, theme),
                const SizedBox(height: AppSpacing.md),
                _buildCompletionCard(colors, user, theme),
                const SizedBox(height: AppSpacing.lg),
                const SerifSectionTitle('Aperçu de mon portfolio'),
                const SizedBox(height: AppSpacing.md),
                _buildOverviewGrid(colors, user, theme),
                const SizedBox(height: AppSpacing.sectionSpacing),
              ]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 2,
        onTap: _onNavTap,
        thirdItemIcon: Icons.collections_bookmark_rounded,
        thirdItemLabel: 'Portfolio',
        notificationCount: _notificationCount,
        accentColor: DashboardColors.accent,
      softHomeButton: true,
      ),
    );
  }

  Widget _buildProfileCard(AppSurfaceColors colors, User? user, PortfolioHeroTheme theme) {
    final fullName = (user != null && (user.firstName.isNotEmpty || user.lastName.isNotEmpty))
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Vous';
    final position = user?.position?.trim() ?? '';
    final location = user?.localisation?.trim() ?? '';
    final projectCount = user?.portfolioProjects.length ?? 0;

    return SoftCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: SoftUi.tint(colors, theme.accent), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: SoftUi.tint(colors, theme.accent),
                  backgroundImage:
                      user?.photoBytes != null ? MemoryImage(user!.photoBytes!) : null,
                  child: user?.photoBytes == null
                      ? Icon(Icons.person_rounded, color: theme.accent, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppTypography.frauncesBold.copyWith(
                        fontSize: 20,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position.isNotEmpty ? position : "Chercheur d'emploi",
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: colors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: AppTypography.interRegular.copyWith(
                              fontSize: 12,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(theme, '$projectCount projet${projectCount > 1 ? 's' : ''}'),
              _buildStatChip(theme, '$_profileViews vue${_profileViews > 1 ? 's' : ''}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Boutons pilules à teinte pâle aux couleurs du thème choisi.
          Row(
            children: [
              Expanded(
                child: SoftPillButton(
                  label: 'Modifier',
                  icon: Icons.edit_outlined,
                  compact: true,
                  color: theme.accent,
                  onPressed: () => _openSection(const EditJobSeekerProfileScreen()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SoftPillButton(
                  label: 'Aperçu recruteur',
                  icon: Icons.visibility_outlined,
                  compact: true,
                  color: theme.accent,
                  onPressed: _openPreview,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(PortfolioHeroTheme theme, String label) {
    return SoftDotBadge(label: label, color: theme.accentDeep);
  }

  Widget _buildCompletionCard(AppSurfaceColors colors, User? user, PortfolioHeroTheme theme) {
    final sections = user?.portfolioSections ?? const [];
    final completion = user?.portfolioCompletion ?? 0;
    final percent = (completion * 100).round();

    // Bloc teinté façon "48 messages reçus · objectif 500" de la maquette.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: SoftUi.isDark(colors) ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent %',
                style: AppTypography.frauncesBold.copyWith(
                  fontSize: 38,
                  color: colors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'portfolio complété',
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: colors.background,
              valueColor: AlwaysStoppedAnimation(SoftUi.accentInk(colors, theme.accent)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 4.2,
            children: [
              for (final section in sections)
                _buildChecklistRow(colors, theme, section.$1, section.$2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(AppSurfaceColors colors, PortfolioHeroTheme theme, String label, bool filled) {
    return Row(
      children: [
        Icon(
          filled ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: filled ? SoftUi.accentInk(colors, theme.accent) : colors.textTertiary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.interRegular.copyWith(
              fontSize: 12.5,
              fontWeight: filled ? FontWeight.w500 : FontWeight.w400,
              color: filled ? colors.textPrimary : colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid(AppSurfaceColors colors, User? user, PortfolioHeroTheme theme) {
    final projectCount = user?.portfolioProjects.length ?? 0;
    final skillCount = user?.skills.length ?? 0;
    final experienceCount = user?.experiences.length ?? 0;
    final formationCount = user?.formations.length ?? 0;
    final certificationCount = user?.certifications.length ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _OverviewTile(
          theme: theme,
          icon: Icons.badge_outlined,
          title: 'À propos',
          subtitle: 'Présentation',
          onTap: () => _openSection(const PortfolioAboutScreen()),
        ),
        _OverviewTile(
          theme: theme,
          icon: Icons.stars_rounded,
          title: 'Compétences',
          subtitle: skillCount == 0 ? 'Aucune pour le moment' : '$skillCount compétences',
          onTap: () => _openSection(const PortfolioSkillsScreen()),
        ),
        _OverviewTile(
          theme: theme,
          icon: Icons.work_outline_rounded,
          title: 'Expériences',
          subtitle: experienceCount == 0 ? 'Aucune pour le moment' : '$experienceCount postes',
          onTap: () => _openSection(const PortfolioExperienceScreen()),
        ),
        _OverviewTile(
          theme: theme,
          icon: Icons.collections_bookmark_rounded,
          title: 'Projets',
          subtitle:
              projectCount == 0 ? 'Aucun pour le moment' : '$projectCount réalisations',
          badgeCount: projectCount,
          onTap: () => _openSection(const PortfolioProjectsScreen()),
        ),
        _OverviewTile(
          theme: theme,
          icon: Icons.school_outlined,
          title: 'Formations',
          subtitle: formationCount == 0 ? 'Aucune pour le moment' : '$formationCount parcours',
          onTap: () => _openSection(const PortfolioExperienceScreen()),
        ),
        _OverviewTile(
          theme: theme,
          icon: Icons.workspace_premium_outlined,
          title: 'Certifications',
          subtitle:
              certificationCount == 0 ? "Aucune pour l'instant" : '$certificationCount obtenues',
          onTap: () => _openSection(const PortfolioCertificationsScreen()),
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final PortfolioHeroTheme theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: SoftUi.tint(colors, theme.accent),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: SoftUi.accentInk(colors, theme.accent), size: 19),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTypography.interSemiBold.copyWith(
                    fontSize: 13.5,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 11.5,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftUi.tint(colors, theme.accent),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: AppTypography.frauncesBold.copyWith(
                      color: SoftUi.accentInk(colors, theme.accent),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }
}

/// État vide/onboarding du Portfolio (fond sombre premium) — affiché tant
/// qu'aucune des 6 sections n'est renseignée, plutôt qu'une vitrine sans
/// contenu. "Plus tard" masque cet état pour la session en cours seulement
/// (voir doc de [PortfolioScreen]).
class _PortfolioEmptyState extends StatelessWidget {
  const _PortfolioEmptyState({required this.onComplete, required this.onDismiss});

  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final ink = SoftUi.brandInk(colors);
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
            child: SoftCard(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: SoftUi.tint(colors, DashboardColors.accent),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.collections_bookmark_rounded, color: ink, size: 38),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Un portfolio qui\nfait la différence',
                    textAlign: TextAlign.center,
                    style: AppTypography.frauncesBold.copyWith(
                      fontSize: 24,
                      height: 1.2,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Montrez aux recruteurs ce que vous savez faire, au-delà de votre CV.',
                    textAlign: TextAlign.center,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 13.5,
                      height: 1.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final label in const [
                    'Vos compétences',
                    'Vos projets',
                    'Votre parcours',
                    'Vos réalisations',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: SoftUi.tint(colors, DashboardColors.accent),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded, size: 14, color: ink),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: AppTypography.interMedium.copyWith(
                              fontSize: 13.5,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SoftPrimaryButton(
                    label: 'Compléter mon portfolio',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onComplete,
                  ),
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(
                      'Plus tard',
                      style: AppTypography.interMedium.copyWith(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
