import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/core/utils/responsive.dart';
import 'package:joem/core/widgets/advice_card.dart';
import 'package:joem/core/widgets/dashboard_card.dart';
import 'package:joem/core/widgets/section_header.dart';

import 'widgets/candidate_card.dart';
import 'widgets/create_offer_button.dart';
import 'widgets/dashboard_bottom_nav.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_search_bar.dart';
import 'widgets/interview_card.dart';
import 'widgets/job_card.dart';
import 'widgets/kpi_card.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/statistics_chart_card.dart';

/// Dashboard principal de l'espace Employeur — première page après la
/// connexion d'un recruteur. Même design system (couleurs, typos,
/// rayons, ombres, animations) que le Dashboard Candidat.
class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _employerName = 'Heritiana';

  static const _kpis = [
    (icon: Icons.work_outline_rounded, value: '27', label: 'Offres publiées', trend: [0.2, 0.35, 0.3, 0.5, 0.45, 0.65, 0.8]),
    (icon: Icons.people_outline_rounded, value: '154', label: 'Candidatures reçues', trend: [0.3, 0.4, 0.35, 0.55, 0.6, 0.5, 0.75]),
    (icon: Icons.event_available_outlined, value: '18', label: 'Entretiens', trend: [0.4, 0.3, 0.5, 0.45, 0.6, 0.55, 0.7]),
    (icon: Icons.emoji_events_outlined, value: '9', label: 'Embauches', trend: [0.1, 0.25, 0.2, 0.4, 0.35, 0.5, 0.6]),
  ];

  static const _quickActions = [
    (icon: Icons.post_add_rounded, title: 'Publier une offre'),
    (icon: Icons.work_outline_rounded, title: 'Mes offres'),
    (icon: Icons.people_outline_rounded, title: 'Candidats'),
    (icon: Icons.calendar_month_outlined, title: 'Calendrier'),
  ];

  static const _jobs = [
    (title: 'Développeur Flutter', city: 'Antananarivo', salary: '1 500 000 Ar', candidates: 18),
    (title: 'Comptable Senior', city: 'Antananarivo', salary: '900 000 Ar', candidates: 12),
    (title: 'Chargée de Marketing', city: 'Toamasina', salary: '800 000 Ar', candidates: 7),
  ];

  static const _candidates = [
    (name: 'Mialy Rasoanaivo', jobTitle: 'Développeuse Flutter', city: 'Antananarivo', experience: '3 ans d\'expérience'),
    (name: 'Tojo Andrianina', jobTitle: 'Comptable', city: 'Antananarivo', experience: '5 ans d\'expérience'),
    (name: 'Fara Ravaka', jobTitle: 'Chargée de Marketing', city: 'Toamasina', experience: '2 ans d\'expérience'),
  ];

  static const _candidatureTrend = [0.2, 0.35, 0.3, 0.5, 0.42, 0.6, 0.55, 0.75, 0.68, 0.85];

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
                    DashboardHeader(
                      userInitial: _employerName[0],
                      notificationCount: 3,
                      onNotificationTap: () {},
                      onProfileTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (isWide) ...[
                      Row(
                        children: [
                          Expanded(child: _greeting()),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(flex: 1, child: DashboardSearchBar(onFilterTap: () {})),
                        ],
                      ),
                    ] else ...[
                      _greeting(),
                      const SizedBox(height: AppSpacing.lg),
                      DashboardSearchBar(onFilterTap: () {}),
                    ],
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
      bottomNavigationBar: DashboardBottomNav(
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
          'Bonjour $_employerName 👋',
          style: AppTextStyles.poppinsExtraBold.copyWith(
            fontSize: 26,
            color: AppColors.dashboardTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bienvenue sur votre espace Employeur.',
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
        _kpiGrid(context),
        const SizedBox(height: AppSpacing.lg),
        CreateOfferButton(onTap: () {}),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Actions rapides',
          style: AppTextStyles.poppinsSemiBold.copyWith(
            fontSize: 18,
            color: AppColors.dashboardTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _quickActionsGrid(context),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Mes offres récentes', trailingLabel: 'Voir tout', onTrailingTap: () {}),
        const SizedBox(height: AppSpacing.md),
        for (final job in _jobs) ...[
          JobCard(
            title: job.title,
            city: job.city,
            salary: job.salary,
            candidateCount: job.candidates,
            onEdit: () {},
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        const SectionHeader(title: 'Nouveaux candidats'),
        const SizedBox(height: AppSpacing.md),
        for (final candidate in _candidates) ...[
          CandidateCard(
            name: candidate.name,
            jobTitle: candidate.jobTitle,
            city: candidate.city,
            experience: candidate.experience,
            onViewProfile: () {},
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _sidebarColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatisticsChartCard(values: _candidatureTrend),
        const SizedBox(height: AppSpacing.md),
        _interviewsCard(),
        const SizedBox(height: AppSpacing.md),
        const AdviceCard(
          text: 'Les annonces avec un salaire affiché obtiennent généralement '
              'davantage de candidatures.',
        ),
      ],
    );
  }

  Widget _kpiGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.85,
      children: [
        for (final kpi in _kpis)
          KpiCard(icon: kpi.icon, value: kpi.value, label: kpi.label, trend: kpi.trend),
      ],
    );
  }

  Widget _quickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.05,
      children: [
        for (final action in _quickActions)
          QuickActionCard(icon: action.icon, title: action.title, onTap: () {}),
      ],
    );
  }

  Widget _interviewsCard() {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entretiens aujourd\'hui',
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 15,
              color: AppColors.dashboardTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const InterviewCard(time: '14:00', candidateName: 'Jean Rakoto', jobTitle: 'Développeur Flutter'),
          const SizedBox(height: 14),
          const InterviewCard(time: '16:30', candidateName: 'Marie Rabe', jobTitle: 'Comptable'),
        ],
      ),
    );
  }
}