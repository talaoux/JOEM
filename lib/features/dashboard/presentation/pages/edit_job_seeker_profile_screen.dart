import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';
import 'package:joem/features/job_seeker_registration/presentation/widgets/step_four_daily_rate.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Écran "Modifier le profil" — ouvert depuis l'icône stylo de
/// `JobProfileScreen`. Champs réels (ceux collectés à l'inscription, plus
/// modifiables ici) : identité, coordonnées, présentation, tarif,
/// disponibilité, modes de travail, compétences. Aucune donnée simulée :
/// toute modification est persistée via `AuthService.updateJobSeekerProfile`
/// et se reflète immédiatement dans la carte "Profil complété".
class EditJobSeekerProfileScreen extends StatefulWidget {
  const EditJobSeekerProfileScreen({super.key});

  @override
  State<EditJobSeekerProfileScreen> createState() => _EditJobSeekerProfileScreenState();
}

class _EditJobSeekerProfileScreenState extends State<EditJobSeekerProfileScreen> {
  final AuthService _authService = AuthService();

  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _titreController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _localisationController;
  late final TextEditingController _presentationController;
  late final TextEditingController _rateController;
  late final TextEditingController _newSkillController;

  late List<String> _skills;
  late Set<WorkMode> _workModes;
  String? _availability;
  bool _isSaving = false;

  static WorkMode? _workModeFromName(String name) {
    for (final mode in WorkMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _prenomController = TextEditingController(text: user?.firstName ?? '');
    _nomController = TextEditingController(text: user?.lastName ?? '');
    _titreController = TextEditingController(text: user?.position ?? '');
    _telephoneController = TextEditingController(text: user?.telephone ?? '');
    _localisationController = TextEditingController(text: user?.localisation ?? '');
    _presentationController = TextEditingController(text: user?.presentation ?? '');
    _rateController = TextEditingController(text: user?.tarifJournalier ?? '');
    _newSkillController = TextEditingController();
    _skills = List<String>.from(user?.skills ?? const []);
    _availability = user?.disponibilite;
    _workModes = (user?.workModes ?? const [])
        .map(_workModeFromName)
        .whereType<WorkMode>()
        .toSet();

    _prenomController.addListener(_onFieldChanged);
    _nomController.addListener(_onFieldChanged);
    _titreController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _titreController.dispose();
    _telephoneController.dispose();
    _localisationController.dispose();
    _presentationController.dispose();
    _rateController.dispose();
    _newSkillController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _prenomController.text.trim().isNotEmpty &&
      _nomController.text.trim().isNotEmpty &&
      _titreController.text.trim().isNotEmpty;

  void _addSkill() {
    final value = _newSkillController.text.trim();
    if (value.isEmpty || _skills.contains(value)) return;
    setState(() {
      _skills.add(value);
      _newSkillController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  /// Persiste immédiatement (comme la photo de profil/couverture) plutôt
  /// que d'attendre "Enregistrer", pour rester cohérent avec le
  /// comportement du CV sur `JobProfileScreen`.
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

  Future<void> _save() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    await _authService.updateJobSeekerProfile(
      firstName: _prenomController.text.trim(),
      lastName: _nomController.text.trim(),
      position: _titreController.text.trim(),
      telephone: _telephoneController.text.trim(),
      localisation: _localisationController.text.trim(),
      presentation: _presentationController.text.trim(),
      tarifJournalier: _rateController.text.trim(),
      disponibilite: _availability,
      skills: _skills,
      workModes: _workModes.map((mode) => mode.name).toList(),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        title: Text('Modifier le profil', style: colors.dashboardTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: 'Identité',
                children: [
                  _TwoColumnRow(
                    left: LightTextField(
                      label: 'Prénom',
                      hint: 'Hery',
                      icon: Icons.person_outline_rounded,
                      controller: _prenomController,
                    ),
                    right: LightTextField(
                      label: 'Nom',
                      hint: 'Rakoto',
                      icon: Icons.person_outline_rounded,
                      controller: _nomController,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LightTextField(
                    label: 'Titre professionnel',
                    hint: 'Ex: Développeur Web, Électricien...',
                    icon: Icons.badge_outlined,
                    controller: _titreController,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildCard(
                title: 'Coordonnées',
                children: [
                  LightTextField(
                    label: 'Téléphone',
                    hint: '+261 XX XX XXX XX',
                    icon: Icons.call_rounded,
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  LocationAutocompleteField(
                    controller: _localisationController,
                    options: kMalagasyCities,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildCard(
                title: 'À propos',
                children: [
                  LightTextField(
                    label: 'Présentation',
                    hint: 'Présentez-vous en quelques mots',
                    icon: Icons.notes_rounded,
                    controller: _presentationController,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildCard(
                title: 'Tarif et disponibilité',
                children: [
                  LightTextField(
                    label: 'Tarif journalier souhaité',
                    hint: 'Ex: 50000',
                    icon: Icons.payments_outlined,
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    suffixText: 'Ar',
                  ),
                  const SizedBox(height: 18),
                  LightDropdown(
                    label: 'Disponibilité',
                    hint: 'Sélectionnez votre disponibilité',
                    icon: Icons.event_available_outlined,
                    options: kAvailabilityOptions,
                    value: _availability,
                    onChanged: (value) => setState(() => _availability = value),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Mode de travail',
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2A2A38),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final mode in WorkMode.values)
                        _WorkModeChip(
                          mode: mode,
                          selected: _workModes.contains(mode),
                          onTap: () => setState(() {
                            if (_workModes.contains(mode)) {
                              _workModes.remove(mode);
                            } else {
                              _workModes.add(mode);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildCard(
                title: 'CV',
                children: [_buildCvContent()],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildCard(
                title: 'Compétences',
                children: [
                  if (_skills.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final skill in _skills)
                          _SkillChip(label: skill, onRemove: () => _removeSkill(skill)),
                      ],
                    ),
                  if (_skills.isNotEmpty) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LightTextField(
                          hint: 'Ex: Maçonnerie, Comptabilité...',
                          icon: Icons.star_border_rounded,
                          controller: _newSkillController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addSkill,
                        icon: const Icon(Icons.add_circle_rounded, color: OnboardingColors.violet, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isValid && !_isSaving) ? _save : null,
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
                      : const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
          ),
        ),
      ),
    );
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
              color: AppSurfaceColors.of(context).textPrimary,
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

  Widget _buildCard({required String title, required List<Widget> children}) {
    final colors = AppSurfaceColors.of(context);
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
          ...children,
        ],
      ),
    );
  }
}

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  static const double _breakpoint = 340;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 18),
            right,
          ],
        );
      },
    );
  }
}

class _WorkModeChip extends StatelessWidget {
  const _WorkModeChip({required this.mode, required this.selected, required this.onTap});

  final WorkMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? OnboardingColors.violet : const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? OnboardingColors.violet : const Color(0xFFE3E3EC)),
        ),
        child: Text(
          mode.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: OnboardingColors.lavender.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: OnboardingColors.violetDeep, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 16, color: OnboardingColors.violetDeep),
          ),
        ],
      ),
    );
  }
}
