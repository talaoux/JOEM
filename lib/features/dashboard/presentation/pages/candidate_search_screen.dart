import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_search_repository.dart';
import '../widgets/search_bar_widget.dart';
import 'candidate_profile_view_screen.dart';

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

  String get _userId => AuthService().currentUser?.id ?? '';

  List<String> _history = [];
  List<CandidateSearchResult> _results = [];
  bool _isSearching = false;
  bool _hasQuery = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
      backgroundColor: AppColors.background,
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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
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
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
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
      itemBuilder: (context, index) => _CandidateResultCard(
        candidate: _results[index],
        onTap: () => _openCandidateDetail(_results[index]),
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
              const Text(
                'Historiques',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeAreaHorizontal,
                  ),
                  itemCount: _history.length,
                  itemBuilder: (context, index) => _buildHistoryItem(index),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(int index) {
    final query = _history[index];
    return InkWell(
      onTap: () => _onHistoryTap(query),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                query,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => _removeHistoryItem(index),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final position = candidate.position?.trim() ?? '';
    final location = candidate.localisation?.trim() ?? '';
    final skills = candidate.skills.take(3).toList();

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(photo: candidate.photo, icon: Icons.person_rounded),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.fullName.isEmpty ? 'Candidat' : candidate.fullName,
                    style: AppTypography.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (position.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(position, style: AppTypography.companyName),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTypography.jobInfo,
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
                      children: skills.map((s) => _SkillChip(label: s)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photo, required this.icon});

  final Uint8List? photo;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withOpacity(0.1),
        shape: BoxShape.circle,
        image: photo != null ? DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover) : null,
      ),
      child: photo == null ? Icon(icon, color: OnboardingColors.violet, size: 24) : null,
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.jobInfo.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

