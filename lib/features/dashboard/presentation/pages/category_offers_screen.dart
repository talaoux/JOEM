import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/job_offer_post_card.dart';
import 'job_offer_detail_screen.dart';
import '../widgets/soft_ui.dart';

/// Offres réellement publiées rangées dans [category] — catégories choisies
/// par le recruteur à la publication (une offre peut en avoir plusieurs),
/// ou catégorie de l'entreprise pour les offres plus anciennes (voir
/// `JobOfferRepository.fetchByCategory`). Ouvert en tapant une catégorie
/// dans `JobCategoriesScreen` ou la grille "Catégories populaires" du
/// dashboard candidat. "Aucune offre" si rien n'a encore été publié ici.
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

    final withdrawn = await _repository.withdrawApplication(jobOfferId: offer.id, jobSeekerUserId: userId);
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
      backgroundColor: SoftUi.pageBackground(colors),
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
                  Expanded(child: SerifSectionTitle(widget.category)),
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
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
        child: SkeletonCardList(
          count: 3,
          cardBuilder: (context, index) => const JobOfferCardSkeleton(),
        ),
      );
    }
    if (_offers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.safeAreaHorizontal,
          vertical: AppSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SoftEmptyState(
            icon: Icons.work_off_outlined,
            text: "Aucune offre — aucune offre n'a encore été publiée dans la catégorie \"${widget.category}\".",
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
                  MaterialPageRoute(builder: (_) => JobOfferDetailScreen(offer: offer)),
                );
                _refreshAppliedOfferIds();
              },
            ),
          ),
        );
      },
    );
  }
}