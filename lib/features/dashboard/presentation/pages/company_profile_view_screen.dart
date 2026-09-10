import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/account_search_repository.dart';

/// Profil d'une entreprise trouvée via `JobSearchScreen` (recherche
/// candidat) — même identité visuelle que `EmployerProfileScreen` (le
/// profil de l'entreprise connectée), mais en lecture seule : pas
/// d'édition de logo, pas de carte "Profil complété" (elle n'a de sens
/// que pour son propriétaire).
class CompanyProfileViewScreen extends StatelessWidget {
  const CompanyProfileViewScreen({super.key, required this.company});

  final CompanySearchResult company;

  static const double _bannerHeight = 130;
  static const double _avatarOverflow = 45;
  static const double _avatarBoxSize = 98;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBannerAndLogo(context, colors),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: _buildIdentitySection(colors),
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
                      colors,
                      title: 'À propos de l\'entreprise',
                      child: _buildAbout(colors),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      colors,
                      title: 'Coordonnées',
                      child: _buildContactInfo(colors),
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

  Widget _buildBannerAndLogo(BuildContext context, AppSurfaceColors colors) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const SizedBox(height: _bannerHeight + _avatarOverflow, width: double.infinity),
        Container(
          height: _bannerHeight,
          width: double.infinity,
          decoration: BoxDecoration(color: colors.divider),
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
              backgroundColor: AppColors.primaryLightest,
              backgroundImage: company.logo != null ? MemoryImage(company.logo!) : null,
              child: company.logo == null
                  ? const Icon(Icons.business_rounded, color: AppColors.primary, size: 40)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitySection(AppSurfaceColors colors) {
    final companyName = company.companyName.trim().isNotEmpty ? company.companyName.trim() : 'Entreprise';
    final contactName = company.contactName?.trim() ?? '';
    final location = company.localisation?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          companyName,
          style: colors.dashboardTitle.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          contactName.isNotEmpty ? 'Géré par $contactName' : 'Espace recruteur',
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: colors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                location,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAbout(AppSurfaceColors colors) {
    final description = company.description?.trim() ?? '';
    return Text(
      description.isNotEmpty ? description : "Cette entreprise n'a pas encore ajouté de description.",
      style: AppTypography.interRegular.copyWith(
        fontSize: 14,
        fontStyle: description.isNotEmpty ? FontStyle.normal : FontStyle.italic,
        color: colors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildContactInfo(AppSurfaceColors colors) {
    final telephone = company.telephone?.trim() ?? '';
    final location = company.localisation?.trim() ?? '';

    if (telephone.isEmpty && location.isEmpty) {
      return _buildEmptyPlaceholder(colors, "Aucune coordonnée renseignée pour le moment.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (telephone.isNotEmpty) ...[
          _buildContactRow(colors, Icons.call_rounded, telephone),
          if (location.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        ],
        if (location.isNotEmpty) _buildContactRow(colors, Icons.location_on_outlined, location),
      ],
    );
  }

  Widget _buildContactRow(AppSurfaceColors colors, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: OnboardingColors.violet),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    AppSurfaceColors colors, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: colors.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(AppSurfaceColors colors, String message) {
    return Text(
      message,
      style: AppTypography.interRegular.copyWith(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: colors.textTertiary,
      ),
    );
  }
}