import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/job_seeker_header.dart';
import 'profile_stats_screens.dart';
import 'category_offers_screen.dart';
import 'job_categories_screen.dart';
import 'job_search_screen.dart';
import 'job_publish_screen.dart';
import 'job_notifications_screen.dart';
import 'job_profile_screen.dart';
import 'job_offer_detail_screen.dart';
import 'job_seeker_settings_screen.dart';
import '../widgets/hero_card.dart';
import '../widgets/category_card.dart';
import '../widgets/job_offer_post_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/profile_side_panel.dart';
import '../../../../features/login/presentation/login_screen.dart';
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
  int _notificationCount = 0;

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

  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  final InterviewRepository _interviewRepository = const InterviewRepository();
  final AccountSearchRepository _accountSearchRepository = const AccountSearchRepository();

  /// Compteurs réels des 4 cartes "Les Statistiques" du panneau latéral
  /// (`ProfileSidePanel`) — `null` tant que non chargés. "Favoris" n'a pas
  /// de champ dédié : c'est `_savedOfferIds.length`.
  int? _applicationsCount;
  int? _interviewsCount;
  int? _profileViewsCount;

  /// Toutes les offres réellement publiées par les recruteurs
  /// (`job_offers`), tous métiers confondus — un chercheur d'emploi voit
  /// toute offre publiée, peu importe le type d'emploi qu'il recherche.
  List<JobOffer> _offers = [];
  bool _loadingOffers = true;

  /// Ids des offres auxquelles le candidat connecté a déjà postulé
  /// (`job_applications`) — bascule chaque carte sur "Candidature envoyée"
  /// sans re-fetch de toute la liste.
  Set<int> _appliedOfferIds = {};

  /// Ids des offres que le candidat connecté a enregistrées
  /// (`job_offer_saves`) — bascule le libellé du menu "..." de chaque
  /// carte entre "Enregistrer publication" et "Retirer des enregistrements".
  Set<int> _savedOfferIds = {};

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
    final reducedAnimations = _authService.currentUser?.reducedAnimationsEnabled ?? false;
    _animationController = AnimationController(
      duration: reducedAnimations ? Duration.zero : AppDurations.verySlow,
      vsync: this,
    )..forward();
    _profilePanelController = AnimationController(
      duration: reducedAnimations ? Duration.zero : const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadOffers();
    _loadNotificationCount();
    _loadStats();
  }

  /// Charge les compteurs des 4 cartes "Les Statistiques" du panneau
  /// latéral. "Favoris" vient de `_loadOffers` (`_savedOfferIds`).
  Future<void> _loadStats() async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    final results = await Future.wait([
      _jobOfferRepository.countApplicationsForJobSeeker(userId),
      _interviewRepository.countForJobSeeker(userId),
      _accountSearchRepository.countProfileViews(userId),
    ]);
    if (!mounted) return;
    setState(() {
      _applicationsCount = results[0];
      _interviewsCount = results[1];
      _profileViewsCount = results[2];
    });
  }

  /// Id du chercheur d'emploi connecté — `null` si personne n'est
  /// connecté (aucun compte de démo/wizard n'atterrit jamais ici sans
  /// session, mais on reste défensif).
  String? get _jobSeekerUserId => _authService.currentUser?.id;

  Future<void> _loadOffers() async {
    final userId = _jobSeekerUserId;
    final offers = userId != null
        ? await _jobOfferRepository.fetchAllForJobSeeker(userId)
        : await _jobOfferRepository.fetchAll();
    final appliedIds = userId != null
        ? await _jobOfferRepository.fetchAppliedOfferIds(userId)
        : <int>{};
    final savedIds = userId != null
        ? await _jobOfferRepository.fetchSavedOfferIds(userId)
        : <int>{};
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _appliedOfferIds = appliedIds;
      _savedOfferIds = savedIds;
      _loadingOffers = false;
    });
  }

  /// Rafraîchit uniquement l'état des candidatures — utilisé au retour de
  /// `JobOfferDetailScreen` (où le candidat peut avoir postulé) sans
  /// recharger toute la liste d'offres.
  Future<void> _refreshAppliedOfferIds() async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    final appliedIds = await _jobOfferRepository.fetchAppliedOfferIds(userId);
    if (!mounted) return;
    setState(() => _appliedOfferIds = appliedIds);
  }

  /// Enregistre la candidature du candidat connecté pour [offer]
  /// (`JobOfferRepository.apply`) — appelé par le bouton "Postuler" d'une
  /// `JobCard` de la liste "Recommandées pour vous".
  Future<void> _applyToOffer(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null || _appliedOfferIds.contains(offer.id)) return;

    final currentUser = _authService.currentUser;
    final candidateName = currentUser != null
        ? '${currentUser.firstName} ${currentUser.lastName}'.trim()
        : '';

    await _jobOfferRepository.apply(
      jobOfferId: offer.id,
      jobSeekerUserId: userId,
      candidateName: candidateName.isNotEmpty ? candidateName : 'Un candidat',
      candidatePosition: currentUser?.position,
    );
    if (!mounted) return;
    setState(() => _appliedOfferIds = {..._appliedOfferIds, offer.id});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Candidature envoyée pour "${offer.title}" !')),
    );
  }

  /// Annule la candidature du candidat connecté pour [offer]
  /// (`JobOfferRepository.withdrawApplication`) — appelé après confirmation
  /// depuis le bouton "Candidature envoyée" d'une `JobOfferPostCard`, pour
  /// rattraper un "Postuler" envoyé par erreur.
  Future<void> _withdrawApplication(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null || !_appliedOfferIds.contains(offer.id)) return;

    await _jobOfferRepository.withdrawApplication(
      jobOfferId: offer.id,
      jobSeekerUserId: userId,
    );
    if (!mounted) return;
    setState(() => _appliedOfferIds = {..._appliedOfferIds}..remove(offer.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Candidature annulée pour "${offer.title}".')),
    );
  }

  /// Enregistre/retire [offer] des publications enregistrées du candidat
  /// connecté (`JobOfferRepository.saveOffer`/`unsaveOffer`) — appelé par le
  /// menu "..." d'une `JobOfferPostCard`.
  Future<void> _toggleSaveOffer(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;

    final isSaved = _savedOfferIds.contains(offer.id);
    if (isSaved) {
      await _jobOfferRepository.unsaveOffer(offer.id, userId);
    } else {
      await _jobOfferRepository.saveOffer(offer.id, userId);
    }
    if (!mounted) return;
    setState(() {
      _savedOfferIds = isSaved
          ? ({..._savedOfferIds}..remove(offer.id))
          : {..._savedOfferIds, offer.id};
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'Publication retirée des enregistrements.' : 'Publication enregistrée.'),
      ),
    );
  }

  /// Masque [offer] du fil du candidat connecté ("X" sur la carte) —
  /// réutilise le même masquage propre au candidat que "Supprimer" dans
  /// `JobNotificationsScreen` (`job_offer_notification_reads.is_deleted`) :
  /// l'offre reste visible par les autres candidats et dans "Mes offres"
  /// côté recruteur.
  Future<void> _dismissOffer(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;

    await _jobOfferRepository.deleteNotification(offer.id, userId);
    if (!mounted) return;
    setState(() {
      _offers = _offers.where((o) => o.id != offer.id).toList();
    });
    _loadNotificationCount();
  }

  /// Pastille du header et de la nav basse : offres publiées non lues +
  /// entretiens planifiés non lus. Les propositions d'entretien sont
  /// toujours comptées (invitation personnelle) ; seules les notifications
  /// de nouvelles offres sont mises en sourdine si "Recevoir des
  /// notifications de nouvelles offres" est désactivé (`JobSeekerSettingsScreen`)
  /// — dans tous les cas les notifications restent consultables depuis
  /// `JobNotificationsScreen`.
  Future<void> _loadNotificationCount() async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;

    final offersMuted = _authService.currentUser?.notificationsEnabled == false;
    final offerCount = offersMuted
        ? 0
        : await _jobOfferRepository.countUnreadNotificationsForJobSeeker(userId);
    final interviewCount =
        await _interviewRepository.countUnreadNotificationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() {
      _notificationCount = offerCount + interviewCount;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _profilePanelController.dispose();
    super.dispose();
  }

  /// Durée d'ouverture/fermeture du panneau de profil, relue à chaque
  /// interaction pour que "Réduire les animations"
  /// (`JobSeekerSettingsScreen`) s'applique dès le retour sur le dashboard,
  /// sans attendre sa reconstruction.
  Duration get _profilePanelDuration =>
      (_authService.currentUser?.reducedAnimationsEnabled ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 300);

  void _openProfilePanel() {
    _profilePanelController.duration = _profilePanelDuration;
    _profilePanelController.forward();
  }

  void _closeProfilePanel() {
    _profilePanelController.duration = _profilePanelDuration;
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

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: colors.background,
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
                      onNotificationTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JobNotificationsScreen(),
                          ),
                        );
                        _loadNotificationCount();
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

                  // Catégories
                  _buildCategoriesSection(),

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
                  _loadNotificationCount();
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

    String statValue(int? n) => n?.toString() ?? '…';

    return ProfileSidePanel(
      animation: _profilePanelController,
      onClose: _closeProfilePanel,
      onLogoutTap: _logout,
      onSettingsTap: () async {
        _closeProfilePanel();
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JobSeekerSettingsScreen()),
        );
        _loadNotificationCount();
      },
      fullName: fullName ?? 'Marie Martin',
      avatarBytes: user?.photoBytes,
      skills: position ?? "Développeur Flutter . Chercheur d'emploi",
      profileCompletion: user?.profileCompletion ?? 0.0,
      onProfileCompletionTap: () {
        _closeProfilePanel();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JobProfileScreen()),
        );
      },
      stats: [
        {
          'title': 'Candidatures envoyées',
          'value': statValue(_applicationsCount),
          'icon': Icons.send_rounded,
          'iconColor': const Color(0xFF3B82F6),
          'onTap': () { _openStatScreen(const MyApplicationsScreen()); },
        },
        {
          'title': 'Entretiens',
          'value': statValue(_interviewsCount),
          'icon': Icons.calendar_today_rounded,
          'iconColor': const Color(0xFF10B981),
          'onTap': () { _openStatScreen(const MyInterviewsScreen()); },
        },
        {
          'title': 'Favoris',
          'value': _loadingOffers ? '…' : '${_savedOfferIds.length}',
          'icon': Icons.favorite_rounded,
          'iconColor': const Color(0xFFEF4444),
          'onTap': () { _openStatScreen(const MySavedOffersScreen()); },
        },
        {
          'title': 'Vues du profil',
          'value': statValue(_profileViewsCount),
          'icon': Icons.visibility_rounded,
          'iconColor': const Color(0xFFF59E0B),
          'onTap': () { _openStatScreen(const ProfileViewersScreen()); },
        },
      ],
    );
  }

  /// Ouvre l'un des 4 écrans de détail des "Statistiques" du panneau
  /// latéral, puis rafraîchit compteurs et liste d'offres au retour (une
  /// candidature retirée ou un favori enlevé depuis le détail se reflète
  /// immédiatement sur le dashboard).
  Future<void> _openStatScreen(Widget screen) async {
    _closeProfilePanel();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    _loadOffers();
    _loadStats();
  }

  Widget _buildCategoriesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = AppSurfaceColors.of(context);
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
                    style: colors.sectionTitle,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JobCategoriesScreen()),
                      );
                    },
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryOffersScreen(category: category['title'] as String),
                        ),
                      );
                    },
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
    final colors = AppSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.safeAreaHorizontal,
          ),
          child: Text(
            'Recommandées pour vous',
            style: colors.sectionTitle,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!_loadingOffers && _offers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.safeAreaHorizontal,
            ),
            child: Text(
              "Aucune offre publiée pour le moment. Revenez bientôt !",
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: colors.textTertiary,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _offers.length,
            itemBuilder: (context, index) {
              final offer = _offers[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.md,
                  left: AppSpacing.safeAreaHorizontal,
                  right: AppSpacing.safeAreaHorizontal,
                ),
                child: JobOfferPostCard(
                  companyName: offer.companyName,
                  companyLogo: offer.companyLogo,
                  publishedLabel: offer.publishedLabel,
                  jobTitle: offer.title,
                  location: offer.location,
                  salary: offer.salary,
                  contractType: offer.contractType,
                  description: offer.description,
                  posterImage: offer.posterImage,
                  isSaved: _savedOfferIds.contains(offer.id),
                  hasApplied: _appliedOfferIds.contains(offer.id),
                  onToggleSave: () => _toggleSaveOffer(offer),
                  onDismiss: () => _dismissOffer(offer),
                  onApply: () => _applyToOffer(offer),
                  onWithdraw: () => _withdrawApplication(offer),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobOfferDetailScreen(offer: offer),
                      ),
                    );
                    _refreshAppliedOfferIds();
                  },
                ),
              );
            },
          ),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JobCategoriesScreen(),
                ),
              );
            },
            child: Text(
              'Voir plus',
              style: AppTypography.secondaryButton.copyWith(fontSize: 13),
            ),
          ),
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
