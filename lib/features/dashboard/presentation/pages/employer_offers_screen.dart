import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/employer_offer_card.dart';
import 'offer_applicants_screen.dart';

/// Liste complète des offres publiées par le recruteur connecté — ouverte
/// via "Voir tout" de la section "Mes offres d'emploi" du `EmployerDashboard`.
/// Chaque carte ouvre `OfferApplicantsScreen` ; le menu "..." supprime
/// l'offre (`JobOfferRepository.deleteOffer`, cascade sur candidatures/
/// enregistrements/vues).
class EmployerOffersScreen extends StatefulWidget {
  const EmployerOffersScreen({super.key});

  @override
  State<EmployerOffersScreen> createState() => _EmployerOffersScreenState();
}

class _EmployerOffersScreenState extends State<EmployerOffersScreen> {
  final JobOfferRepository _repository = const JobOfferRepository();
  final AuthService _authService = AuthService();

  List<JobOffer> _offers = [];
  Map<int, int> _applicantCounts = {};
  bool _loading = true;

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) {
      setState(() => _loading = false);
      return;
    }
    final offers = await _repository.fetchByEmployer(employerUserId);
    final counts = await _repository.fetchApplicantCountsByOffer(employerUserId);
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _applicantCounts = counts;
      _loading = false;
    });
  }

  Future<void> _openApplicants(JobOffer offer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OfferApplicantsScreen(offer: offer)),
    );
    _load();
  }

  Future<void> _confirmDelete(JobOffer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette offre ?'),
        content: Text(
          '"${offer.title}" et toutes les candidatures reçues sur cette offre '
          'seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repository.deleteOffer(offer.id);
    if (!mounted) return;
    setState(() => _offers = _offers.where((o) => o.id != offer.id).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Offre "${offer.title}" supprimée.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Mes offres d\'emploi', style: AppTypography.sectionTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _offers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                      child: Text(
                        "Vous n'avez publié aucune offre pour le moment.",
                        textAlign: TextAlign.center,
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
                    itemCount: _offers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      return EmployerOfferCard(
                        offer: offer,
                        applicantCount: _applicantCounts[offer.id] ?? 0,
                        onTap: () => _openApplicants(offer),
                        onDelete: () => _confirmDelete(offer),
                      );
                    },
                  ),
      ),
    );
  }
}
