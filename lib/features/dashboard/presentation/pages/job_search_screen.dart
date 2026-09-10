import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_search_repository.dart';
import '../widgets/search_bar_widget.dart';
import 'company_profile_view_screen.dart';

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
      backgroundColor: colors.background,
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
      return const Center(child: CircularProgressIndicator());
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
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _CompanyResultCard(
        company: _results[index],
        onTap: () => _openCompanyDetail(_results[index]),
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
              Text(
                'Historiques',
                style: TextStyle(
                  color: colors.textPrimary,
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
                  colors,
                  icon: Icons.history_rounded,
                  title: 'Aucun historique',
                  message: 'Vos recherches récentes apparaîtront ici.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeAreaHorizontal,
                  ),
                  itemCount: _history.length,
                  itemBuilder: (context, index) => _buildHistoryItem(colors, index),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(AppSurfaceColors colors, int index) {
    final query = _history[index];
    return InkWell(
      onTap: () => _onHistoryTap(query),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 20,
              color: colors.textTertiary,
            ),
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
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: colors.textTertiary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AppSurfaceColors colors, {
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
            Icon(icon, size: 48, color: colors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: colors.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final location = company.localisation?.trim() ?? '';
    final contact = company.contactName?.trim() ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Logo(logo: company.logo),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.companyName.isEmpty ? 'Entreprise' : company.companyName,
                    style: colors.jobTitle,
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
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.logo});

  final Uint8List? logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        image: logo != null ? DecorationImage(image: MemoryImage(logo!), fit: BoxFit.cover) : null,
      ),
      child: logo == null ? Icon(Icons.business_rounded, color: OnboardingColors.violet, size: 24) : null,
    );
  }
}

