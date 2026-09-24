import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/soft_ui.dart';
import 'candidate_search_screen.dart';
import 'edit_employer_profile_screen.dart';
import 'employer_notifications_screen.dart';
import 'job_offer_publish_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

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
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();

  /// Pastille de la nav basse — même calcul que sur le dashboard.
  int _notificationCount = 0;

  /// Compteurs réels affichés sous l'identité (offres publiées et vues sur
  /// ces offres, `job_offers`/`job_offer_views`) — remplacent les anciens
  /// "12 offres publiées · 340 vues du profil" codés en dur. `null` tant
  /// que non chargés.
  int? _offersCount;
  int? _offerViewsCount;

  AppSurfaceColors get _colors => AppSurfaceColors.of(context);

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    final offers = await _jobOfferRepository.fetchByEmployer(employerUserId);
    final views = await _jobOfferRepository.countOfferViewsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() {
      _offersCount = offers.length;
      _offerViewsCount = views;
    });
  }

  Future<void> _loadNotificationCount() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    if (_authService.currentUser?.notificationsEnabled == false) {
      if (!mounted) return;
      setState(() => _notificationCount = 0);
      return;
    }
    final count = await _jobOfferRepository
        .countUnreadApplicationNotificationsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() => _notificationCount = count);
  }

  /// Navigation de la barre basse : remplace l'écran courant par l'écran
  /// cible (comportement d'onglets, pas d'empilement) ou revient au
  /// dashboard ("Accueil", toujours la racine de la pile de navigation
  /// après connexion).
  void _onNavTap(int index) {
    if (index == 4) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    late final Widget screen;
    switch (index) {
      case 1:
        screen = const CandidateSearchScreen();
        break;
      case 2:
        screen = const JobOfferPublishScreen();
        break;
      default:
        screen = const EmployerNotificationsScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Uint8List? get _coverImageBytes => _authService.currentUser?.coverPhotoBytes;

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
    await _authService.updateCoverPhoto(bytes);
    if (!mounted) return;
    setState(() {});
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
      backgroundColor: SoftUi.pageBackground(_colors),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              _buildBannerAndLogo(),
              const SizedBox(height: 52),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: _buildIdentitySection(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompletionCard(),
                    const SizedBox(height: AppSpacing.md),
                    SoftSection(
                      title: 'À propos de l\'entreprise',
                      child: _about != null
                          ? Text(
                              _about!,
                              style: AppTypography.interRegular.copyWith(
                                fontSize: 14,
                                color: _colors.textSecondary,
                                height: 1.5,
                              ),
                            )
                          : const SoftEmptyState(
                              icon: Icons.edit_note_rounded,
                              text: "Vous n'avez pas encore décrit votre entreprise.",
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SoftSection(
                      title: 'Coordonnées',
                      child: _buildContactInfo(),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 4,
        onTap: _onNavTap,
        secondItemIcon: Icons.search_rounded,
        secondItemLabel: 'Recherche',
        notificationCount: _notificationCount,
        accentColor: DashboardColors.accent,
        softHomeButton: true,
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
          // Pas de photo de couverture choisie : fond violet très pâle (au
          // lieu de l'ancien gris "Facebook") pour rester dans la palette.
          decoration: BoxDecoration(
            color: _coverImageBytes == null
                ? DashboardColors.accent.withValues(alpha: SoftUi.isDark(_colors) ? 0.22 : 0.12)
                : null,
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
          child: _roundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _colors.background,
                shape: BoxShape.circle,
                border: Border.all(color: _colors.divider, width: 1),
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
              decoration: BoxDecoration(
                color: SoftUi.pageBackground(_colors),
                shape: BoxShape.circle,
              ),
              child: SoftAvatar(
                name: 'Entreprise',
                size: 90,
                icon: Icons.business_rounded,
                photo: _currentLogoBytes != null ? MemoryImage(_currentLogoBytes!) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _colors.background.withValues(alpha: 0.9),
      shape: CircleBorder(side: BorderSide(color: _colors.divider)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: _colors.textPrimary, size: 18),
        ),
      ),
    );
  }

  void _showLogoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: _colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(
                  Icons.visibility_outlined,
                  color: _colors.textPrimary,
                ),
                title: Text(
                  'Voir le logo',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: _colors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: _colors.textPrimary,
                ),
                title: Text(
                  'Changer le logo',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: _colors.textPrimary,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                companyName,
                style: AppTypography.frauncesBold.copyWith(
                  fontSize: 26,
                  color: _colors.textPrimary,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SoftPillButton(
              label: 'Modifier',
              icon: Icons.edit_outlined,
              compact: true,
              onPressed: _openEditProfile,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          recruiterName.isNotEmpty
              ? 'Géré par $recruiterName'
              : 'Espace recruteur',
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            color: _colors.textSecondary,
          ),
        ),
        if (location != null && location.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: _colors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                location,
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: _colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SoftDotBadge(
              label: _offersCount == null
                  ? 'Offres publiées'
                  : '$_offersCount offre${_offersCount == 1 ? '' : 's'} publiée${_offersCount == 1 ? '' : 's'}',
              color: DashboardColors.accentStrong,
            ),
            SoftDotBadge(
              label: _offerViewsCount == null
                  ? 'Vues sur vos offres'
                  : '$_offerViewsCount vue${_offerViewsCount == 1 ? '' : 's'} sur vos offres',
              color: const Color(0xFFD1366E),
            ),
          ],
        ),
      ],
    );
  }

  /// Rouge sous 40%, ambre entre 40% et 74%, vert à partir de 75% — même
  /// seuils que côté candidat (teintes foncées de la maquette).
  Color _completionColor(double ratio) {
    if (ratio < 0.4) return const Color(0xFFD1366E);
    if (ratio < 0.75) return const Color(0xFFC2780E);
    return const Color(0xFF0F8A6E);
  }

  /// Bloc teinté façon "48 messages reçus · objectif 500" de la maquette :
  /// gros pourcentage serif, barre de progression, puis ce qu'il reste à
  /// renseigner.
  Widget _buildCompletionCard() {
    final user = _authService.currentUser;
    final ratio = (user?.employerProfileCompletion ?? 0.0).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final color = SoftUi.accentInk(_colors, _completionColor(ratio));
    final missingFields = user?.missingEmployerFieldLabels ?? const <String>[];
    final suggestions = missingFields.take(3).toList();

    return Material(
      color: DashboardColors.accent.withValues(alpha: SoftUi.isDark(_colors) ? 0.16 : 0.08),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openEditProfile,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percent %',
                    style: AppTypography.frauncesBold.copyWith(
                      fontSize: 38,
                      color: _colors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'profil complété',
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 14,
                          color: _colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'objectif 100 %',
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 12.5,
                        color: _colors.textSecondary,
                      ),
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
                  backgroundColor: _colors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (suggestions.isEmpty)
                Text(
                  'Votre profil est complet, bravo !',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 12.5,
                    color: _colors.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final suggestion in suggestions)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _colors.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              suggestion,
                              style: AppTypography.interMedium.copyWith(
                                fontSize: 11.5,
                                color: _colors.textSecondary,
                              ),
                            ),
                          ],
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
      return const SoftEmptyState(
        icon: Icons.contact_phone_outlined,
        text: 'Aucune coordonnée renseignée pour le moment.',
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: SoftUi.tint(_colors, DashboardColors.accent),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: SoftUi.brandInk(_colors)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              color: _colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
