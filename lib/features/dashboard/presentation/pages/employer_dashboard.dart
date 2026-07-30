import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/hero_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/category_card.dart';
import '../widgets/job_card.dart';
import '../widgets/interview_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/bottom_navigation.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 0;
  late AnimationController _animationController;

  late List<Map<String, dynamic>> _postedJobs;
  
  String get _companyName => _authService.currentUser?.companyName ?? 'Tech Solutions';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.verySlow,
      vsync: this,
    )..forward();
    
    _postedJobs = [
      {
        'title': 'Développeur Flutter',
        'company': _companyName,
        'location': 'Antananarivo',
        'salary': '2 500 000 Ar',
        'contractType': 'CDI',
        'isNew': true,
        'isFavorite': false,
        'applications': 12,
        'status': 'Active',
        'date': '12 Juil 2024',
      },
      {
        'title': 'Designer UI/UX',
        'company': _companyName,
        'location': 'Toamasina',
        'salary': '1 800 000 Ar',
        'contractType': 'CDD',
        'isNew': false,
        'isFavorite': false,
        'applications': 8,
        'status': 'Active',
        'date': '8 Juil 2024',
      },
    ];
  }

  final List<Map<String, dynamic>> _candidates = [
    {
      'name': 'Jean Rakoto',
      'position': 'Développeur Flutter',
      'experience': '3 ans',
      'status': 'Nouveau',
    },
    {
      'name': 'Marie Razafy',
      'position': 'Designer UI/UX',
      'experience': '2 ans',
      'status': 'Vue',
    },
    {
      'name': 'Pierre Andria',
      'position': 'Chef de Projet',
      'experience': '5 ans',
      'status': 'Entretien',
    },
  ];

  String getCandidateName(Map<String, dynamic> candidate) {
    final name = candidate['name'];
    return name != null ? name.toString() : 'Candidat';
  }

  String getCandidatePosition(Map<String, dynamic> candidate) {
    final position = candidate['position'];
    return position != null ? position.toString() : 'Poste';
  }

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
  
  /// Taille de police responsive pour les valeurs de statistiques
  double _getStatValueFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 16;
    if (_isMediumScreen(context)) return 18;
    return 20;
  }
  
  /// Taille de police responsive pour les titres de statistiques
  double _getStatTitleFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 8;
    if (_isMediumScreen(context)) return 9;
    return 10;
  }
  
  /// Taille de police responsive pour les sous-titres de statistiques
  double _getStatSubtitleFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 7;
    if (_isMediumScreen(context)) return 7.5;
    return 8;
  }
  
  /// Taille d'icône responsive pour les cartes de statistiques
  double _getStatIconSize(BuildContext context) {
    if (_isSmallScreen(context)) return 14;
    if (_isMediumScreen(context)) return 16;
    return 18;
  }
  
  /// Taille du conteneur d'icône responsive
  double _getStatIconContainerSize(BuildContext context) {
    if (_isSmallScreen(context)) return 24;
    if (_isMediumScreen(context)) return 28;
    return 32;
  }
  
  /// Padding des cartes responsive
  double _getCardPadding(BuildContext context) {
    if (_isSmallScreen(context)) return 12;
    if (_isMediumScreen(context)) return 16;
    return 20;
  }
  
  /// Espacement vertical responsive dans les cartes
  double _getCardSpacing(BuildContext context) {
    if (_isSmallScreen(context)) return 4;
    if (_isMediumScreen(context)) return 6;
    return 8;
  }
  
  /// Calcule le childAspectRatio optimal pour le GridView selon la largeur d'écran
  /// Problème: childAspectRatio fixe causait overflow sur petits écrans
  /// Problème persistant: Ratio calculé trop petit, overflow de 12px
  /// Solution: Adapter le ratio au nouveau contenu simplifié (icône+valeur sur même ligne)
  double _getStatCardAspectRatio(BuildContext context) {
    // Ratio = width / height, donc un ratio plus grand = carte moins haute
    // Avec le nouveau contenu simplifié, les cartes peuvent être moins hautes
    if (_isSmallScreen(context)) {
      // Pour écran 320px: carte ~140px de large, ratio 1.0 = hauteur ~140px
      return 1.0;
    } else if (_isMediumScreen(context)) {
      // Pour écran 375px: carte ~165px de large, ratio 1.1 = hauteur ~150px
      return 1.1;
    } else {
      // Pour écran 390px+: carte ~175px de large, ratio 1.2 = hauteur ~146px
      return 1.2;
    }
  }
  
  /// Padding inférieur pour éviter le contenu caché derrière BottomNavigationBar
  /// Problème: Le contenu pouvait être caché derrière la barre de navigation
  /// Problème persistant: Overflow de 18px même avec 80px de marge
  /// Solution: Utiliser un padding fixe très conservateur de 200px
  double _getBottomPadding(BuildContext context) {
    return 200.0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeTransition(
                opacity: _animationController,
                child: DashboardHeader(
                  userName: _authService.currentUser?.firstName ?? 'Employeur',
                ),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Message de salutation
              FadeTransition(
                opacity: _animationController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeAreaHorizontal,
                  ),
                  child: GreetingSection(
                    firstName: _authService.currentUser?.firstName ?? 'Employeur',
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Barre de recherche
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: AppDurations.easeOutCubic,
                )),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeAreaHorizontal,
                  ),
                  child: SearchBarWidget(
                    controller: _searchController,
                    onFilterTap: () {},
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Carte Hero - Actions rapides recruteur
              // Problème: Row avec contenu fixe causait overflow sur petits écrans (< 360px)
              // Solution: Adapter les tailles de texte et padding selon la largeur d'écran
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = _isSmallScreen(context);
                  final titleFontSize = isSmallScreen ? 16.0 : 18.0;
                  final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
                  final buttonTextFontSize = isSmallScreen ? 12.0 : 14.0;
                  final buttonIconSize = isSmallScreen ? 18.0 : 20.0;
                  final buttonPaddingHorizontal = isSmallScreen ? AppSpacing.sm : AppSpacing.lg;
                  final buttonPaddingVertical = isSmallScreen ? AppSpacing.sm : AppSpacing.md;
                  
                  return FadeTransition(
                    opacity: _animationController,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.95,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: AppDurations.easeOutCubic,
                      )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.safeAreaHorizontal,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(_getCardPadding(context)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryLightest, AppColors.primaryLighter],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: AppRadius.cardRadius,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Publier une offre',
                                      style: AppTypography.poppinsSemiBold.copyWith(
                                        fontSize: titleFontSize,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Trouvez les meilleurs talents',
                                      style: AppTypography.interRegular.copyWith(
                                        fontSize: subtitleFontSize,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // Bouton avec Flexible pour éviter overflow sur petits écrans
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: buttonPaddingHorizontal,
                                      vertical: buttonPaddingVertical,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: buttonIconSize),
                                      SizedBox(width: AppSpacing.sm),
                                      Flexible(
                                        child: Text(
                                          'Nouvelle offre',
                                          style: TextStyle(
                                            fontSize: buttonTextFontSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Statistiques
              _buildStatisticsSection(),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Offres publiées
              _buildPostedJobsSection(),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Candidats récents
              _buildCandidatesSection(),

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
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
        ),
      ),
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
              child: Text(
                'Tableau de bord',
                style: AppTypography.sectionTitle,
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
                crossAxisCount: 2,
                // childAspectRatio dynamique selon la taille d'écran
                // Problème: Ratio fixe causait overflow sur petits écrans
                // Solution: Calculer le ratio optimal dynamiquement
                childAspectRatio: _getStatCardAspectRatio(context),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                children: [
                  _buildStatCard(
                    title: 'Offres actives',
                    value: '3',
                    subtitle: 'Sur 5 publiées',
                    icon: Icons.work_outline_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  _buildStatCard(
                    title: 'Candidatures',
                    value: '25',
                    subtitle: '+5 aujourd\'hui',
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _buildStatCard(
                    title: 'Entretiens',
                    value: '4',
                    subtitle: 'Cette semaine',
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildStatCard(
                    title: 'Vues totales',
                    value: '156',
                    subtitle: '+23 cette semaine',
                    icon: Icons.visibility_outlined,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tailles responsive selon la largeur d'écran
        final iconSize = _getStatIconSize(context);
        final iconContainerSize = _getStatIconContainerSize(context);
        final cardPadding = _getCardPadding(context);
        final valueFontSize = _getStatValueFontSize(context);
        final titleFontSize = _getStatTitleFontSize(context);
        
        // Problème: Trop de contenu causait overflow malgré les ratios très conservateurs
        // Solution: Simplifier drastiquement le contenu - ne garder que l'essentiel
        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.statCardRadius,
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône et valeur sur la même ligne pour économiser l'espace
              Row(
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(iconContainerSize * 0.3),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.statNumber.copyWith(
                        fontSize: valueFontSize,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Titre uniquement (supprimer le sous-titre)
              Text(
                title,
                style: AppTypography.statLabel.copyWith(
                  fontSize: titleFontSize,
                  color: AppColors.textSecondary,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostedJobsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = _isSmallScreen(context);
        final iconSize = isSmallScreen ? 24.0 : 28.0;
        final iconContainerSize = isSmallScreen ? 48.0 : 56.0;
        final titleFontSize = isSmallScreen ? 14.0 : 16.0;
        final infoFontSize = isSmallScreen ? 11.0 : 13.0;
        final badgeFontSize = isSmallScreen ? 10.0 : 12.0;
        
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
                    'Mes offres d\'emploi',
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _postedJobs.length,
              itemBuilder: (context, index) {
                final job = _postedJobs[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: AppSpacing.md,
                    left: AppSpacing.safeAreaHorizontal,
                    right: AppSpacing.safeAreaHorizontal,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(_getCardPadding(context)),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppRadius.cardRadius,
                      boxShadow: AppShadows.cardShadow,
                    ),
                    child: Row(
                      children: [
                        // Icône conteneur
                        Container(
                          width: iconContainerSize,
                          height: iconContainerSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryLightest, AppColors.primaryLighter],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(iconContainerSize * 0.28),
                          ),
                          child: Icon(
                            Icons.work_outline_rounded,
                            color: AppColors.primary,
                            size: iconSize,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Contenu texte avec Expanded pour éviter overflow
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['title'],
                                style: AppTypography.jobTitle.copyWith(
                                  fontSize: titleFontSize,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              // Wrap pour gérer le débordement sur petits écrans
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: isSmallScreen ? 12 : 14,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${job['applications']} candidatures',
                                        style: AppTypography.jobInfo.copyWith(
                                          fontSize: infoFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: isSmallScreen ? 12 : 14,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        job['date'],
                                        style: AppTypography.jobInfo.copyWith(
                                          fontSize: infoFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Badge de statut - utiliser Flexible pour éviter overflow
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: job['status'] == 'Active'
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  job['status'] == 'Active'
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_rounded,
                                  size: isSmallScreen ? 14 : 16,
                                  color: job['status'] == 'Active'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    job['status'],
                                    style: AppTypography.interSemiBold.copyWith(
                                      fontSize: badgeFontSize,
                                      color: job['status'] == 'Active'
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCandidatesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = _isSmallScreen(context);
        final avatarSize = isSmallScreen ? 40.0 : 48.0;
        final avatarFontSize = isSmallScreen ? 16.0 : 20.0;
        final nameFontSize = isSmallScreen ? 13.0 : 15.0;
        final positionFontSize = isSmallScreen ? 11.0 : 13.0;
        final badgeFontSize = isSmallScreen ? 10.0 : 12.0;
        final iconSize = isSmallScreen ? 12.0 : 14.0;
        
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
                    'Candidats récents',
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _candidates.length,
              itemBuilder: (context, index) {
                final candidate = _candidates[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: AppSpacing.md,
                    left: AppSpacing.safeAreaHorizontal,
                    right: AppSpacing.safeAreaHorizontal,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(_getCardPadding(context)),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppRadius.cardRadius,
                      boxShadow: AppShadows.cardShadow,
                    ),
                    child: Row(
                      children: [
                        // Avatar conteneur
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryLightest, AppColors.primaryLighter],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(avatarSize / 2),
                          ),
                          child: Center(
                            child: Text(
                              getCandidateName(candidate).isNotEmpty
                                  ? getCandidateName(candidate)[0]
                                  : '?',
                              style: AppTypography.poppinsSemiBold.copyWith(
                                color: AppColors.primary,
                                fontSize: avatarFontSize,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Contenu texte avec Expanded pour éviter overflow
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getCandidateName(candidate),
                                style: AppTypography.interviewCompany.copyWith(
                                  fontSize: nameFontSize,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.work_outline_rounded,
                                    size: iconSize,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      getCandidatePosition(candidate),
                                      style: AppTypography.companyName.copyWith(
                                        fontSize: positionFontSize,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Badge de statut - utiliser Flexible pour éviter overflow
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: (candidate['status'] ?? 'Nouveau') == 'Nouveau'
                                  ? AppColors.primary.withOpacity(0.1)
                                  : (candidate['status'] ?? 'Nouveau') == 'Vue'
                                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                                      : const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (candidate['status'] ?? 'Nouveau') == 'Nouveau'
                                      ? Icons.new_releases_rounded
                                      : (candidate['status'] ?? 'Nouveau') == 'Vue'
                                          ? Icons.visibility_rounded
                                          : Icons.event_available_rounded,
                                  size: isSmallScreen ? 14 : 16,
                                  color: (candidate['status'] ?? 'Nouveau') == 'Nouveau'
                                      ? AppColors.primary
                                      : (candidate['status'] ?? 'Nouveau') == 'Vue'
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    candidate['status'] ?? 'Nouveau',
                                    style: AppTypography.interSemiBold.copyWith(
                                      fontSize: badgeFontSize,
                                      color: (candidate['status'] ?? 'Nouveau') == 'Nouveau'
                                          ? AppColors.primary
                                          : (candidate['status'] ?? 'Nouveau') == 'Vue'
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFF10B981),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}