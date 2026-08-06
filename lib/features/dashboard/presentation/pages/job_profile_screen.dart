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

class JobProfileScreen extends StatefulWidget {
  const JobProfileScreen({super.key});

  @override
  State<JobProfileScreen> createState() => _JobProfileScreenState();
}

class _JobProfileScreenState extends State<JobProfileScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _coverImageBytes;

  /// Photo choisie pendant cette session d'écran ; retombe sur la photo de
  /// profil réellement enregistrée à l'inscription (`AuthService`) tant
  /// qu'aucune nouvelle photo n'a été prise ici.
  Uint8List? _avatarImageBytes;

  /// Photo à afficher : celle re-choisie dans cette session prime, sinon
  /// la vraie photo de profil de l'utilisateur connecté (`AuthService`).
  Uint8List? get _currentAvatarBytes =>
      _avatarImageBytes ?? _authService.currentUser?.photoBytes;

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
    setState(() {
      _avatarImageBytes = bytes;
    });
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
                      // L'inscription ne collecte aucune expérience
                      // professionnelle : rien à afficher tant que la
                      // fonctionnalité n'existe pas ailleurs dans l'app.
                      child: _buildEmptySectionPlaceholder(
                        "Aucune expérience renseignée pour le moment.",
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
                onTap: () => Navigator.pop(context),
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
              onPressed: () {},
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
        // Simulation en attendant un vrai suivi des vues de profil et des
        // candidatures envoyées (aucun compteur persistant n'existe encore).
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
              '45 candidatures envoyées',
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
