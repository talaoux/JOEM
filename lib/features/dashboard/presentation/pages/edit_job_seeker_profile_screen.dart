import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';
import 'package:joem/features/job_seeker_registration/presentation/widgets/step_four_daily_rate.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

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
  late final TextEditingController _objectifsController;
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
    _objectifsController = TextEditingController(text: user?.objectifs ?? '');
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
    _objectifsController.dispose();
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
      objectifs: _objectifsController.text.trim(),
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
      backgroundColor: SoftUi.pageBackground(colors),
      appBar: const SoftAppBar(title: 'Modifier le profil'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              _buildCard(
                title: 'Identité',
                children: [
                  _TwoColumnRow(
                    left: LightTextField(
                      accentColor: DashboardColors.accent,
                      label: 'Prénom',
                      hint: 'Hery',
                      icon: Icons.person_outline_rounded,
                      controller: _prenomController,
                    ),
                    right: LightTextField(
                      accentColor: DashboardColors.accent,
                      label: 'Nom',
                      hint: 'Rakoto',
                      icon: Icons.person_outline_rounded,
                      controller: _nomController,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Titre professionnel',
                    hint: 'Ex: Développeur Web, Électricien...',
                    icon: Icons.badge_outlined,
                    controller: _titreController,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                title: 'Coordonnées',
                children: [
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Téléphone',
                    hint: '+261 XX XX XXX XX',
                    icon: Icons.call_rounded,
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  LocationAutocompleteField(
                    accentColor: DashboardColors.accent,
                    controller: _localisationController,
                    options: kMalagasyCities,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                title: 'À propos',
                children: [
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Présentation',
                    hint: 'Présentez-vous en quelques mots',
                    icon: Icons.notes_rounded,
                    controller: _presentationController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 18),
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Mes objectifs',
                    hint: 'Ce que vous recherchez professionnellement',
                    icon: Icons.track_changes_outlined,
                    controller: _objectifsController,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                title: 'Tarif et disponibilité',
                children: [
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Tarif journalier souhaité',
                    hint: 'Ex: 50000',
                    icon: Icons.payments_outlined,
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    suffixText: 'Ar',
                  ),
                  const SizedBox(height: 18),
                  LightDropdown(
                    accentColor: DashboardColors.accent,
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
                      color: colors.textPrimary,
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
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                title: 'CV',
                children: [_buildCvContent()],
              ),
              const SizedBox(height: AppSpacing.md),
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
                          accentColor: DashboardColors.accent,
                          hint: 'Ex: Maçonnerie, Comptabilité...',
                          icon: Icons.star_border_rounded,
                          controller: _newSkillController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addSkill,
                        icon: Icon(Icons.add_circle_rounded, color: SoftUi.brandInk(colors), size: 32),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              SoftPrimaryButton(
                label: 'Enregistrer',
                icon: Icons.check_rounded,
                loading: _isSaving,
                onPressed: _isValid ? _save : null,
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCvContent() {
    final colors = AppSurfaceColors.of(context);
    final cvFileName = _authService.currentUser?.cvFileName;

    if (cvFileName == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Ajoutez votre CV (PDF ou image).',
              style: AppTypography.interRegular.copyWith(fontSize: 13, color: colors.textSecondary),
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
            style: AppTypography.interMedium.copyWith(fontSize: 13.5, color: colors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SoftPillButton(label: 'Remplacer', compact: true, onPressed: _pickCv),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return SizedBox(
      width: double.infinity,
      child: SoftSection(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
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
    final colors = AppSurfaceColors.of(context);
    final ink = SoftUi.brandInk(colors);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? SoftUi.tint(colors, DashboardColors.accent)
              : (SoftUi.isDark(colors) ? colors.surface : DashboardColors.segment),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? ink : Colors.transparent, width: 1.5),
        ),
        child: Text(
          mode.label,
          style: AppTypography.interSemiBold.copyWith(
            fontSize: 13,
            color: selected ? ink : colors.textSecondary,
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
    final colors = AppSurfaceColors.of(context);
    final ink = SoftUi.brandInk(colors);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: SoftUi.tint(colors, DashboardColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.interSemiBold.copyWith(fontSize: 12.5, color: ink)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: ink),
          ),
        ],
      ),
    );
  }
}
