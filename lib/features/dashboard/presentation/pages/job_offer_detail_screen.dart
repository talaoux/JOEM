import 'package:flutter/material.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

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

  /// Décision du recruteur sur la candidature du candidat connecté : le
  /// bouton devient "Candidature acceptée"/"Candidature non retenue"
  /// (désactivé : ni retrait ni nouvelle candidature possible) et un encadré
  /// affiche [_decisionMessage].
  bool _isRejected = false;
  bool _isAccepted = false;
  String? _decisionMessage;

  /// Catégories choisies par le recruteur à la publication
  /// (`job_offer_categories`) — vide pour une offre plus ancienne.
  List<String> _categories = const [];

  JobOffer get offer => widget.offer;

  String? get _jobSeekerUserId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadApplicationStatus();
    _recordView();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _repository.fetchCategoriesForOffer(offer.id);
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  /// Enregistre une vue de cette offre (au plus une par candidat, voir
  /// `JobOfferRepository.recordOfferView`) — alimente la carte "Vues
  /// totales" du `EmployerDashboard`. Seuls les chercheurs d'emploi
  /// comptent : le recruteur qui consulte sa propre offre ne se compte pas.
  Future<void> _recordView() async {
    final user = _authService.currentUser;
    if (user == null || user.role != 'job_seeker') return;
    await _repository.recordOfferView(offer.id, user.id);
  }

  Future<void> _loadApplicationStatus() async {
    final userId = _jobSeekerUserId;
    if (userId == null) {
      setState(() => _checkingStatus = false);
      return;
    }
    final status = await _repository.fetchApplicationStatus(offer.id, userId);
    if (!mounted) return;
    setState(() {
      _hasApplied = status != null;
      _isRejected = status?.status == ApplicationStatus.rejected;
      _isAccepted = status?.status == ApplicationStatus.accepted;
      _decisionMessage = status?.decisionMessage;
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
    final withdrawn =
        await _repository.withdrawApplication(jobOfferId: offer.id, jobSeekerUserId: userId);
    if (!mounted) return;
    if (!withdrawn) {
      // Rejetée entre-temps par le recruteur : on recharge le statut.
      setState(() => _applying = false);
      _loadApplicationStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette candidature a déjà été traitée par le recruteur.')),
      );
      return;
    }
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
                  const Expanded(child: SerifSectionTitle("Détail de l'offre")),
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
                  children: staggered([
                    SoftCard(
                      radius: 28,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompanyHeader(colors),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _buildInfoChip(colors, Icons.location_on_outlined, offer.location),
                              _buildInfoChip(colors, Icons.attach_money_rounded, offer.salary),
                              _buildInfoChip(colors, Icons.work_outline_rounded, offer.contractType),
                              for (final category in _categories)
                                _buildInfoChip(
                                  colors,
                                  Icons.category_outlined,
                                  offerCategoryLabel(category, offer.otherSector),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SoftSection(
                        title: 'Description du poste',
                        child: Text(
                          offer.description.isNotEmpty
                              ? offer.description
                              : 'Aucune description fournie pour cette offre.',
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 14,
                            height: 1.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    // Toujours présent (même vide) : la liste animée garde sa
                    // longueur quand le statut arrive après chargement.
                    SmoothSwitcher(
                      child: (_isRejected || _isAccepted)
                          ? Padding(
                              key: ValueKey(_isAccepted),
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: _buildDecisionNotice(colors),
                            )
                          : null,
                    ),
                    if (offer.posterImage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.memory(
                          offer.posterImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ]),
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
              // "Postuler" en pilule pâle violette ; une fois postulé, pilule
              // verte "Candidature envoyée" (tap = annuler la candidature).
              child: SmoothSwitcher(
                alignment: Alignment.bottomCenter,
                child: KeyedSubtree(
                  key: ValueKey('$_isAccepted-$_isRejected-$_hasApplied'),
                  child: _isAccepted
                  ? const SoftPrimaryButton(
                      label: 'Candidature acceptée',
                      icon: Icons.verified_rounded,
                      color: _acceptedColor,
                      onPressed: null,
                    )
                  : _isRejected
                  ? const SoftPrimaryButton(
                      label: 'Candidature non retenue',
                      icon: Icons.do_not_disturb_on_outlined,
                      color: _rejectedColor,
                      onPressed: null,
                    )
                  : _hasApplied
                  ? SoftPrimaryButton(
                      label: 'Candidature envoyée',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF0F8A6E),
                      loading: _applying || _checkingStatus,
                      onPressed: _confirmWithdraw,
                    )
                  : SoftPrimaryButton(
                      label: 'Postuler',
                      icon: Icons.send_rounded,
                      loading: _applying || _checkingStatus,
                      onPressed: _handleApply,
                    ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _rejectedColor = Color(0xFF64748B);
  static const Color _acceptedColor = Color(0xFF0F8A6E);

  /// Encadré "Candidature acceptée" / "Candidature non retenue", avec le
  /// mot du recruteur s'il en a laissé un.
  Widget _buildDecisionNotice(AppSurfaceColors colors) {
    final message = _decisionMessage?.trim() ?? '';
    final String fallback = _isAccepted
        ? "L'entreprise a accepté votre candidature et vous propose un entretien : "
            "retrouvez-le dans vos notifications et dans « Mes entretiens »."
        : "L'entreprise n'a pas retenu votre candidature pour ce poste. "
            "Ne vous découragez pas, d'autres offres vous attendent !";
    return SizedBox(
      width: double.infinity,
      child: SoftSection(
        title: _isAccepted ? 'Candidature acceptée' : 'Candidature non retenue',
        child: Text(
          message.isNotEmpty ? "Message de l'entreprise : « $message »" : fallback,
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(AppSurfaceColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftAvatar(
          name: offer.companyName,
          size: 56,
          icon: Icons.business_rounded,
          photo: offer.companyLogo != null ? MemoryImage(offer.companyLogo!) : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: AppTypography.frauncesBold.copyWith(
                  fontSize: 21,
                  color: colors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(offer.companyName, style: colors.companyName),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    offer.publishedLabel,
                    style: colors.jobInfo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(AppSurfaceColors colors, IconData icon, String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: SoftUi.tint(colors, DashboardColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: SoftUi.brandInk(colors)),
          const SizedBox(width: 6),
          Text(
            label,
            style: colors.jobInfo.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}