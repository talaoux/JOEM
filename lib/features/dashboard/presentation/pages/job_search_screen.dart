import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/account_search_repository.dart';
import '../widgets/search_bar_widget.dart';
import 'company_profile_view_screen.dart';
import '../widgets/soft_ui.dart';

/// Recherche d'entreprises — équivalent candidat de `CandidateSearchScreen`.
/// Recherche réelle parmi les comptes recruteur inscrits
/// (`AccountSearchRepository.searchEmployers`) : aucun résultat mocké,
/// "Aucun résultat" si aucune entreprise ne correspond. L'historique est
/// également réel (`search_history`), propre au candidat connecté.
class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AccountSearchRepository _repository = const AccountSearchRepository();

  String get _userId => AuthService().currentUser?.id ?? '';

  List<String> _history = [];
  List<CompanySearchResult> _results = [];
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
      searchType: SearchAccountType.company,
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
    final results = await _repository.searchEmployers(term);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });

    if (saveHistory) {
      await _repository.recordSearch(
        userId: _userId,
        searchType: SearchAccountType.company,
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
      searchType: SearchAccountType.company,
      query: query,
    );
  }

  /// Ouvrir un profil vaut validation de la recherche : sans ça, une
  /// entreprise cherchée puis ouverte directement (sans appuyer sur
  /// "Rechercher" au clavier) ne laissait jamais de trace dans
  /// l'historique.
  Future<void> _openCompanyDetail(CompanySearchResult company) async {
    final term = _searchController.text.trim();
    if (term.isNotEmpty) {
      await _repository.recordSearch(
        userId: _userId,
        searchType: SearchAccountType.company,
        query: term,
      );
      await _loadHistory();
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompanyProfileViewScreen(company: company)),
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
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
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
                      color: colors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchController,
                      showFilterButton: false,
                      autofocus: true,
                      hintText: 'Rechercher une entreprise...',
                      onChanged: _onQueryChanged,
                      onSubmitted: _onSubmitted,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _hasQuery ? _buildResults(colors) : _buildHistory(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AppSurfaceColors colors) {
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
        colors,
        icon: Icons.business_outlined,
        title: 'Aucun résultat',
        message: 'Aucune entreprise inscrite ne correspond à cette recherche.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeAreaHorizontal,
        vertical: AppSpacing.sm,
      ),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => FadeSlideIn(
        key: ValueKey(_results[index].userId),
        delay: staggerDelayFor(index),
        child: _CompanyResultCard(
          company: _results[index],
          onTap: () => _openCompanyDetail(_results[index]),
        ),
      ),
    );
  }

  Widget _buildHistory(AppSurfaceColors colors) {
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
                  colors,
                  icon: Icons.history_rounded,
                  title: 'Aucun historique',
                  message: 'Vos recherches récentes apparaîtront ici.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeAreaHorizontal,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: _history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _buildHistoryItem(colors, index),
                ),
        ),
      ],
    );
  }

  /// Recherche récente : pilule blanche à fine bordure.
  Widget _buildHistoryItem(AppSurfaceColors colors, int index) {
    final query = _history[index];
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      onTap: () => _onHistoryTap(query),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: colors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              query,
              style: AppTypography.interRegular.copyWith(
                fontSize: 14,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _removeHistoryItem(index),
            icon: Icon(Icons.close_rounded, size: 18, color: colors.textTertiary),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    AppSurfaceColors colors, {
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

class _CompanyResultCard extends StatelessWidget {
  const _CompanyResultCard({required this.company, required this.onTap});

  final CompanySearchResult company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final name = company.companyName.isEmpty ? 'Entreprise' : company.companyName;
    final location = company.localisation?.trim() ?? '';
    final contact = company.contactName?.trim() ?? '';

    return SoftCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftAvatar(
            name: name,
            size: 48,
            icon: Icons.business_rounded,
            photo: company.logo != null ? MemoryImage(company.logo!) : null,
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
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(contact, style: colors.companyName),
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
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
        ],
      ),
    );
  }
}
