import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/account_search_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/soft_ui.dart';
import 'candidate_profile_view_screen.dart';
import 'employer_notifications_screen.dart';
import 'employer_profile_screen.dart';
import 'job_offer_publish_screen.dart';

/// Recherche de candidats — équivalent recruteur de `JobSearchScreen`.
/// Recherche réelle parmi les comptes chercheur d'emploi inscrits
/// (`AccountSearchRepository.searchJobSeekers`) : aucun résultat mocké,
/// "Aucun résultat" si aucun compte ne correspond. L'historique est
/// également réel (`search_history`), propre au recruteur connecté.
class CandidateSearchScreen extends StatefulWidget {
  const CandidateSearchScreen({super.key});

  @override
  State<CandidateSearchScreen> createState() => _CandidateSearchScreenState();
}

class _CandidateSearchScreenState extends State<CandidateSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AccountSearchRepository _repository = const AccountSearchRepository();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  final AuthService _authService = AuthService();

  String get _userId => _authService.currentUser?.id ?? '';
  int? get _employerUserId => int.tryParse(_userId);

  AppSurfaceColors get _colors => AppSurfaceColors.of(context);

  List<String> _history = [];
  List<CandidateSearchResult> _results = [];
  bool _isSearching = false;
  bool _hasQuery = false;
  Timer? _debounce;

  /// Pastille de la nav basse — même calcul que sur le dashboard.
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
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

  /// Navigation de la barre basse : remplace l'écran courant par l'écran
  /// cible (comportement d'onglets, pas d'empilement) ou revient au
  /// dashboard ("Accueil", toujours la racine de la pile de navigation
  /// après connexion).
  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    late final Widget screen;
    switch (index) {
      case 2:
        screen = const JobOfferPublishScreen();
        break;
      case 3:
        screen = const EmployerNotificationsScreen();
        break;
      default:
        screen = const EmployerProfileScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _loadHistory() async {
    final history = await _repository.fetchHistory(
      userId: _userId,
      searchType: SearchAccountType.candidate,
    );
    if (!mounted) return;
    setState(() => _history = history);
  }

  void _onQueryChanged(String value) {
    setState(() => _hasQuery = value.trim().isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(value));
  }

  Future<void> _runSearch(String value, {bool saveHistory = false}) async {
    final term = value.trim();
    if (term.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await _repository.searchJobSeekers(term);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });

    if (saveHistory) {
      await _repository.recordSearch(
        userId: _userId,
        searchType: SearchAccountType.candidate,
        query: term,
      );
      await _loadHistory();
    }
  }

  Future<void> _onSubmitted(String value) async {
    _debounce?.cancel();
    await _runSearch(value, saveHistory: true);
  }

  Future<void> _onHistoryTap(String query) async {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    setState(() => _hasQuery = query.trim().isNotEmpty);
    await _onSubmitted(query);
  }

  Future<void> _removeHistoryItem(int index) async {
    final query = _history[index];
    setState(() => _history.removeAt(index));
    await _repository.removeHistoryEntry(
      userId: _userId,
      searchType: SearchAccountType.candidate,
      query: query,
    );
  }

  /// Ouvrir un profil vaut validation de la recherche : sans ça, un
  /// candidat cherché puis ouvert directement (sans appuyer sur
  /// "Rechercher" au clavier) ne laissait jamais de trace dans
  /// l'historique.
  Future<void> _openCandidateDetail(CandidateSearchResult candidate) async {
    final term = _searchController.text.trim();
    if (term.isNotEmpty) {
      await _repository.recordSearch(
        userId: _userId,
        searchType: SearchAccountType.candidate,
        query: term,
      );
      await _loadHistory();
    }
    if (_userId.isNotEmpty) {
      await _repository.recordProfileView(
        profileUserId: candidate.userId,
        viewerUserId: _userId,
      );
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CandidateProfileViewScreen(candidate: candidate)),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(_colors),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche + retour
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
                vertical: AppSpacing.headerPadding,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _colors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchController,
                      showFilterButton: false,
                      autofocus: true,
                      hintText: 'Rechercher un candidat...',
                      onChanged: _onQueryChanged,
                      onSubmitted: _onSubmitted,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _hasQuery ? _buildResults() : _buildHistory(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        onTap: _onNavTap,
        secondItemIcon: Icons.search_rounded,
        secondItemLabel: 'Recherche',
        notificationCount: _notificationCount,
        accentColor: DashboardColors.accent,
        softHomeButton: true,
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.safeAreaHorizontal,
          vertical: AppSpacing.sm,
        ),
        child: SkeletonCardList(
          count: 4,
          cardBuilder: (context, index) => const ListRowSkeleton(),
        ),
      );
    }
    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search_rounded,
        title: 'Aucun résultat',
        message: 'Aucun candidat inscrit ne correspond à cette recherche.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeAreaHorizontal,
        vertical: AppSpacing.sm,
      ),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => FadeSlideIn(
        key: ValueKey(_results[index].userId),
        delay: staggerDelayFor(index),
        child: _CandidateResultCard(
          candidate: _results[index],
          onTap: () => _openCandidateDetail(_results[index]),
        ),
      ),
    );
  }

  Widget _buildHistory() {
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
              const SerifSectionTitle('Recherches récentes', fontSize: 19),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _history.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history_rounded,
                  title: 'Aucun historique',
                  message: 'Vos recherches de candidats récentes apparaîtront ici.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeAreaHorizontal,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: _history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _buildHistoryItem(index),
                ),
        ),
      ],
    );
  }

  /// Recherche récente : pilule blanche à fine bordure, comme les champs
  /// de la maquette.
  Widget _buildHistoryItem(int index) {
    final query = _history[index];
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      onTap: () => _onHistoryTap(query),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: _colors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              query,
              style: AppTypography.interRegular.copyWith(
                fontSize: 14,
                color: _colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _removeHistoryItem(index),
            icon: Icon(Icons.close_rounded, size: 18, color: _colors.textTertiary),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeAreaHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: SoftEmptyState(icon: icon, text: '$title — $message'),
      ),
    );
  }
}

class _CandidateResultCard extends StatelessWidget {
  const _CandidateResultCard({required this.candidate, required this.onTap});

  final CandidateSearchResult candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final name = candidate.fullName.isEmpty ? 'Candidat' : candidate.fullName;
    final position = candidate.position?.trim() ?? '';
    final location = candidate.localisation?.trim() ?? '';
    final skills = candidate.skills.take(3).toList();

    return SoftCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftAvatar(
            name: name,
            size: 48,
            photo: candidate.photo != null ? MemoryImage(candidate.photo!) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.interSemiBold.copyWith(fontSize: 15, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (position.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(position, style: colors.companyName),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: colors.jobInfo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skills
                        .map((s) => SoftDotBadge(label: s, color: DashboardColors.accent))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
        ],
      ),
    );
  }
}
