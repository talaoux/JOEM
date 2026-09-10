import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/login/presentation/login_screen.dart';
import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/employer_header.dart';
import '../widgets/employer_profile_side_panel.dart';
import '../widgets/employer_offer_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/interview_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/bottom_navigation.dart';
import 'candidate_application_detail_screen.dart';
import 'candidate_profile_view_screen.dart';
import 'candidate_search_screen.dart';
import 'employer_offers_screen.dart';
import 'employer_settings_screen.dart';
import 'employer_stats_screens.dart';
import 'job_offer_publish_screen.dart';
import 'offer_applicants_screen.dart';
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
  final InterviewRepository _interviewRepository = const InterviewRepository();
  final AccountSearchRepository _accountSearchRepository = const AccountSearchRepository();
  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 0;

  /// Nombre d'offres affichées directement sur le dashboard — le reste est
  /// accessible via "Voir tout" (`EmployerOffersScreen`).
  static const int _dashboardOffersPreview = 3;

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

  /// Candidatures reçues, offre par offre (`job_offer_id` -> nombre) — pour
  /// le compteur affiché sur chaque carte de "Mes offres d'emploi".
  Map<int, int> _applicantCountsByOffer = {};

  /// Nombre total de vues (candidats distincts) sur toutes les offres de ce
  /// recruteur (`job_offer_views`) — carte "Vues totales".
  int _totalViews = 0;

  /// Entretiens planifiés aujourd'hui / à venir pour ce recruteur
  /// (`interviews`) — section "Entretiens du jour"/"Mes prochains
  /// entretiens" et carte statistique "Entretiens".
  List<Interview> _todayInterviews = [];
  List<Interview> _upcomingInterviews = [];
  bool _loadingInterviews = true;

  String get _companyName => _authService.currentUser?.companyName ?? 'Tech Solutions';

  /// Palette de surfaces (fond de page, cartes, texte) dynamique selon le
  /// "Mode nuit" de `EmployerSettingsScreen` — voir `AppSurfaceColors` /
  /// `DisplayPreferencesController`. En mode clair, ces valeurs sont
  /// identiques aux anciennes constantes `AppColors` utilisées ici.
  AppSurfaceColors get _colors => AppSurfaceColors.of(context);

  /// `null` pour un compte sans session valide (ne devrait pas arriver
  /// une fois connecté) — les comptes de démo ont un id négatif exprès
  /// (voir `AuthService._demoAccounts`) pour ne jamais entrer en
  /// collision avec un vrai `user_id` autoincrémenté.
  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    final reducedAnimations = _authService.currentUser?.reducedAnimationsEnabled ?? false;
    _animationController = AnimationController(
      duration: reducedAnimations ? Duration.zero : AppDurations.verySlow,
      vsync: this,
    )..forward();
    _profilePanelController = AnimationController(
      duration: reducedAnimations ? Duration.zero : const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadPostedOffers().then((_) => _loadSuggestedCandidates());
    _loadNotificationCount();
    _loadInterviews();
  }

  /// Recharge tout ce que le dashboard affiche — appelé au retour d'un
  /// sous-écran susceptible d'avoir changé les données (publication ou
  /// suppression d'offre, planification d'entretien, lecture d'une
  /// candidature...).
  Future<void> _reloadAll() async {
    await _loadPostedOffers();
    await _loadSuggestedCandidates();
    await _loadNotificationCount();
    await _loadInterviews();
  }

  Future<void> _loadNotificationCount() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    // "Nouvelles candidatures" désactivé dans `EmployerSettingsScreen` :
    // la pastille reste à 0, les candidatures restent consultables depuis
    // `EmployerNotificationsScreen`.
    if (_authService.currentUser?.notificationsEnabled == false) {
      if (!mounted) return;
      setState(() => _notificationCount = 0);
      return;
    }
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
    final applicantCountsByOffer =
        await _jobOfferRepository.fetchApplicantCountsByOffer(employerUserId);
    final totalViews =
        await _jobOfferRepository.countOfferViewsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() {
      _postedOffers = offers;
      _applicantsCount = applicantsCount;
      _applicantCountsByOffer = applicantCountsByOffer;
      _totalViews = totalViews;
      _loadingOffers = false;
    });
  }

  Future<void> _loadInterviews() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) {
      setState(() => _loadingInterviews = false);
      return;
    }
    final today = await _interviewRepository.fetchTodayForEmployer(employerUserId);
    final upcoming = await _interviewRepository.fetchUpcomingForEmployer(employerUserId);
    if (!mounted) return;
    setState(() {
      _todayInterviews = today;
      _upcomingInterviews = upcoming;
      _loadingInterviews = false;
    });
  }

  // "Candidats suggérés" : TOUS les candidats réellement inscrits (profil
  // visible), triés par pertinence pour les offres publiées par le
  // recruteur (`_postedOffers`). Ceux dont le titre/les compétences/la
  // localisation recoupent une offre remontent en tête avec leur taux de
  // correspondance ; les autres suivent, sans score. Rien n'est simulé.
  List<_SuggestedCandidate> _suggestedCandidates = [];
  bool _loadingSuggestedCandidates = true;

  static const _matchStopWords = {
    'de', 'du', 'la', 'le', 'et', 'un', 'une', 'les', 'des', 'pour',
    'avec', 'dans', 'en', 'sur', 'aux', 'au', 'à', 'ou', 'the', 'and',
  };

  Future<void> _loadSuggestedCandidates() async {
    final candidates = await _accountSearchRepository.fetchAllJobSeekers();
    if (candidates.isEmpty) {
      if (!mounted) return;
      setState(() {
        _suggestedCandidates = [];
        _loadingSuggestedCandidates = false;
      });
      return;
    }

    // Mots significatifs de chaque offre publiée, regroupés par offre.
    final offerWords = <String, Set<String>>{};
    for (final offer in _postedOffers) {
      final words = offer.title
          .toLowerCase()
          .split(RegExp(r'[^a-zà-ÿ0-9]+'))
          .where((w) => w.length >= 3 && !_matchStopWords.contains(w))
          .toSet();
      if (words.isNotEmpty) offerWords[offer.title] = words;
    }

    final suggestions = candidates.map((candidate) {
      // Texte cherchable du candidat : titre + compétences + localisation.
      final haystack = [
        candidate.position ?? '',
        candidate.localisation ?? '',
        ...candidate.skills,
      ].join(' ').toLowerCase();

      int bestPercent = 0;
      String? bestJob;
      offerWords.forEach((jobTitle, words) {
        final hits = words.where((w) => haystack.contains(w)).length;
        if (hits == 0) return;
        final percent = ((hits / words.length) * 100).round().clamp(1, 100);
        if (percent > bestPercent) {
          bestPercent = percent;
          bestJob = jobTitle;
        }
      });

      return _SuggestedCandidate(
        candidate: candidate,
        matchPercent: bestPercent > 0 ? bestPercent : null,
        matchedJob: bestJob,
      );
    }).toList()
      ..sort((a, b) {
        final pa = a.matchPercent ?? -1;
        final pb = b.matchPercent ?? -1;
        if (pa != pb) return pb.compareTo(pa);
        return a.candidate.fullName.toLowerCase().compareTo(b.candidate.fullName.toLowerCase());
      });

    if (!mounted) return;
    setState(() {
      _suggestedCandidates = suggestions;
      _loadingSuggestedCandidates = false;
    });
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
    // Recalcule stats, compteurs par offre et "Candidats suggérés" (la
    // nouvelle offre peut faire remonter des candidats jusque-là sans score).
    _reloadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _colors.background,
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
                        _reloadAll();
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
                                            color: _colors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Trouvez les meilleurs talents',
                                          style: AppTypography.interRegular.copyWith(
                                            fontSize: subtitleFontSize,
                                            color: _colors.textSecondary,
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
                    _reloadAll();
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
      onSettingsTap: () async {
        _closeProfilePanel();
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployerSettingsScreen()),
        );
        _reloadAll();
      },
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
      // Mêmes 4 chiffres (et mêmes écrans de détail) que le "Tableau de
      // bord" du corps du dashboard.
      stats: [
        {
          'title': 'Offres publiées',
          'value': '${_postedOffers.length}',
          'icon': Icons.work_outline_rounded,
          'iconColor': const Color(0xFF3B82F6),
          'onTap': () => _openStatScreenFromPanel(const EmployerOffersScreen()),
        },
        {
          'title': 'Candidatures reçues',
          'value': '$_applicantsCount',
          'icon': Icons.people_outline_rounded,
          'iconColor': const Color(0xFF10B981),
          'onTap': () => _openStatScreenFromPanel(const EmployerNotificationsScreen()),
        },
        {
          'title': 'Entretiens programmés',
          'value': '${_upcomingInterviews.length}',
          'icon': Icons.calendar_today_rounded,
          'iconColor': const Color(0xFFF59E0B),
          'onTap': () => _openStatScreenFromPanel(const EmployerInterviewsScreen()),
        },
        {
          'title': 'Vues totales',
          'value': '$_totalViews',
          'icon': Icons.visibility_rounded,
          'iconColor': const Color(0xFF8B5CF6),
          'onTap': () => _openStatScreenFromPanel(const EmployerOfferViewsScreen()),
        },
      ],
    );
  }

  /// Comme [_openStatScreen] mais ferme d'abord le panneau latéral.
  void _openStatScreenFromPanel(Widget screen) {
    _closeProfilePanel();
    _openStatScreen(screen);
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
                style: _colors.sectionTitle,
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
                    onTap: () => _openStatScreen(const EmployerOffersScreen()),
                  ),
                  StatCard(
                    title: 'Candidatures',
                    value: '$_applicantsCount',
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    miniChart: 'Sur ${_postedOffers.length} offre${_postedOffers.length > 1 ? 's' : ''}',
                    onTap: () => _openStatScreen(const EmployerNotificationsScreen()),
                  ),
                  StatCard(
                    title: 'Entretiens',
                    value: '${_upcomingInterviews.length}',
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    miniChart: 'À venir',
                    onTap: () => _openStatScreen(const EmployerInterviewsScreen()),
                  ),
                  StatCard(
                    title: 'Vues totales',
                    value: '$_totalViews',
                    icon: Icons.visibility_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    miniChart: 'Sur vos offres',
                    onTap: () => _openStatScreen(const EmployerOfferViewsScreen()),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Ouvre l'écran de détail derrière une carte du "Tableau de bord", puis
  /// recharge toutes les données au retour (les compteurs peuvent avoir
  /// changé — offre supprimée, candidature lue...).
  Future<void> _openStatScreen(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    _reloadAll();
  }

  Future<void> _openOfferApplicants(JobOffer offer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OfferApplicantsScreen(offer: offer)),
    );
    _reloadAll();
  }

  Future<void> _openAllOffers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployerOffersScreen()),
    );
    _reloadAll();
  }

  Widget _buildPostedJobsSection() {
    final preview = _postedOffers.take(_dashboardOffersPreview).toList();
    final hasMore = _postedOffers.length > _dashboardOffersPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mes offres d\'emploi', style: _colors.sectionTitle),
              if (_postedOffers.isNotEmpty)
                TextButton(
                  onPressed: _openAllOffers,
                  child: Text(
                    hasMore ? 'Voir tout (${_postedOffers.length})' : 'Voir tout',
                    style: AppTypography.secondaryButton.copyWith(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loadingOffers)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_postedOffers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
            child: Text(
              "Vous n'avez publié aucune offre pour le moment.",
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _colors.textTertiary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
            itemCount: preview.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final offer = preview[index];
              return EmployerOfferCard(
                offer: offer,
                applicantCount: _applicantCountsByOffer[offer.id] ?? 0,
                onTap: () => _openOfferApplicants(offer),
              );
            },
          ),
      ],
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

  Future<void> _openCandidateProfile(CandidateSearchResult candidate) async {
    final viewerId = _authService.currentUser?.id;
    if (viewerId != null && viewerId.isNotEmpty) {
      await _accountSearchRepository.recordProfileView(
        profileUserId: candidate.userId,
        viewerUserId: viewerId,
      );
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CandidateProfileViewScreen(candidate: candidate)),
    );
  }

  Widget _buildSuggestedCandidatesSection() {
    final preview = _suggestedCandidates.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Candidats suggérés', style: _colors.sectionTitle),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CandidateSearchScreen()),
                  );
                },
                child: Text(
                  'Voir tout',
                  style: AppTypography.secondaryButton.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
          child: Text(
            _postedOffers.isEmpty
                ? 'Tous les candidats inscrits — publiez une offre pour les voir classés par pertinence'
                : 'Tous les candidats inscrits, les plus proches de vos offres en tête',
            style: AppTypography.interRegular.copyWith(
              fontSize: 12,
              color: _colors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loadingSuggestedCandidates)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_suggestedCandidates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
            child: Text(
              "Aucun candidat inscrit pour le moment.",
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: _colors.textTertiary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
            itemCount: preview.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _buildSuggestedCandidateCard(preview[index]),
          ),
      ],
    );
  }

  Widget _buildSuggestedCandidateCard(_SuggestedCandidate suggestion) {
    final candidate = suggestion.candidate;
    final name = candidate.fullName.isNotEmpty ? candidate.fullName : 'Candidat';
    final position = candidate.position?.trim() ?? '';
    final location = candidate.localisation?.trim() ?? '';
    final matchPercent = suggestion.matchPercent;
    final subtitle = matchPercent != null
        ? 'Pour "${suggestion.matchedJob}"'
        : (position.isNotEmpty ? position : 'Chercheur d\'emploi');

    return InkWell(
      onTap: () => _openCandidateProfile(candidate),
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: EdgeInsets.all(_getCardPadding(context)),
        decoration: BoxDecoration(
          color: _colors.background,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLightest, AppColors.primaryLighter],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                image: candidate.photo != null
                    ? DecorationImage(image: MemoryImage(candidate.photo!), fit: BoxFit.cover)
                    : null,
              ),
              child: candidate.photo == null
                  ? Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: AppTypography.poppinsSemiBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.interviewCompany
                        .copyWith(fontSize: 15, color: _colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _colors.companyName.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: _colors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: _colors.jobInfo.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (matchPercent != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: _matchColor(matchPercent).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: _matchColor(matchPercent)),
                    const SizedBox(width: 2),
                    Text(
                      '$matchPercent%',
                      style: AppTypography.interSemiBold.copyWith(
                        fontSize: 11,
                        color: _matchColor(matchPercent),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Icon(Icons.chevron_right_rounded, color: _colors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewsSection() {
    // "Entretiens du jour" si au moins un entretien aujourd'hui ; sinon on
    // bascule sur "Mes prochains entretiens" (les 3 plus proches à venir).
    final showToday = _todayInterviews.isNotEmpty;
    final list = showToday
        ? _todayInterviews
        : _upcomingInterviews.take(3).toList();
    final title = showToday ? 'Entretiens du jour' : 'Mes prochains entretiens';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
          child: Text(title, style: _colors.sectionTitle),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loadingInterviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
            child: Text(
              "Aucun entretien planifié. Ouvrez une candidature reçue pour en planifier un.",
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _colors.textTertiary,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final interview = list[index];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                  left: AppSpacing.safeAreaHorizontal,
                  right: AppSpacing.safeAreaHorizontal,
                ),
                child: InterviewCard(
                  company: interview.candidateName.trim().isNotEmpty
                      ? interview.candidateName.trim()
                      : 'Candidat',
                  date: interview.dateLabel,
                  time: interview.time,
                  location: interview.offerTitle.trim().isNotEmpty
                      ? '${interview.locationLabel} · ${interview.offerTitle}'
                      : interview.locationLabel,
                  onViewDetails: () => _openInterviewCandidate(interview),
                ),
              );
            },
          ),
      ],
    );
  }

  /// "Voir" sur une carte d'entretien : ouvre le détail de la candidature
  /// liée (profil du candidat + offre + entretien planifié) si elle existe
  /// encore, sinon informe que la candidature a été retirée.
  Future<void> _openInterviewCandidate(Interview interview) async {
    final applicationId = interview.jobApplicationId;
    if (applicationId == null) {
      _showInterviewGone();
      return;
    }
    final applications =
        await _jobOfferRepository.fetchApplicationsForOffer(interview.jobOfferId ?? -1);
    final match = applications.where((a) => a.applicationId == applicationId).toList();
    if (!mounted) return;
    if (match.isEmpty) {
      _showInterviewGone();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateApplicationDetailScreen(notification: match.first),
      ),
    );
    _reloadAll();
  }

  void _showInterviewGone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La candidature liée à cet entretien a été retirée.')),
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

/// Un candidat inscrit proposé dans "Candidats suggérés" — le profil réel
/// ([candidate]) plus, quand il recoupe une offre publiée par le recruteur,
/// le taux de correspondance ([matchPercent], `null` sinon) et l'intitulé
/// de l'offre la mieux matchée ([matchedJob]).
class _SuggestedCandidate {
  const _SuggestedCandidate({
    required this.candidate,
    this.matchPercent,
    this.matchedJob,
  });

  final CandidateSearchResult candidate;
  final int? matchPercent;
  final String? matchedJob;
}
