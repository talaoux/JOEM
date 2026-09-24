import 'package:flutter/material.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/job_seeker_header.dart';
import 'profile_stats_screens.dart';
import 'job_categories_screen.dart';
import 'job_search_screen.dart';
import 'portfolio_screen.dart';
import 'job_notifications_screen.dart';
import 'job_profile_screen.dart';
import 'job_offer_detail_screen.dart';
import 'job_seeker_settings_screen.dart';
import '../widgets/job_offer_post_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/soft_ui.dart';
import '../widgets/profile_side_panel.dart';
import '../../../../features/login/presentation/login_screen.dart';

class JobSeekerDashboard extends StatefulWidget {
  const JobSeekerDashboard({super.key});

  @override
  State<JobSeekerDashboard> createState() => _JobSeekerDashboardState();
}

class _JobSeekerDashboardState extends State<JobSeekerDashboard>
    with TickerProviderStateMixin, RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  int _currentNavIndex = 0;
  int _notificationCount = 0;

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

  /// Nombre maximum d'offres affichées sur l'accueil. Au-delà, un bouton
  /// "Voir plus d'offres" ouvre `JobCategoriesScreen` pour parcourir le
  /// reste par secteur.
  static const int _maxHomeOffers = 100;

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

    final withdrawn = await _jobOfferRepository.withdrawApplication(
      jobOfferId: offer.id,
      jobSeekerUserId: userId,
    );
    if (!mounted) return;
    if (!withdrawn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cette candidature a déjà été traitée par le recruteur : elle ne peut plus être annulée.")),
      );
      return;
    }
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
    final decisionCount =
        await _jobOfferRepository.countUnreadDecisionNotificationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() {
      _notificationCount = offerCount + interviewCount + decisionCount;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _searchController.dispose();
    _animationController.dispose();
    _profilePanelController.dispose();
    super.dispose();
  }

  /// Redevient visible après la fermeture d'un sous-écran de la nav basse
  /// (Catégorie, Publier, Notifications, Profil) — même quand le retour a
  /// sauté par plusieurs remplacements d'onglets plutôt qu'un simple `pop`
  /// direct (voir `BottomNavigation`/`_onNavTap` des sous-écrans).
  @override
  void didPopNext() {
    _loadOffers();
    _loadNotificationCount();
    _loadStats();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de votre compte ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Se déconnecter',
              style: TextStyle(color: DashboardColors.accent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
          backgroundColor: SoftUi.pageBackground(colors),
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

                  // Offres recommandées : l'accueil ne contient plus que les
                  // offres (hero, catégories et conseil retirés ; le conseil
                  // vit désormais dans le panneau latéral).
                  _buildRecommendedJobsSection(),

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
                        if (index == 2) return const PortfolioScreen();
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
              accentColor: DashboardColors.accent,
              softHomeButton: true,
              thirdItemIcon: Icons.collections_bookmark_rounded,
              thirdItemLabel: 'Portfolio',
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
      advice: _careerAdvice(),
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
          'iconColor': const Color(0xFF0F8A6E),
          'onTap': () { _openStatScreen(const MyApplicationsScreen()); },
        },
        {
          'title': 'Entretiens',
          'value': statValue(_interviewsCount),
          'icon': Icons.calendar_today_rounded,
          'iconColor': const Color(0xFFC2780E),
          'onTap': () { _openStatScreen(const MyInterviewsScreen()); },
        },
        {
          'title': 'Favoris',
          'value': _loadingOffers ? '…' : '${_savedOfferIds.length}',
          'icon': Icons.favorite_rounded,
          'iconColor': const Color(0xFFD1366E),
          'onTap': () { _openStatScreen(const MySavedOffersScreen()); },
        },
        {
          'title': 'Vues du profil',
          'value': statValue(_profileViewsCount),
          'icon': Icons.visibility_rounded,
          'iconColor': DashboardColors.accentStrong,
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

  Widget _buildRecommendedJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.safeAreaHorizontal,
          ),
          child: const SerifSectionTitle('Recommandées pour vous'),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loadingOffers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
            child: SkeletonCardList(
              count: 2,
              cardBuilder: (context, index) => const JobOfferCardSkeleton(),
            ),
          )
        else if (_offers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.safeAreaHorizontal,
            ),
            child: const SoftEmptyState(
              icon: Icons.work_outline_rounded,
              text: 'Aucune offre publiée pour le moment. Revenez bientôt !',
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _offers.length.clamp(0, _maxHomeOffers),
            itemBuilder: (context, index) {
              final offer = _offers[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.md,
                  left: AppSpacing.safeAreaHorizontal,
                  right: AppSpacing.safeAreaHorizontal,
                ),
                child: FadeSlideIn(
                  key: ValueKey(offer.id),
                  delay: staggerDelayFor(index),
                  child: JobOfferPostCard(
                    companyName: offer.companyName,
                    companyLogo: offer.companyLogo,
                    publishedLabel: offer.publishedLabel,
                    jobTitle: offer.title,
                    location: offer.location,
                    salary: offer.salary,
                    contractType: offer.contractType,
                    otherSector: offer.otherSector,
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
                ),
              );
            },
          ),
        if (_offers.length > _maxHomeOffers) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: SoftPillButton(
              label: "Voir plus d'offres",
              icon: Icons.arrow_forward_rounded,
              compact: true,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JobCategoriesScreen()),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Conseil "réel" : dérivé de l'état effectif du profil et de l'activité
  /// du candidat (complétude du profil, candidatures envoyées, favoris,
  /// entretiens obtenus) plutôt qu'un texte fixe — le plus actionnable en
  /// premier. Une fois tout à jour, une petite rotation de conseils
  /// génériques change selon le jour, pour ne pas figer sur un seul texte.
  ({String title, String text}) _careerAdvice() {
    final user = _authService.currentUser;
    final missing = user?.missingJobSeekerFieldLabels ?? const [];

    if (missing.isNotEmpty) {
      final extra = missing.length - 1;
      return (
        title: 'Complétez votre profil',
        text: extra > 0
            ? '${missing.first} — et $extra autre${extra > 1 ? 's' : ''} élément${extra > 1 ? 's' : ''} à renseigner pour être mieux repéré par les recruteurs.'
            : '${missing.first} pour être mieux repéré par les recruteurs.',
      );
    }

    final applicationsCount = _applicationsCount ?? 0;
    if (applicationsCount == 0) {
      return (
        title: "Passez à l'action",
        text: _offers.isNotEmpty
            ? 'Votre profil est complet : postulez à "${_offers.first.title}" ou une autre offre recommandée pour décrocher votre premier entretien.'
            : 'Votre profil est complet : les recruteurs peuvent désormais vous trouver plus facilement.',
      );
    }

    if (_savedOfferIds.isEmpty && _offers.isNotEmpty) {
      return (
        title: 'Gardez une trace des offres qui vous intéressent',
        text: "Appuyez sur le cœur d'une offre pour l'enregistrer et la retrouver facilement dans vos favoris.",
      );
    }

    if ((_interviewsCount ?? 0) == 0) {
      return (
        title: 'Restez actif',
        text:
            'Vous avez $applicationsCount candidature${applicationsCount > 1 ? 's' : ''} envoyée${applicationsCount > 1 ? 's' : ''} : continuez à postuler pour multiplier vos chances d\'entretien.',
      );
    }

    const tips = [
      (
        title: 'Conseil carrière',
        text: 'Mettez à jour votre CV régulièrement et personnalisez votre lettre de motivation pour chaque candidature.',
      ),
      (
        title: 'Préparez vos entretiens',
        text: "Relisez l'offre et renseignez-vous sur l'entreprise avant chaque entretien planifié.",
      ),
      (
        title: 'Soignez votre profil',
        text: 'Une présentation claire et des compétences à jour augmentent vos chances d\'être contacté directement.',
      ),
    ];
    return tips[DateTime.now().day % tips.length];
  }
}
