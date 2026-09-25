import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/profile_photo_viewer_screen.dart';
import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import 'edit_job_seeker_profile_screen.dart';
import 'job_categories_screen.dart';
import 'job_notifications_screen.dart';
import 'portfolio_screen.dart';
import '../../../job_seeker_registration/presentation/widgets/step_four_daily_rate.dart' show WorkMode, WorkModeLabel;
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

class JobProfileScreen extends StatefulWidget {
  const JobProfileScreen({super.key});

  @override
  State<JobProfileScreen> createState() => _JobProfileScreenState();
}

class _JobProfileScreenState extends State<JobProfileScreen> {
  static const double _bannerHeight = 130;
  static const double _avatarOverflow = 45;
  static const double _avatarBoxSize = 98; // rayon 45 * 2 + padding 4 * 2
  static const double _coverCameraIconSize = 32;

  final AuthService _authService = AuthService();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  final InterviewRepository _interviewRepository = const InterviewRepository();
  final AccountSearchRepository _searchRepository = const AccountSearchRepository();
  final ImagePicker _picker = ImagePicker();

  /// Pastille de la nav basse — même calcul que sur le dashboard (offres
  /// publiées non lues + entretiens planifiés non lus), pour que la barre
  /// reste cohérente sur les 5 écrans où elle est affichée.
  int _notificationCount = 0;

  /// Nombre réel de candidatures envoyées (`job_applications`) — `null`
  /// tant que non chargé, pour ne pas afficher un "0" trompeur pendant la
  /// requête.
  int? _applicationsCount;

  /// Nombre réel de recruteurs distincts ayant consulté le profil
  /// (`job_seeker_profile_views`, enregistré à l'ouverture de
  /// `CandidateProfileViewScreen`) — `null` tant que non chargé.
  int? _profileViewsCount;

  @override
  void initState() {
    super.initState();
    _loadApplicationsCount();
    _loadProfileViewsCount();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final offersMuted = _authService.currentUser?.notificationsEnabled == false;
    final offerCount = offersMuted
        ? 0
        : await _jobOfferRepository.countUnreadNotificationsForJobSeeker(userId);
    final interviewCount =
        await _interviewRepository.countUnreadNotificationsForJobSeeker(userId);
    final decisionCount =
        await _jobOfferRepository.countUnreadDecisionNotificationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() => _notificationCount = offerCount + interviewCount + decisionCount);
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
        screen = const JobCategoriesScreen();
        break;
      case 2:
        screen = const PortfolioScreen();
        break;
      default:
        screen = const JobNotificationsScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _loadApplicationsCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final count = await _jobOfferRepository.countApplicationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() => _applicationsCount = count);
  }

  Future<void> _loadProfileViewsCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final count = await _searchRepository.countProfileViews(userId);
    if (!mounted) return;
    setState(() => _profileViewsCount = count);
  }

  /// Photo de profil affichée : toujours celle de l'utilisateur connecté
  /// (`AuthService`), pour qu'un changement ici se reflète partout ailleurs
  /// dans l'app (header, panneau latéral, publication...) dès qu'on y
  /// revient.
  Uint8List? get _currentAvatarBytes => _authService.currentUser?.photoBytes;

  Uint8List? get _coverImageBytes => _authService.currentUser?.coverPhotoBytes;

  static WorkMode? _workModeFromName(String name) {
    for (final mode in WorkMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
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

  Future<void> _pickAvatarImage(ImageSource source) async {
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

  Future<void> _pickCv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    await _authService.updateCv(cvBytes: file.bytes!, cvFileName: file.name);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditJobSeekerProfileScreen()),
    );
    if (!mounted || updated != true) return;
    setState(() {});
  }

  List<PortfolioProject> get _portfolioProjects =>
      _authService.currentUser?.portfolioProjects ?? const [];

  Future<void> _openPortfolio() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PortfolioScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _viewProfilePhoto() {
    final bytes = _currentAvatarBytes;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePhotoViewerScreen(imageBytes: bytes),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              _buildBannerAndAvatar(colors),
              const SizedBox(height: 7),
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
                    _buildCompletionCard(colors),
                    const SizedBox(height: AppSpacing.md),
                    _buildPortfolioTeaser(colors),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      colors,
                      title: 'Disponibilité',
                      child: _buildAvailabilityContent(colors),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      colors,
                      title: 'CV',
                      child: _buildCvContent(),
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
        notificationCount: _notificationCount,
        accentColor: DashboardColors.accent,
        softHomeButton: true,
        thirdItemIcon: Icons.collections_bookmark_rounded,
        thirdItemLabel: 'Portfolio',
      ),
    );
  }

  Widget _buildBannerAndAvatar(AppSurfaceColors colors) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Sizer invisible : l'avatar déborde de 45px sous la bannière
        // (Positioned bottom: -45 plus bas). Sans lui, le Stack ne mesure
        // que les 130px de la bannière et le bas de l'avatar tombe hors de
        // sa zone de hit-test (clipBehavior ne change que le rendu, pas la
        // détection de tap) — d'où le besoin de taper 2-3 fois pour ouvrir
        // le popup photo.
        const SizedBox(height: _bannerHeight + _avatarOverflow, width: double.infinity),
        Container(
          height: _bannerHeight,
          width: double.infinity,
          // Pas de photo de couverture choisie : fond neutre plutôt que le
          // dégradé violet de la marque.
          decoration: BoxDecoration(
            color: _coverImageBytes == null
                ? DashboardColors.accent.withValues(alpha: SoftUi.isDark(colors) ? 0.22 : 0.12)
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
          child: Material(
            color: colors.background.withValues(alpha: 0.9),
            shape: CircleBorder(side: BorderSide(color: colors.divider)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 18),
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          // Ancré depuis le haut (et non le bas du Stack, agrandi pour
          // englober le débordement de l'avatar) pour rester collé au
          // coin bas-droit de la bannière de couverture, peu importe la
          // hauteur totale du Stack.
          top: _bannerHeight - AppSpacing.sm - _coverCameraIconSize,
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              width: _coverCameraIconSize,
              height: _coverCameraIconSize,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.background,
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider, width: 1),
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
          // Idem : ancré depuis le haut à sa position d'origine
          // (`_bannerHeight + _avatarOverflow - _avatarBoxSize`, identique
          // à l'ancien `bottom: -_avatarOverflow` sur un Stack de
          // `_bannerHeight` de haut) plutôt que depuis le bas du Stack
          // agrandi, sinon l'avatar descend avec lui.
          top: _bannerHeight + _avatarOverflow - _avatarBoxSize,
          child: GestureDetector(
            onTap: _showProfilePhotoOptions,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: SoftUi.pageBackground(colors),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundImage: _currentAvatarBytes != null
                    ? MemoryImage(_currentAvatarBytes!) as ImageProvider
                    : const AssetImage('assets/images/avatar_portfolio1.jpg'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProfilePhotoOptions() {
    final colors = AppSurfaceColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
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
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(
                  Icons.visibility_outlined,
                  color: colors.textPrimary,
                ),
                title: Text(
                  'Voir la photo de profil',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewProfilePhoto();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: colors.textPrimary,
                ),
                title: Text(
                  'Prendre une photo',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: colors.textPrimary,
                ),
                title: Text(
                  'Choisir depuis la galerie',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdentitySection(AppSurfaceColors colors) {
    final user = _authService.currentUser;
    final fullName = user != null ? '${user.firstName} ${user.lastName}' : '';
    final position = user?.position?.trim();
    final subtitle = (position != null && position.isNotEmpty)
        ? '$position · Chercheur d\'emploi'
        : 'Chercheur d\'emploi';
    final location = user?.localisation?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                fullName,
                style: AppTypography.frauncesBold.copyWith(
                  fontSize: 26,
                  color: colors.textPrimary,
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
          subtitle,
          style: AppTypography.interRegular.copyWith(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        if (location != null && location.isNotEmpty) ...[
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
        const SizedBox(height: AppSpacing.md),
        // "vues du profil" est réel (`job_seeker_profile_views`, voir
        // `_loadProfileViewsCount`) ; "candidatures envoyées" aussi
        // (`job_applications`, voir `_loadApplicationsCount`).
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SoftDotBadge(
              label: '${_profileViewsCount ?? 0} vues du profil',
              color: DashboardColors.accentStrong,
            ),
            SoftDotBadge(
              label: '${_applicationsCount ?? 0} candidatures envoyées',
              color: const Color(0xFF0F8A6E),
            ),
          ],
        ),
      ],
    );
  }

  /// Rouge sous 40%, ambre entre 40% et 74%, vert à partir de 75% — même
  /// seuils que la carte "Profil complété" du panneau latéral du dashboard.
  Color _completionColor(double ratio) {
    if (ratio < 0.4) return const Color(0xFFD1366E);
    if (ratio < 0.75) return const Color(0xFFC2780E);
    return const Color(0xFF0F8A6E);
  }

  /// Bloc teinté façon "48 messages reçus · objectif 500" de la maquette.
  Widget _buildCompletionCard(AppSurfaceColors colors) {
    final user = _authService.currentUser;
    final ratio = (user?.profileCompletion ?? 0.0).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final color = SoftUi.accentInk(colors, _completionColor(ratio));
    final missingFields = user?.missingJobSeekerFieldLabels ?? const <String>[];
    final suggestions = missingFields.take(3).toList();

    return Material(
      color: DashboardColors.accent.withValues(alpha: SoftUi.isDark(colors) ? 0.16 : 0.08),
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
                      color: colors.textPrimary,
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
                          color: colors.textSecondary,
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
                        color: colors.textSecondary,
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
                  backgroundColor: colors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (suggestions.isEmpty)
                Text(
                  'Votre profil est complet, bravo !',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 12.5,
                    color: colors.textSecondary,
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
                          color: colors.background,
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
                            Flexible(
                              child: Text(
                                suggestion,
                                style: AppTypography.interMedium.copyWith(
                                  fontSize: 11.5,
                                  color: colors.textSecondary,
                                ),
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

  Widget _buildSectionCard(
    AppSurfaceColors colors, {
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return SizedBox(
      width: double.infinity,
      child: SoftSection(title: title, trailing: trailing, child: child),
    );
  }

  /// Texte d'état vide (italique, gris) utilisé pour "Disponibilité" quand
  /// aucune de ces informations n'a été renseignée.
  Widget _buildEmptySectionPlaceholder(AppSurfaceColors colors, String message) {
    return SoftEmptyState(text: message);
  }

  Widget _buildCvContent() {
    final colors = AppSurfaceColors.of(context);
    final cvFileName = _authService.currentUser?.cvFileName;

    if (cvFileName == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Ajoutez votre CV (PDF ou image) pour le joindre à vos candidatures.',
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SoftPillButton(
            label: 'Ajouter',
            icon: Icons.upload_file_rounded,
            compact: true,
            onPressed: _pickCv,
          ),
        ],
      );
    }

    final isPdf = cvFileName.toLowerCase().endsWith('.pdf');
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SoftUi.tint(colors, DashboardColors.accent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            color: SoftUi.brandInk(colors),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            cvFileName,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.interMedium.copyWith(
              fontSize: 13.5,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SoftPillButton(
          label: 'Remplacer',
          compact: true,
          onPressed: _pickCv,
        ),
      ],
    );
  }

  /// Bandeau compact renvoyant vers le Portfolio ("Portfolio", index 2) —
  /// volontairement pas de contenu dupliqué (photos/titres de projets déjà
  /// visibles là-bas) : juste le nombre de réalisations et un lien.
  Widget _buildPortfolioTeaser(AppSurfaceColors colors) {
    final count = _portfolioProjects.length;
    return SoftCard(
      onTap: _openPortfolio,
      child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SoftUi.tint(colors, DashboardColors.accent),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.collections_bookmark_rounded,
                color: SoftUi.brandInk(colors),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SerifSectionTitle('Mon Portfolio', fontSize: 18),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? "Présentation, compétences, projets... à compléter"
                        : '$count projet${count > 1 ? 's' : ''} · voir la vitrine complète',
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
    );
  }

  /// Tarif journalier, disponibilité et modes de travail — saisis à
  /// l'inscription et modifiables via `EditJobSeekerProfileScreen`, mais
  /// jamais affichés nulle part avant ça (ni ici, ni sur le Portfolio, ni
  /// côté recruteur) : information pratique propre au Profil, pas une
  /// vitrine de réalisations.
  Widget _buildAvailabilityContent(AppSurfaceColors colors) {
    final user = _authService.currentUser;
    final tarif = user?.tarifJournalier?.trim() ?? '';
    final disponibilite = user?.disponibilite?.trim() ?? '';
    final workModeLabels = (user?.workModes ?? const [])
        .map(_workModeFromName)
        .whereType<WorkMode>()
        .map((mode) => mode.label)
        .toList();

    if (tarif.isEmpty && disponibilite.isEmpty && workModeLabels.isEmpty) {
      return _buildEmptySectionPlaceholder(
        colors,
        "Vous n'avez pas encore renseigné votre tarif ou votre disponibilité.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tarif.isNotEmpty)
          _buildAvailabilityRow(colors, Icons.payments_outlined, '$tarif Ar / jour'),
        if (disponibilite.isNotEmpty) ...[
          if (tarif.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          _buildAvailabilityRow(colors, Icons.event_available_outlined, disponibilite),
        ],
        if (workModeLabels.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: workModeLabels
                .map((label) => SoftDotBadge(label: label, color: DashboardColors.accent))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilityRow(AppSurfaceColors colors, IconData icon, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: SoftUi.tint(colors, DashboardColors.accent),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: SoftUi.brandInk(colors)),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: AppTypography.interRegular.copyWith(fontSize: 14, color: colors.textPrimary),
        ),
      ],
    );
  }
}
