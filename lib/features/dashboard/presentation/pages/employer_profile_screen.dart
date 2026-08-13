import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import 'edit_employer_profile_screen.dart';

/// Profil entreprise — équivalent recruteur de `JobProfileScreen`, mais le
/// contenu tourne autour de l'entreprise (logo, description, coordonnées)
/// plutôt que du CV d'un candidat (expérience, formation, compétences).
class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _coverImageBytes;

  /// Logo affiché : toujours celui de l'utilisateur connecté (`AuthService`),
  /// pour qu'un changement ici se reflète partout ailleurs dans l'app
  /// (header, panneau latéral, publication...) dès qu'on y revient.
  Uint8List? get _currentLogoBytes => _authService.currentUser?.photoBytes;

  /// Description de l'entreprise réellement saisie à l'inscription — `null`
  /// si non renseignée, pour rester cohérent avec la suggestion "Décrivez
  /// votre entreprise" de la carte "Profil complété".
  String? get _about {
    final description = _authService.currentUser?.presentation?.trim();
    return (description == null || description.isEmpty) ? null : description;
  }

  Future<void> _pickCoverImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _coverImageBytes = bytes;
    });
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditEmployerProfileScreen()),
    );
    if (!mounted || updated != true) return;
    setState(() {});
  }

  Future<void> _pickLogoImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _authService.updateProfilePhoto(bytes);
    if (!mounted) return;
    setState(() {});
  }

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
              _buildBannerAndLogo(),
              const SizedBox(height: 52),
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
                    _buildCompletionCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'À propos de l\'entreprise',
                      child: Text(
                        _about ??
                            "Vous n'avez pas encore décrit votre entreprise.",
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 14,
                          fontStyle: _about == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
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

  Widget _buildBannerAndLogo() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 130,
          width: double.infinity,
          // Pas de photo de couverture choisie : fond gris uni façon
          // Facebook plutôt que le dégradé violet de la marque.
          decoration: BoxDecoration(
            color: _coverImageBytes == null ? const Color(0xFFE4E6EB) : null,
            image: _coverImageBytes != null
                ? DecorationImage(
                    image: MemoryImage(_coverImageBytes!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
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
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Image.asset(
                'assets/images/appareil-photo-reflex-numerique.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.safeAreaHorizontal,
          bottom: -45,
          child: GestureDetector(
            onTap: _showLogoOptions,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.primaryLightest,
                backgroundImage: _currentLogoBytes != null
                    ? MemoryImage(_currentLogoBytes!) as ImageProvider
                    : null,
                child: _currentLogoBytes == null
                    ? const Icon(
                        Icons.business_rounded,
                        color: AppColors.primary,
                        size: 40,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  'Voir le logo',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  'Changer le logo',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickLogoImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdentitySection() {
    final user = _authService.currentUser;
    final companyName =
        (user?.companyName != null && user!.companyName!.trim().isNotEmpty)
        ? user.companyName!.trim()
        : 'Mon entreprise';
    final recruiterName = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : '';
    final location = user?.localisation?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                companyName,
                style: AppTypography.dashboardTitle.copyWith(fontSize: 20),
              ),
            ),
            IconButton(
              onPressed: _openEditProfile,
              icon: Image.asset(
                'assets/images/stylo.png',
                width: 20,
                height: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          recruiterName.isNotEmpty
              ? 'Géré par $recruiterName'
              : 'Espace recruteur',
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        if (location != null && location.isNotEmpty) ...[
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
        const SizedBox(height: AppSpacing.md),
        // Simulation en attendant un vrai suivi des offres publiées et des
        // vues du profil entreprise (aucun compteur persistant n'existe
        // encore) — même traitement que "128 vues du profil" côté candidat.
        Row(
          children: [
            Text(
              '12 offres publiées',
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: OnboardingColors.violet,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('·', style: TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '340 vues du profil',
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: OnboardingColors.violet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Rouge sous 40%, jaune entre 40% et 74%, vert à partir de 75% — même
  /// seuils que côté candidat.
  Color _completionColor(double ratio) {
    if (ratio < 0.4) return AppColors.error;
    if (ratio < 0.75) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildCompletionCard() {
    final user = _authService.currentUser;
    final ratio = (user?.employerProfileCompletion ?? 0.0).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final color = _completionColor(ratio);
    final missingFields = user?.missingEmployerFieldLabels ?? const <String>[];
    final suggestions = missingFields.take(3).toList();

    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        onTap: _openEditProfile,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profil complété', style: AppTypography.sectionTitle),
                  Text(
                    '$percent%',
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (suggestions.isEmpty)
                Text(
                  'Votre profil est complet, bravo !',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final suggestion in suggestions)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• $suggestion',
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    final user = _authService.currentUser;
    final telephone = user?.telephone?.trim();
    final localisation = user?.localisation?.trim();
    final hasTelephone = telephone != null && telephone.isNotEmpty;
    final hasLocalisation = localisation != null && localisation.isNotEmpty;

    if (!hasTelephone && !hasLocalisation) {
      return Text(
        "Aucune coordonnée renseignée pour le moment.",
        style: AppTypography.interRegular.copyWith(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: const Color(0xFF9CA3AF),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTelephone) ...[
          _buildContactRow(Icons.call_rounded, telephone),
          if (hasLocalisation) const SizedBox(height: AppSpacing.sm),
        ],
        if (hasLocalisation)
          _buildContactRow(Icons.location_on_outlined, localisation),
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
}
