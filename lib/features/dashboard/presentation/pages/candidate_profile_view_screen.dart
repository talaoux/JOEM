import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/account_search_repository.dart';

/// Profil d'un candidat trouvé via `CandidateSearchScreen` (recherche
/// recruteur) — même identité visuelle que `JobProfileScreen` (le profil du
/// candidat connecté), mais en lecture seule : pas d'édition de photo, pas
/// d'ajout/suppression d'expérience, pas de carte "Profil complété" (elle
/// n'a de sens que pour son propriétaire).
class CandidateProfileViewScreen extends StatelessWidget {
  const CandidateProfileViewScreen({super.key, required this.candidate});

  final CandidateSearchResult candidate;

  static const double _bannerHeight = 130;
  static const double _avatarOverflow = 45;
  static const double _avatarBoxSize = 98;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBannerAndAvatar(context),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: _buildIdentitySection(),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'À propos',
                      child: _buildAbout(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Expérience',
                      child: candidate.experiences.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucune expérience renseignée pour le moment.",
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < candidate.experiences.length; i++) ...[
                                  if (i > 0) const Divider(height: 24, color: Color(0xFFF0F0F3)),
                                  _buildExperienceRow(candidate.experiences[i]),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Compétences',
                      child: candidate.skills.isEmpty
                          ? _buildEmptyPlaceholder(
                              "Aucune compétence renseignée pour le moment.",
                            )
                          : Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: candidate.skills.map(_buildSkillChip).toList(),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Coordonnées',
                      child: _buildContactInfo(),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerAndAvatar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const SizedBox(height: _bannerHeight + _avatarOverflow, width: double.infinity),
        Container(
          height: _bannerHeight,
          width: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFFE4E6EB)),
        ),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.safeAreaHorizontal,
          top: _bannerHeight + _avatarOverflow - _avatarBoxSize,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: OnboardingColors.violet.withValues(alpha: 0.1),
              backgroundImage: candidate.photo != null ? MemoryImage(candidate.photo!) : null,
              child: candidate.photo == null
                  ? const Icon(Icons.person_rounded, color: OnboardingColors.violet, size: 40)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitySection() {
    final fullName = candidate.fullName.isEmpty ? 'Candidat' : candidate.fullName;
    final position = candidate.position?.trim() ?? '';
    final subtitle = position.isNotEmpty ? '$position · Chercheur d\'emploi' : 'Chercheur d\'emploi';
    final location = candidate.localisation?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          style: AppTypography.dashboardTitle.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                location,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAbout() {
    final about = candidate.presentation?.trim() ?? '';
    return Text(
      about.isNotEmpty ? about : "Ce candidat n'a pas encore ajouté de présentation.",
      style: AppTypography.interRegular.copyWith(
        fontSize: 14,
        fontStyle: about.isNotEmpty ? FontStyle.normal : FontStyle.italic,
        color: const Color(0xFF6B7280),
        height: 1.5,
      ),
    );
  }

  Widget _buildContactInfo() {
    final telephone = candidate.telephone?.trim() ?? '';
    final location = candidate.localisation?.trim() ?? '';

    if (telephone.isEmpty && location.isEmpty) {
      return _buildEmptyPlaceholder("Aucune coordonnée renseignée pour le moment.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (telephone.isNotEmpty) ...[
          _buildContactRow(Icons.call_rounded, telephone),
          if (location.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        ],
        if (location.isNotEmpty) _buildContactRow(Icons.location_on_outlined, location),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: OnboardingColors.violet),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Text(
      message,
      style: AppTypography.interRegular.copyWith(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildExperienceRow(JobExperience experience) {
    final period = experience.enCours
        ? '${experience.dateDebut} - Aujourd\'hui'
        : (experience.dateFin != null && experience.dateFin!.isNotEmpty)
            ? '${experience.dateDebut} - ${experience.dateFin}'
            : experience.dateDebut;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: OnboardingColors.lavender.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.work_outline_rounded, color: OnboardingColors.violetDeep, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                experience.poste,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                experience.entreprise,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                period,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              if (experience.description != null && experience.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  experience.description!,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OnboardingColors.lavender.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.interRegular.copyWith(
          fontSize: 13,
          color: OnboardingColors.violetDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}