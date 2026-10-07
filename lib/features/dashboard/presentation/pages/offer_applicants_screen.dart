import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_search_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/soft_ui.dart';
import 'candidate_application_detail_screen.dart';
import 'candidate_profile_view_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';
import 'package:joem/core/network/live_updates.dart';

/// Liste des candidats ayant postulé à une offre précise — ouverte en
/// tapant sur une carte de "Mes offres d'emploi" (`EmployerDashboard` ou
/// `EmployerOffersScreen`). Données réelles (`job_applications` via
/// `JobOfferRepository.fetchApplicationsForOffer`) : "Aucune candidature"
/// si personne n'a encore postulé.
class OfferApplicantsScreen extends StatefulWidget {
  const OfferApplicantsScreen({super.key, required this.offer});

  final JobOffer offer;

  @override
  State<OfferApplicantsScreen> createState() => _OfferApplicantsScreenState();
}

class _OfferApplicantsScreenState extends State<OfferApplicantsScreen>
    with LiveRefresh<OfferApplicantsScreen> {
  final JobOfferRepository _repository = const JobOfferRepository();
  final AccountSearchRepository _accountRepository = const AccountSearchRepository();

  List<JobApplicationNotification> _applications = [];
  bool _loading = true;

  AppSurfaceColors get _colors => AppSurfaceColors.of(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Données partagées modifiées depuis un autre téléphone (voir
  /// `LiveUpdates`) : même rechargement qu'à l'ouverture.
  @override
  void onLiveUpdate() {
    _load();
  }

  Future<void> _load() async {
    final applications = await _repository.fetchApplicationsForOffer(widget.offer.id);
    if (!mounted) return;
    setState(() {
      _applications = applications;
      _loading = false;
    });
  }

  Future<void> _openApplication(JobApplicationNotification application) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateApplicationDetailScreen(notification: application),
      ),
    );
    _load();
  }

  Future<void> _viewCandidateProfile(JobApplicationNotification application) async {
    final candidate = await _accountRepository.fetchJobSeekerById(application.jobSeekerUserId);
    if (!mounted) return;
    if (candidate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le profil de ce candidat n'est pas disponible.")),
      );
      return;
    }
    final viewerId = AuthService().currentUser?.id;
    if (viewerId != null && viewerId.isNotEmpty) {
      await _accountRepository.recordProfileView(
        profileUserId: candidate.userId,
        viewerUserId: viewerId,
      );
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateProfileViewScreen(candidate: candidate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(_colors),
      appBar: const SoftAppBar(title: 'Candidats'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.safeAreaHorizontal,
                0,
                AppSpacing.safeAreaHorizontal,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(Icons.work_outline_rounded, size: 16, color: _colors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.offer.title,
                      style: AppTypography.interMedium.copyWith(
                        fontSize: 14,
                        color: _colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: SoftUi.brandInk(_colors)))
                  : _applications.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.safeAreaHorizontal,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SoftEmptyState(
                              icon: Icons.people_outline_rounded,
                              text: 'Aucune candidature reçue sur cette offre pour le moment.',
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.safeAreaHorizontal,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: _applications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) => FadeSlideIn(
                            key: ValueKey(_applications[index].applicationId),
                            delay: staggerDelayFor(index),
                            child: _buildApplicantCard(_applications[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard(JobApplicationNotification application) {
    final name = application.candidateName.trim().isNotEmpty
        ? application.candidateName.trim()
        : 'Candidat';
    final position = application.candidatePosition?.trim() ?? '';

    return SoftCard(
      onTap: () => _openApplication(application),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _viewCandidateProfile(application),
            child: SoftAvatar(name: name),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _viewCandidateProfile(application),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.interSemiBold.copyWith(fontSize: 15, color: _colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: _colors.textTertiary),
                    ],
                  ),
                ),
                if (position.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(position, style: _colors.companyName, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Text(
                  'A postulé ${application.timeLabel.toLowerCase()}',
                  style: _colors.jobInfo,
                ),
              ],
            ),
          ),
          if (application.isRejected) ...[
            const SoftDotBadge(label: 'Rejetée', color: Color(0xFFDC2626)),
            const SizedBox(width: 4),
          ] else if (application.isAccepted) ...[
            const SoftDotBadge(label: 'Acceptée', color: Color(0xFF0F8A6E)),
            const SizedBox(width: 4),
          ] else if (!application.isRead) ...[
            const SoftDotBadge(label: 'Nouveau', color: DashboardColors.accent),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right_rounded, color: _colors.textTertiary),
        ],
      ),
    );
  }
}
