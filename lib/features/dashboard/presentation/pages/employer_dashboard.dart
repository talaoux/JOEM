import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/login/presentation/login_screen.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_profile_side_panel.dart';
import '../widgets/stat_card.dart';
import '../widgets/interview_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/bottom_navigation.dart';
import 'candidate_search_screen.dart';
import 'job_offer_publish_screen.dart';
import 'employer_notifications_screen.dart';
import 'employer_profile_screen.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 0;

  /// Nombre réel de candidatures reçues que ce recruteur n'a pas encore
  /// lues (ni supprimées) — alimente la pastille du header et de la nav
  /// basse (`countUnreadApplicationNotificationsForEmployer`).
  int _notificationCount = 0;

  /// Offres réellement publiées par ce recruteur (`job_offers`), les plus
  /// récentes en premier — plus de données simulées ici.
  List<JobOffer> _postedOffers = [];
  bool _loadingOffers = true;

  /// Nombre réel de candidatures reçues, toutes offres de ce recruteur
  /// confondues (`job_applications`) — carte "Candidatures".
  int _applicantsCount = 0;

  String get _companyName => _authService.currentUser?.companyName ?? 'Tech Solutions';

  /// `null` pour un compte sans session valide (ne devrait pas arriver
  /// une fois connecté) — les comptes de démo ont un id négatif exprès
  /// (voir `AuthService._demoAccounts`) pour ne jamais entrer en
  /// collision avec un vrai `user_id` autoincrémenté.
  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

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

    _loadPostedOffers();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    final count = await _jobOfferRepository
        .countUnreadApplicationNotificationsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() => _notificationCount = count);
  }

  Future<void> _loadPostedOffers() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) {
      setState(() => _loadingOffers = false);
      return;
    }
    final offers = await _jobOfferRepository.fetchByEmployer(employerUserId);
    final applicantsCount =
        await _jobOfferRepository.countApplicantsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() {
      _postedOffers = offers;
      _applicantsCount = applicantsCount;
      _loadingOffers = false;
    });
  }

  // Candidats dont le profil correspond aux offres publiées par le
  // recruteur (`_postedOffers`) — pas un simple historique d'activité :
  // c'est ce qu'un recruteur veut voir en premier, des profils pertinents
  // pour SES besoins, avec un taux de correspondance.
  final List<Map<String, dynamic>> _suggestedCandidates = [
    {
      'name': 'Hery Andrianina',
      'matchedJob': 'Développeur Flutter',
      'matchPercent': 95,
      'experience': '4 ans',
      'location': 'Antananarivo',
    },
    {
      'name': 'Voahangy Rasoa',
      'matchedJob': 'Designer UI/UX',
      'matchPercent': 88,
      'experience': '3 ans',
      'location': 'Toamasina',
    },
    {
      'name': 'Fanomezantsoa Rakoto',
      'matchedJob': 'Développeur Flutter',
      'matchPercent': 74,
      'experience': '1 an',
      'location': 'Antananarivo',
    },
  ];

  final List<Map<String, dynamic>> _interviews = [
    {
      'candidate': 'Jean Rakoto',
      'date': '15 Jan 2026',
      'time': '09:00',
      'location': 'Antananarivo, Bureau 3',
    },
    {
      'candidate': 'Pierre Andria',
      'date': '18 Jan 2026',
      'time': '14:30',
      'location': 'Visioconférence',
    },
  ];

  String getCandidateName(Map<String, dynamic> candidate) {
    final name = candidate['name'];
    return name != null ? name.toString() : 'Candidat';
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

  /// Calcule le childAspectRatio optimal pour le GridView des Stat Cards
  double _getStatCardAspectRatio(BuildContext context) {
    if (_isSmallScreen(context)) {
      return 1.0;
    } else if (_isMediumScreen(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Padding des cartes responsive
  double _getCardPadding(BuildContext context) {
    if (_isSmallScreen(context)) return 12;
    if (_isMediumScreen(context)) return 16;
    return 20;
  }

  /// Padding inférieur pour éviter le contenu caché derrière BottomNavigationBar
  double _getBottomPadding(BuildContext context) {
    return 200.0;
  }

  late AnimationController _animationController;
  late AnimationController _profilePanelController;

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

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openPublishScreen() async {
    final formData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const JobOfferPublishScreen()),
    );
    if (formData == null || !mounted) return;

    final offer = await _jobOfferRepository.publish(
      employerUserId: _employerUserId ?? 0,
      companyName: _companyName,
      companyLogo: _authService.currentUser?.photoBytes,
      title: formData['title'] as String,
      description: formData['description'] as String,
      location: formData['location'] as String,
      salary: formData['salary'] as String,
      contractType: formData['contractType'] as String,
      posterImage: formData['posterImage'] as Uint8List?,
    );
    if (!mounted) return;

    setState(() {
      _postedOffers.insert(0, offer);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Offre "${offer.title}" publiée avec succès.')),
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
                  // En-tête (recherche de candidats + notification + logo)
                  FadeTransition(
                    opacity: _animationController,
                    child: EmployerHeader(
                      controller: _searchController,
                      notificationCount: _notificationCount,
                      logoBytes: _authService.currentUser?.photoBytes,
                      onLogoTap: _openProfilePanel,
                      onSearchTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CandidateSearchScreen(),
                          ),
                        );
                      },
                      onNotificationTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmployerNotificationsScreen(),
                          ),
                        );
                        _loadNotificationCount();
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Carte Hero - Publier une offre
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
                                  Flexible(
                                    child: ElevatedButton(
                                      onPressed: _openPublishScreen,
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
                  _buildSuggestedCandidatesSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Entretiens du jour
                  _buildInterviewsSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Conseil recruteur
                  _buildAdviceSection(),

                  const SizedBox(height: AppSpacing.sectionSpacing * 2),

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
              secondItemIcon: Icons.search_rounded,
              secondItemLabel: 'Recherche',
              onTap: (index) async {
                if (index == 1 || index == 2 || index == 3 || index == 4) {
                  if (index == 2) {
                    await _openPublishScreen();
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          if (index == 1) return const CandidateSearchScreen();
                          if (index == 3) return const EmployerNotificationsScreen();
                          return const EmployerProfileScreen();
                        },
                      ),
                    );
                    if (index == 3) _loadNotificationCount();
                  }
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
            ),
          ),
        ),
        _buildProfileSidePanel(),
      ],
    );
  }

  /// Le panneau reprend le logo, le nom d'entreprise et la localisation
  /// réellement saisis à l'inscription (session ouverte par `AuthService`) ;
  /// à défaut (comptes de démo par ex.), il retombe sur les valeurs par
  /// défaut de `EmployerProfileSidePanel`.
  Widget _buildProfileSidePanel() {
    final user = _authService.currentUser;
    final recruiterName = (user != null && (user.firstName.isNotEmpty || user.lastName.isNotEmpty))
        ? '${user.firstName} ${user.lastName}'.trim()
        : null;
    final location = (user?.localisation != null && user!.localisation!.trim().isNotEmpty)
        ? user.localisation!.trim()
        : null;

    return EmployerProfileSidePanel(
      animation: _profilePanelController,
      onClose: _closeProfilePanel,
      onLogoutTap: _logout,
      companyName: _companyName,
      recruiterName: recruiterName ?? 'Jean Dupont',
      logoBytes: user?.photoBytes,
      location: location ?? 'Antananarivo, Analamanga',
      profileCompletion: user?.employerProfileCompletion ?? 0.0,
      onProfileCompletionTap: () {
        _closeProfilePanel();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployerProfileScreen()),
        );
      },
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
                childAspectRatio: _getStatCardAspectRatio(context),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                children: [
                  StatCard(
                    title: 'Offres actives',
                    value: '${_postedOffers.length}',
                    icon: Icons.work_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    miniChart: 'Sur ${_postedOffers.length} publiées',
                  ),
                  StatCard(
                    title: 'Candidatures',
                    value: '$_applicantsCount',
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    miniChart: 'Sur ${_postedOffers.length} offre${_postedOffers.length > 1 ? 's' : ''}',
                  ),
                  StatCard(
                    title: 'Entretiens',
                    value: '${_interviews.length}',
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    miniChart: 'Cette semaine',
                  ),
                  StatCard(
                    title: 'Vues totales',
                    value: '156',
                    icon: Icons.visibility_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    miniChart: '+23 cette semaine',
                  ),
                ],
              ),
            ),
          ],
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
            if (!_loadingOffers && _postedOffers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: Text(
                  "Vous n'avez publié aucune offre pour le moment.",
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textTertiary,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _postedOffers.length,
                itemBuilder: (context, index) {
                  final offer = _postedOffers[index];
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.title,
                                  style: AppTypography.jobTitle.copyWith(
                                    fontSize: titleFontSize,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: isSmallScreen ? 12 : 14,
                                          color: AppColors.textTertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          offer.location,
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
                                          Icons.work_outline_rounded,
                                          size: isSmallScreen ? 12 : 14,
                                          color: AppColors.textTertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          offer.contractType,
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
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: isSmallScreen ? 14 : 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      offer.publishedLabel,
                                      style: AppTypography.interSemiBold.copyWith(
                                        fontSize: badgeFontSize,
                                        color: AppColors.primary,
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

  /// Vert à partir de 85% de correspondance, bleu entre 70 et 84%, ambre
  /// en dessous — permet au recruteur de repérer les meilleurs profils
  /// d'un coup d'œil.
  Color _matchColor(int percent) {
    if (percent >= 85) return const Color(0xFF10B981);
    if (percent >= 70) return const Color(0xFF3B82F6);
    return const Color(0xFFF59E0B);
  }

  Widget _buildSuggestedCandidatesSection() {
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
                    'Candidats suggérés',
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
              ),
              child: Text(
                'Profils qui correspondent le mieux à vos offres publiées',
                style: AppTypography.interRegular.copyWith(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestedCandidates.length,
              itemBuilder: (context, index) {
                final candidate = _suggestedCandidates[index];
                final matchPercent = candidate['matchPercent'] as int;
                final matchColor = _matchColor(matchPercent);
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
                                      'Pour "${candidate['matchedJob']}" · ${candidate['experience']}',
                                      style: AppTypography.companyName.copyWith(
                                        fontSize: positionFontSize,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: iconSize,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      candidate['location'] as String,
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
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: matchColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: isSmallScreen ? 14 : 16,
                                  color: matchColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '$matchPercent%',
                                    style: AppTypography.interSemiBold.copyWith(
                                      fontSize: badgeFontSize,
                                      color: matchColor,
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

  Widget _buildInterviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.safeAreaHorizontal,
          ),
          child: Text('Entretiens du jour', style: AppTypography.sectionTitle),
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
                company: interview['candidate'] as String,
                date: interview['date'] as String,
                time: interview['time'] as String,
                location: interview['location'] as String,
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
      child: const AdviceCard(
        title: 'Conseil recruteur',
        text: 'Rédigez des offres claires et détaillées pour attirer plus de candidats qualifiés.',
      ),
    );
  }
}
