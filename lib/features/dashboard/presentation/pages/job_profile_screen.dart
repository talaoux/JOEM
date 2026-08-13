import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/light_text_field.dart';
import '../../../../core/widgets/profile_photo_viewer_screen.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/job_offer_repository.dart';
import 'edit_job_seeker_profile_screen.dart';

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
  final ImagePicker _picker = ImagePicker();

  Uint8List? _coverImageBytes;

  /// Nombre réel de candidatures envoyées (`job_applications`) — `null`
  /// tant que non chargé, pour ne pas afficher un "0" trompeur pendant la
  /// requête.
  int? _applicationsCount;

  @override
  void initState() {
    super.initState();
    _loadApplicationsCount();
  }

  Future<void> _loadApplicationsCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final count = await _jobOfferRepository.countApplicationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() => _applicationsCount = count);
  }

  /// Photo de profil affichée : toujours celle de l'utilisateur connecté
  /// (`AuthService`), pour qu'un changement ici se reflète partout ailleurs
  /// dans l'app (header, panneau latéral, publication...) dès qu'on y
  /// revient.
  Uint8List? get _currentAvatarBytes => _authService.currentUser?.photoBytes;

  /// Présentation réellement saisie à l'inscription (étape "Info") — `null`
  /// si le candidat ne l'a pas renseignée, pour rester cohérent avec la
  /// suggestion "Rédigez la section 'À propos'" de la carte "Profil complété".
  String? get _about {
    final presentation = _authService.currentUser?.presentation?.trim();
    return (presentation == null || presentation.isEmpty) ? null : presentation;
  }

  /// Compétences réellement saisies à l'étape "Profil professionnel" de
  /// l'inscription.
  List<String> get _skills => _authService.currentUser?.skills ?? const [];

  /// Expériences professionnelles réellement ajoutées depuis cet écran
  /// (voir "Expérience" plus bas) — l'inscription n'en collecte aucune.
  List<JobExperience> get _experiences => _authService.currentUser?.experiences ?? const [];

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBannerAndAvatar(),
              const SizedBox(height: 7),
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
                      title: 'À propos',
                      child: Text(
                        _about ?? "Vous n'avez pas encore ajouté de présentation.",
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 14,
                          fontStyle: _about == null ? FontStyle.italic : FontStyle.normal,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Expérience',
                      trailing: IconButton(
                        onPressed: _showAddExperienceSheet,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(
                          Icons.add_circle_rounded,
                          color: OnboardingColors.violet,
                          size: 24,
                        ),
                      ),
                      child: _experiences.isEmpty
                          ? _buildEmptySectionPlaceholder(
                              "Aucune expérience renseignée pour le moment.",
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < _experiences.length; i++) ...[
                                  if (i > 0) const Divider(height: 24, color: Color(0xFFF0F0F3)),
                                  _buildExperienceRow(i, _experiences[i]),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Formation',
                      // Idem : aucune formation collectée à l'inscription.
                      child: _buildEmptySectionPlaceholder(
                        "Aucune formation renseignée pour le moment.",
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'Compétences',
                      child: _skills.isEmpty
                          ? _buildEmptySectionPlaceholder(
                              "Vous n'avez pas encore ajouté de compétence.",
                            )
                          : Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _skills
                                  .map((skill) => _buildSkillChip(skill))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionCard(
                      title: 'CV',
                      child: _buildCvContent(),
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

  Widget _buildBannerAndAvatar() {
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
            backgroundColor: Colors.white.withOpacity(0.85),
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
              decoration: const BoxDecoration(
                color: Colors.white,
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
                  'Voir la photo de profil',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewProfilePhoto();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  'Prendre une photo',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  'Choisir depuis la galerie',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
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

  Widget _buildIdentitySection() {
    final user = _authService.currentUser;
    final fullName = user != null ? '${user.firstName} ${user.lastName}' : 'Marie Martin';
    final position = user?.position?.trim();
    final subtitle = (position != null && position.isNotEmpty)
        ? '$position · Chercheur d\'emploi'
        : 'Chercheur d\'emploi';
    final location = user?.localisation?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                fullName,
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
          subtitle,
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
        // "vues du profil" reste simulé (aucun suivi des vues n'existe) ;
        // "candidatures envoyées" est réel (`job_applications`, voir
        // `_loadApplicationsCount`).
        Row(
          children: [
            Text(
              '128 vues du profil',
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
              '${_applicationsCount ?? 0} candidatures envoyées',
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
  /// seuils que la carte "Profil complété" du panneau latéral du dashboard.
  Color _completionColor(double ratio) {
    if (ratio < 0.4) return AppColors.error;
    if (ratio < 0.75) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildCompletionCard() {
    final user = _authService.currentUser;
    final ratio = (user?.profileCompletion ?? 0.0).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final color = _completionColor(ratio);
    final missingFields = user?.missingJobSeekerFieldLabels ?? const <String>[];
    final suggestions = missingFields.take(3).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profil complété',
                style: AppTypography.sectionTitle,
              ),
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
              backgroundColor: color.withOpacity(0.15),
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
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, Widget? trailing}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.sectionTitle),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  /// Texte d'état vide (italique, gris) utilisé pour "Expérience"/
  /// "Formation"/"Compétences" quand l'inscription n'a fourni aucune
  /// donnée réelle pour la section.
  Widget _buildEmptySectionPlaceholder(String message) {
    return Text(
      message,
      style: AppTypography.interRegular.copyWith(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildExperienceRow(int index, JobExperience experience) {
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
            color: OnboardingColors.lavender.withOpacity(0.6),
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
        IconButton(
          onPressed: () async {
            await _authService.deleteExperienceAt(index);
            if (!mounted) return;
            setState(() {});
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
        ),
      ],
    );
  }

  Future<void> _showAddExperienceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => const _AddExperienceSheet(),
    );

    if (!mounted) return;
    setState(() {});
  }

  Widget _buildCvContent() {
    final cvFileName = _authService.currentUser?.cvFileName;

    if (cvFileName == null) {
      return GestureDetector(
        onTap: _pickCv,
        child: Row(
          children: [
            const Icon(Icons.upload_file_rounded, color: OnboardingColors.violet, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ajouter votre CV (PDF ou image)',
                style: AppTypography.interRegular.copyWith(
                  fontSize: 13,
                  color: OnboardingColors.violet,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isPdf = cvFileName.toLowerCase().endsWith('.pdf');
    return Row(
      children: [
        Icon(
          isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
          color: OnboardingColors.violet,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            cvFileName,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.interRegular.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: _pickCv,
          child: Text(
            'Remplacer',
            style: AppTypography.interRegular.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: OnboardingColors.violet,
            ),
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
        color: OnboardingColors.lavender.withOpacity(0.6),
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

/// Plein écran, fond noir, façon visionneuse Facebook/LinkedIn : affiche la
/// photo de profil actuelle (zoomable), avec un bouton de fermeture en
/// haut à gauche.
/// Formulaire "Ajouter une expérience" (bottom sheet ouvert depuis la
/// section "Expérience" de `JobProfileScreen`) : poste, entreprise,
/// dates (ou "Poste actuel"), description facultative. Persisté pour de
/// vrai via `AuthService.addExperience`, aucune donnée simulée.
class _AddExperienceSheet extends StatefulWidget {
  const _AddExperienceSheet();

  @override
  State<_AddExperienceSheet> createState() => _AddExperienceSheetState();
}

class _AddExperienceSheetState extends State<_AddExperienceSheet> {
  final _posteController = TextEditingController();
  final _entrepriseController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _enCours = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _posteController.addListener(_onFieldChanged);
    _entrepriseController.addListener(_onFieldChanged);
    _dateDebutController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _posteController.dispose();
    _entrepriseController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _posteController.text.trim().isNotEmpty &&
      _entrepriseController.text.trim().isNotEmpty &&
      _dateDebutController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    await AuthService().addExperience(
      poste: _posteController.text.trim(),
      entreprise: _entrepriseController.text.trim(),
      dateDebut: _dateDebutController.text.trim(),
      dateFin: _enCours ? null : _dateFinController.text.trim(),
      enCours: _enCours,
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.safeAreaHorizontal,
        right: AppSpacing.safeAreaHorizontal,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text('Ajouter une expérience', style: AppTypography.dashboardTitle.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              label: 'Poste',
              hint: 'Ex: Développeur Web',
              icon: Icons.badge_outlined,
              controller: _posteController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              label: 'Entreprise',
              hint: 'Ex: Tech Solutions',
              icon: Icons.apartment_outlined,
              controller: _entrepriseController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              label: 'Date de début',
              hint: 'Ex: Janvier 2023',
              icon: Icons.calendar_today_outlined,
              controller: _dateDebutController,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => setState(() => _enCours = !_enCours),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _enCours ? OnboardingColors.violet : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _enCours ? OnboardingColors.violet : const Color(0xFFD8D8E2),
                        width: 1.5,
                      ),
                    ),
                    child: _enCours
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Poste actuel',
                    style: AppTypography.interRegular.copyWith(fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            if (!_enCours) ...[
              const SizedBox(height: AppSpacing.md),
              LightTextField(
                label: 'Date de fin',
                hint: 'Ex: Mars 2024',
                icon: Icons.calendar_today_outlined,
                controller: _dateFinController,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              label: 'Description (facultatif)',
              hint: 'Missions, réalisations...',
              icon: Icons.notes_rounded,
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isValid && !_isSaving) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OnboardingColors.violet,
                  disabledBackgroundColor: OnboardingColors.violet.withOpacity(0.4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Ajouter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
