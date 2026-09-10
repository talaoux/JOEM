import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/job_offer_repository.dart';
import 'candidate_application_detail_screen.dart';

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

class _OfferApplicantsScreenState extends State<OfferApplicantsScreen> {
  final JobOfferRepository _repository = const JobOfferRepository();

  List<JobApplicationNotification> _applications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Candidats', style: AppTypography.sectionTitle.copyWith(fontSize: 18)),
      ),
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
              child: Text(
                widget.offer.title,
                style: AppTypography.jobTitle.copyWith(fontSize: 16),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _applications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.safeAreaHorizontal,
                            ),
                            child: Text(
                              "Aucune candidature reçue sur cette offre pour le moment.",
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.safeAreaHorizontal,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: _applications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) => _buildApplicantCard(_applications[index]),
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

    return InkWell(
      onTap: () => _openApplication(application),
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: OnboardingColors.violet.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: AppTypography.poppinsSemiBold.copyWith(
                    color: OnboardingColors.violet,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.jobTitle.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (position.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(position, style: AppTypography.companyName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'A postulé ${application.timeLabel.toLowerCase()}',
                    style: AppTypography.jobInfo,
                  ),
                ],
              ),
            ),
            if (!application.isRead)
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: OnboardingColors.violet,
                  shape: BoxShape.circle,
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
