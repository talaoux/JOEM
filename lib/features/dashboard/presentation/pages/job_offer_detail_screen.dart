import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/job_offer_repository.dart';

/// Détail complet d'une offre publiée par un recruteur (`job_offers`) —
/// accessible depuis la liste "Recommandées pour vous" du dashboard
/// candidat et depuis les notifications, en tapant sur une offre.
class JobOfferDetailScreen extends StatefulWidget {
  const JobOfferDetailScreen({super.key, required this.offer});

  final JobOffer offer;

  @override
  State<JobOfferDetailScreen> createState() => _JobOfferDetailScreenState();
}

class _JobOfferDetailScreenState extends State<JobOfferDetailScreen> {
  final JobOfferRepository _repository = const JobOfferRepository();
  final AuthService _authService = AuthService();

  bool _hasApplied = false;
  bool _applying = false;
  bool _checkingStatus = true;

  JobOffer get offer => widget.offer;

  String? get _jobSeekerUserId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadApplicationStatus();
  }

  Future<void> _loadApplicationStatus() async {
    final userId = _jobSeekerUserId;
    if (userId == null) {
      setState(() => _checkingStatus = false);
      return;
    }
    final applied = await _repository.hasApplied(offer.id, userId);
    if (!mounted) return;
    setState(() {
      _hasApplied = applied;
      _checkingStatus = false;
    });
  }

  /// Enregistre la candidature en base (`job_applications`), puis met à
  /// jour ce bouton et informe le dashboard candidat (qui rafraîchit ses
  /// propres cartes "Postuler" -> "Candidature envoyée" au retour sur
  /// cet écran, voir `JobSeekerDashboard._buildRecommendedJobsSection`).
  Future<void> _handleApply() async {
    final userId = _jobSeekerUserId;
    if (userId == null || _hasApplied || _applying) return;

    final currentUser = _authService.currentUser;
    final candidateName = currentUser != null
        ? '${currentUser.firstName} ${currentUser.lastName}'.trim()
        : '';

    setState(() => _applying = true);
    await _repository.apply(
      jobOfferId: offer.id,
      jobSeekerUserId: userId,
      candidateName: candidateName.isNotEmpty ? candidateName : 'Un candidat',
      candidatePosition: currentUser?.position,
    );
    if (!mounted) return;
    setState(() {
      _hasApplied = true;
      _applying = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Candidature envoyée pour "${offer.title}" !')),
    );
  }

  /// Annule la candidature envoyée par erreur — même logique que
  /// `JobOfferPostCard._confirmWithdraw`, dupliquée ici car cet écran
  /// gère son propre état `_hasApplied` indépendamment du dashboard.
  Future<void> _confirmWithdraw() async {
    final userId = _jobSeekerUserId;
    if (userId == null || !_hasApplied || _applying) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler la candidature ?'),
        content: Text(
          'Votre candidature pour "${offer.title}" sera retirée. '
          'Vous pourrez postuler à nouveau plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Annuler la candidature',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _applying = true);
    await _repository.withdrawApplication(jobOfferId: offer.id, jobSeekerUserId: userId);
    if (!mounted) return;
    setState(() {
      _hasApplied = false;
      _applying = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Candidature annulée pour "${offer.title}".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Détail de l'offre",
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompanyHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildInfoChip(Icons.location_on_outlined, offer.location),
                        _buildInfoChip(Icons.attach_money_rounded, offer.salary),
                        _buildInfoChip(Icons.work_outline_rounded, offer.contractType),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Description du poste', style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      offer.description.isNotEmpty
                          ? offer.description
                          : 'Aucune description fournie pour cette offre.',
                      style: AppTypography.cardDescription,
                    ),
                    if (offer.posterImage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          offer.posterImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.safeAreaHorizontal,
                AppSpacing.md,
                AppSpacing.safeAreaHorizontal,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_applying || _checkingStatus)
                      ? null
                      : (_hasApplied ? _confirmWithdraw : _handleApply),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasApplied
                        ? const Color(0xFFE5E7EB)
                        : OnboardingColors.violet,
                    foregroundColor:
                        _hasApplied ? const Color(0xFF6B7280) : Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _applying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_hasApplied) ...[
                              const Icon(Icons.check_circle_rounded, size: 18),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Text(
                              _hasApplied ? 'Candidature envoyée' : 'Postuler',
                              style: AppTypography.primaryButton.copyWith(
                                color: _hasApplied
                                    ? const Color(0xFF6B7280)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: OnboardingColors.violet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            image: offer.companyLogo != null
                ? DecorationImage(
                    image: MemoryImage(offer.companyLogo!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: offer.companyLogo == null
              ? const Icon(
                  Icons.business_rounded,
                  color: OnboardingColors.violet,
                  size: 28,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer.title, style: AppTypography.dashboardSubtitle),
              const SizedBox(height: 2),
              Text(offer.companyName, style: AppTypography.companyName),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    offer.publishedLabel,
                    style: AppTypography.jobInfo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: OnboardingColors.violet),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.jobInfo.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}