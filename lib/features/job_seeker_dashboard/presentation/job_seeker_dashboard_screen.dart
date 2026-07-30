import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/utils/responsive.dart';
import 'package:joem/core/widgets/advice_card.dart';
import 'package:joem/core/widgets/section_header.dart';

import 'widgets/boost_card.dart';
import 'widgets/hero_banner_card.dart';
import 'widgets/job_offer_card.dart';
import 'widgets/job_seeker_bottom_nav.dart';
import 'widgets/job_seeker_top_bar.dart';
import 'widgets/profile_completion_card.dart';
import 'widgets/sector_item.dart';
import 'widgets/stat_mini_card.dart';

/// Dashboard principal de l'espace Chercheur d'emploi — reproduction
/// fidèle de `maquette_employeur.png` (bannière "Trouvez le job qui vous
/// correspond", secteurs, offres recommandées, statistiques latérales).
/// Même design system (couleurs, typos, rayons, ombres, animations) que
/// le Dashboard Employeur.
class JobSeekerDashboardScreen extends StatefulWidget {
  const JobSeekerDashboardScreen({super.key});

  @override
  State<JobSeekerDashboardScreen> createState() => _JobSeekerDashboardScreenState();
}

class _JobSeekerDashboardScreenState extends State<JobSeekerDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _userName = 'Jean';

  static const _candidaturesTrend = [0.2, 0.35, 0.3, 0.5, 0.42, 0.6, 0.55, 0.75];

  static const _sectors = [
    (icon: Icons.code_rounded, label: 'Informatique'),
    (icon: Icons.engineering_outlined, label: 'BTP'),
    (icon: Icons.favorite_border_rounded, label: 'Santé'),
    (icon: Icons.storefront_outlined, label: 'Commerce'),
    (icon: Icons.apartment_rounded, label: 'Hôtellerie'),
    (icon: Icons.more_horiz_rounded, label: 'Autre'),
  ];

  static const _jobs = [
    (
      company: 'Airtel',
      title: 'Technicien Réseau',
      city: 'Antananarivo',
      contractType: 'CDI',
      experience: 'Exp. 2 ans+',
      postedAgo: 'Il y a 2h',
      salaryRange: '800 000 Ar - 1 200 000 Ar',
    ),
    (
      company: 'Orange',
      title: 'Développeur Web',
      city: 'Antananarivo',
      contractType: 'CDI',
      experience: 'Exp. 1-3 ans',
      postedAgo: 'Il y a 4h',
      salaryRange: '1 000 000 Ar - 1 500 000 Ar',
    ),
    (
      company: 'Socolait',
      title: 'Responsable Marketing',
      city: 'Toamasina',
      contractType: 'CDI',
      experience: 'Exp. 3 ans+',
      postedAgo: 'Il y a 6h',
      salaryRange: '600 000 Ar - 900 000 Ar',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(_fade);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isTablet(context);
    final horizontalPadding = isWide ? 40.0 : AppSpacing.lg;

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(horizontalPadding, AppSpacing.lg, horizontalPadding, AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JobSeekerTopBar(
                      isWide: isWide,
                      userInitial: _userName[0],
                      notificationCount: 3,
                      onNotificationTap: () {},
                      onProfileTap: () {},
                      onFilterTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _greeting(),
                    const SizedBox(height: AppSpacing.xl),
                    if (isWide)
                      _buildWideLayout(context)
                    else
                      _buildNarrowLayout(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: JobSeekerBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }

  Widget _greeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour $_userName 👋',
          style: AppTextStyles.poppinsExtraBold.copyWith(
            fontSize: 26,
            color: AppColors.dashboardTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Prêt à saisir de nouvelles opportunités ?',
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 14,
            color: AppColors.dashboardTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _mainColumn(context)),
        const SizedBox(width: AppSpacing.lg),
        SizedBox(width: 320, child: _sidebarColumn(context)),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _mainColumn(context),
        const SizedBox(height: AppSpacing.xl),
        _sidebarColumn(context),
      ],
    );
  }

  Widget _mainColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroBannerCard(onExplore: () {}),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Explorer par secteur', trailingLabel: 'Voir tout', onTrailingTap: () {}),
        const SizedBox(height: AppSpacing.md),
        _sectorRow(),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Emplois recommandés pour vous', trailingLabel: 'Tout voir', onTrailingTap: () {}),
        const SizedBox(height: AppSpacing.md),
        for (final job in _jobs) ...[
          JobOfferCard(
            company: job.company,
            title: job.title,
            city: job.city,
            contractType: job.contractType,
            experience: job.experience,
            postedAgo: job.postedAgo,
            salaryRange: job.salaryRange,
            onApply: () {},
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ProfileCompletionCard(progress: 0.7, onTap: () {}),
      ],
    );
  }

  Widget _sidebarColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatMiniCard(
          icon: Icons.send_outlined,
          title: 'Candidatures',
          value: '12',
          label: 'Envoyées',
          trend: _candidaturesTrend,
        ),
        const SizedBox(height: AppSpacing.md),
        const StatMiniCard(
          icon: Icons.favorite_outline_rounded,
          title: 'Favoris',
          value: '8',
          label: 'Offres sauvegardées',
        ),
        const SizedBox(height: AppSpacing.md),
        const StatMiniCard(
          icon: Icons.event_available_outlined,
          title: 'Entretiens',
          value: '3',
          label: 'À venir',
        ),
        const SizedBox(height: AppSpacing.md),
        const StatMiniCard(
          icon: Icons.visibility_outlined,
          title: 'Vues de profil',
          value: '156',
          label: 'Cette semaine',
        ),
        const SizedBox(height: AppSpacing.md),
        BoostCard(onDiscover: () {}),
        const SizedBox(height: AppSpacing.md),
        const AdviceCard(
          text: 'Les grandes opportunités commencent par une petite action.',
        ),
      ],
    );
  }

  Widget _sectorRow() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _sectors.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final sector = _sectors[index];
          return SectorItem(icon: sector.icon, label: sector.label, onTap: () {});
        },
      ),
    );
  }
}