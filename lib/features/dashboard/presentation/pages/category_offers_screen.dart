import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/job_offer_post_card.dart';
import 'job_offer_detail_screen.dart';

/// Offres réellement publiées dont l'entreprise appartient à [category]
/// (`employer_profiles.categorie`, choisie à l'inscription recruteur) —
/// ouvert en tapant une catégorie dans `JobCategoriesScreen` ou la grille
/// "Catégories populaires" du dashboard candidat. Aucune donnée mockée :
/// "Aucune offre" si aucun recruteur de ce secteur n'a encore publié.
class CategoryOffersScreen extends StatefulWidget {
  const CategoryOffersScreen({super.key, required this.category});

  final String category;

  @override
  State<CategoryOffersScreen> createState() => _CategoryOffersScreenState();
}

class _CategoryOffersScreenState extends State<CategoryOffersScreen> {
  final JobOfferRepository _repository = const JobOfferRepository();
  final AuthService _authService = AuthService();

  List<JobOffer> _offers = [];
  Set<int> _appliedOfferIds = {};
  Set<int> _savedOfferIds = {};
  bool _loading = true;

  String? get _jobSeekerUserId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final userId = _jobSeekerUserId;
    final offers = userId != null
        ? await _repository.fetchByCategoryForJobSeeker(widget.category, userId)
        : await _repository.fetchByCategory(widget.category);
    final appliedIds =
        userId != null ? await _repository.fetchAppliedOfferIds(userId) : <int>{};
    final savedIds = userId != null ? await _repository.fetchSavedOfferIds(userId) : <int>{};
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _appliedOfferIds = appliedIds;
      _savedOfferIds = savedIds;
      _loading = false;
    });
  }

  Future<void> _refreshAppliedOfferIds() async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    final appliedIds = await _repository.fetchAppliedOfferIds(userId);
    if (!mounted) return;
    setState(() => _appliedOfferIds = appliedIds);
  }

  Future<void> _applyToOffer(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null || _appliedOfferIds.contains(offer.id)) return;

    final currentUser = _authService.currentUser;
    final candidateName = currentUser != null
        ? '${currentUser.firstName} ${currentUser.lastName}'.trim()
        : '';

    await _repository.apply(
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

  Future<void> _withdrawApplication(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null || !_appliedOfferIds.contains(offer.id)) return;

    await _repository.withdrawApplication(jobOfferId: offer.id, jobSeekerUserId: userId);
    if (!mounted) return;
    setState(() => _appliedOfferIds = {..._appliedOfferIds}..remove(offer.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Candidature annulée pour "${offer.title}".')),
    );
  }

  Future<void> _toggleSaveOffer(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;

    final isSaved = _savedOfferIds.contains(offer.id);
    if (isSaved) {
      await _repository.unsaveOffer(offer.id, userId);
    } else {
      await _repository.saveOffer(offer.id, userId);
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

  Future<void> _dismissOffer(JobOffer offer) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;

    await _repository.deleteNotification(offer.id, userId);
    if (!mounted) return;
    setState(() {
      _offers = _offers.where((o) => o.id != offer.id).toList();
    });
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
                    child: Text(
                      widget.category,
                      style: colors.sectionTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppSurfaceColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_off_outlined, size: 48, color: colors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text('Aucune offre', style: colors.sectionTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Aucun recruteur de la catégorie \"${widget.category}\" n'a encore publié d'offre.",
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                MaterialPageRoute(builder: (_) => JobOfferDetailScreen(offer: offer)),
              );
              _refreshAppliedOfferIds();
            },
          ),
        );
      },
    );
  }
}