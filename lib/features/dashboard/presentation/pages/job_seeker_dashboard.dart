import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../widgets/job_seeker_header.dart';
import 'job_categories_screen.dart';
import 'job_search_screen.dart';
import 'job_publish_screen.dart';
import 'job_notifications_screen.dart';
import 'job_profile_screen.dart';
import '../widgets/hero_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/category_card.dart';
import '../widgets/job_card.dart';
import '../widgets/interview_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/profile_side_panel.dart';
import '../../../../features/welcome/presentation/welcome_screen.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';

class JobSeekerDashboard extends StatefulWidget {
  const JobSeekerDashboard({super.key});

  @override
  State<JobSeekerDashboard> createState() => _JobSeekerDashboardState();
}

class _JobSeekerDashboardState extends State<JobSeekerDashboard>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  int _currentNavIndex = 0;
  final int _notificationCount = 5;

  // Données mockées
  final List<Map<String, dynamic>> _categories = [
    {'title': 'Informatique', 'icon': Icons.computer_rounded},
    {'title': 'Commerce', 'icon': Icons.shopping_bag_rounded},
    {'title': 'Santé', 'icon': Icons.medical_services_rounded},
    {'title': 'BTP', 'icon': Icons.construction_rounded},
    {'title': 'Finance', 'icon': Icons.account_balance_rounded},
    {'title': 'Marketing', 'icon': Icons.campaign_rounded},
    {'title': 'Education', 'icon': Icons.school_rounded},
    {'title': 'Industrie', 'icon': Icons.precision_manufacturing_rounded},
  ];

  final List<Map<String, dynamic>> _jobs = [
    {
      'title': 'Développeur Flutter',
      'company': 'Tech Solutions',
      'location': 'Antananarivo',
      'salary': '2 500 000 Ar',
      'contractType': 'CDI',
      'isNew': true,
      'isFavorite': false,
    },
    {
      'title': 'Designer UI/UX',
      'company': 'Creative Agency',
      'location': 'Toamasina',
      'salary': '1 800 000 Ar',
      'contractType': 'CDD',
      'isNew': true,
      'isFavorite': true,
    },
    {
      'title': 'Chef de Projet',
      'company': 'Digital Corp',
      'location': 'Antananarivo',
      'salary': '3 200 000 Ar',
      'contractType': 'CDI',
      'isNew': false,
      'isFavorite': false,
    },
  ];

  final List<Map<String, dynamic>> _interviews = [
    {
      'company': 'Tech Solutions',
      'date': '15 Jan 2026',
      'time': '09:00',
      'location': 'Antananarivo, Bureau 3',
    },
    {
      'company': 'Creative Agency',
      'date': '18 Jan 2026',
      'time': '14:30',
      'location': 'Toamasina, Centre ville',
    },
  ];

  late AnimationController _animationController;
  late AnimationController _profilePanelController;

  // ===== RESPONSIVE HELPERS =====
  // Ces méthodes adaptent les tailles selon la largeur de l'écran
  // pour éviter les overflow sur tous les appareils

  /// Retourne true si l'écran est petit (< 360px)
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Retourne true si l'écran est moyen (360-390px)
  bool _isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 390;
  }

  /// Retourne true si l'écran est large (>= 390px)
  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 390;
  }

  /// Calcule le childAspectRatio optimal pour le GridView des Stat Cards
  double _getStatCardAspectRatio(BuildContext context) {
    // Ratio = width / height, donc un ratio plus grand = carte moins haute
    if (_isSmallScreen(context)) {
      return 1.0;
    } else if (_isMediumScreen(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Calcule le childAspectRatio optimal pour le GridView des Catégories
  double _getCategoryCardAspectRatio(BuildContext context) {
    // Ratio = width / height
    if (_isSmallScreen(context)) {
      return 0.75;
    } else if (_isMediumScreen(context)) {
      return 0.8;
    } else {
      return 0.85;
    }
  }

  /// Padding inférieur para éviter le contenu caché derrière BottomNavigationBar
  /// Problème: Le contenu pouvait être caché derrière la barre de navigation
  /// Problème persistant: Overflow de 18px même avec 80px de marge
  /// Solution: Utiliser un padding fixe très conservateur de 200px
  double _getBottomPadding(BuildContext context) {
    return 200.0;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.verySlow,
      vsync: this,
    )..forward();
    _profilePanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _profilePanelController.dispose();
    super.dispose();
  }

  void _openProfilePanel() {
    _profilePanelController.forward();
  }

  void _closeProfilePanel() {
    _profilePanelController.reverse();
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (barre de recherche + notification + avatar)
                  FadeTransition(
                    opacity: _animationController,
                    child: JobSeekerHeader(
                      controller: _searchController,
                      notificationCount: _notificationCount,
                      avatarBytes: _authService.currentUser?.photoBytes,
                      onAvatarTap: _openProfilePanel,
                      onSearchTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JobSearchScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Offres recommandées
                  _buildRecommendedJobsSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Carte Hero
                  FadeTransition(
                    opacity: _animationController,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: AppDurations.easeOutCubic,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.safeAreaHorizontal,
                        ),
                        child: HeroCard(onFindJobTap: () {}),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Statistiques
                  _buildStatisticsSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Catégories
                  _buildCategoriesSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Entretiens
                  _buildInterviewsSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Conseil du jour
                  _buildAdviceSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing * 2),

                  // Padding inférieur pour éviter le contenu caché derrière BottomNavigationBar
                  SizedBox(height: _getBottomPadding(context)),
                ],
              ),
            ),
          ),
          // Bottom Navigation
          bottomNavigationBar: FadeTransition(
            opacity: _animationController,
            child: BottomNavigation(
              currentIndex: _currentNavIndex,
              onTap: (index) async {
                if (index == 1 || index == 2 || index == 3 || index == 4) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        if (index == 1) return const JobCategoriesScreen();
                        if (index == 2) return const JobPublishScreen();
                        if (index == 3) return const JobNotificationsScreen();
                        return const JobProfileScreen();
                      },
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _currentNavIndex = 0;
                    });
                  }
                  return;
                }
                setState(() {
                  _currentNavIndex = index;
                });
              },
              notificationCount: _notificationCount,
              accentColor: OnboardingColors.violet,
            ),
          ),
        ),
        _buildProfileSidePanel(),
      ],
    );
  }

  /// Le panneau reprend la photo, le nom et le titre professionnel
  /// réellement saisis à l'inscription (session ouverte par
  /// `AuthService`) ; à défaut (comptes de démo sans photo par ex.), il
  /// retombe sur les valeurs par défaut de `ProfileSidePanel`.
  Widget _buildProfileSidePanel() {
    final user = _authService.currentUser;
    final fullName = (user != null && (user.firstName.isNotEmpty || user.lastName.isNotEmpty))
        ? '${user.firstName} ${user.lastName}'.trim()
        : null;
    final position = (user?.position != null && user!.position!.trim().isNotEmpty)
        ? user.position!.trim()
        : null;

    return ProfileSidePanel(
      animation: _profilePanelController,
      onClose: _closeProfilePanel,
      onLogoutTap: _logout,
      fullName: fullName ?? 'Marie Martin',
      avatarBytes: user?.photoBytes,
      skills: position ?? "Développeur Flutter . Chercheur d'emploi",
    );
  }

  Widget _buildStatisticsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
              ),
              child: Text('Statistiques', style: AppTypography.sectionTitle),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                // childAspectRatio dynamique selon la taille d'écran
                childAspectRatio: _getStatCardAspectRatio(context),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                children: [
                  StatCard(
                    title: 'Candidatures envoyées',
                    value: '12',
                    icon: Icons.send_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    miniChart: '+3 cette semaine',
                  ),
                  StatCard(
                    title: 'Entretiens',
                    value: '3',
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF10B981),
                    miniChart: '2 à venir',
                  ),
                  StatCard(
                    title: 'Favoris',
                    value: '8',
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFEF4444),
                  ),
                  StatCard(
                    title: 'Réponses reçues',
                    value: '5',
                    icon: Icons.mark_chat_read_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    miniChart: '+2 nouvelles',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catégories populaires',
                    style: AppTypography.sectionTitle,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Voir tout',
                      style: AppTypography.secondaryButton.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                // childAspectRatio dynamique selon la taille d'écran
                childAspectRatio: _getCategoryCardAspectRatio(context),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                children: _categories.map((category) {
                  return CategoryCard(
                    title: category['title'],
                    icon: category['icon'],
                    onTap: () {},
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.safeAreaHorizontal,
          ),
          child: Text(
            'Recommandées pour vous',
            style: AppTypography.sectionTitle,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _jobs.length,
          itemBuilder: (context, index) {
            final job = _jobs[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: AppSpacing.md,
                left: AppSpacing.safeAreaHorizontal,
                right: AppSpacing.safeAreaHorizontal,
              ),
              child: JobCard(
                jobTitle: job['title'],
                company: job['company'],
                location: job['location'],
                salary: job['salary'],
                contractType: job['contractType'],
                isNew: job['isNew'],
                isFavorite: job['isFavorite'],
                onApply: () {},
                onFavoriteTap: () {},
              ),
            );
          },
        ),
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Voir plus',
              style: AppTypography.secondaryButton.copyWith(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.safeAreaHorizontal,
          ),
          child: Text(
            'Mes prochains entretiens',
            style: AppTypography.sectionTitle,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _interviews.length,
          itemBuilder: (context, index) {
            final interview = _interviews[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: AppSpacing.md,
                left: AppSpacing.safeAreaHorizontal,
                right: AppSpacing.safeAreaHorizontal,
              ),
              child: InterviewCard(
                company: interview['company'],
                date: interview['date'],
                time: interview['time'],
                location: interview['location'],
                onViewDetails: () {},
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdviceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeAreaHorizontal,
      ),
      child: AdviceCard(
        title: 'Conseil carrière',
        text:
            'Mettez à jour votre CV régulièrement et personnalisez votre lettre de motivation pour chaque candidature.',
      ),
    );
  }
}
