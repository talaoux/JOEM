import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/light_text_field.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Sous-écran "Expériences" du Portfolio candidat — expériences
/// professionnelles (`job_seeker_experiences`, ajout/suppression réels,
/// dupliqué avec `JobProfileScreen` — voir CLAUDE.md, choix assumé pour que
/// le Portfolio reste un CV autonome) présentées en timeline verticale, puis
/// section "Parcours" (formations, `job_seeker_formations`, ajout/suppression
/// réels — aucune autre partie de l'app ne collecte de formation).
class PortfolioExperienceScreen extends StatefulWidget {
  const PortfolioExperienceScreen({super.key});

  @override
  State<PortfolioExperienceScreen> createState() => _PortfolioExperienceScreenState();
}

class _PortfolioExperienceScreenState extends State<PortfolioExperienceScreen> {
  final AuthService _authService = AuthService();

  Future<void> _openAddExperienceSheet() async {
    final colors = AppSurfaceColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddExperienceSheet(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteExperience(int index) async {
    await _authService.deleteExperienceAt(index);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openAddFormationSheet() async {
    final colors = AppSurfaceColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddFormationSheet(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteFormation(int index) async {
    await _authService.deleteFormationAt(index);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final experiences = _authService.currentUser?.experiences ?? const [];
    final formations = _authService.currentUser?.formations ?? const [];

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                  vertical: AppSpacing.headerPadding,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                    ),
                    Expanded(child: SerifSectionTitle('Expériences')),
                    IconButton(
                      onPressed: _openAddExperienceSheet,
                      icon: const Icon(Icons.add_rounded, color: DashboardColors.accent),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (experiences.isEmpty)
                      Text(
                        'Aucune expérience renseignée pour le moment.',
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colors.textTertiary,
                        ),
                      )
                    else
                      for (int i = 0; i < experiences.length; i++)
                        _buildTimelineRow(
                          colors,
                          isLast: i == experiences.length - 1,
                          onDelete: () => _deleteExperience(i),
                          child: _buildExperienceContent(colors, experiences[i]),
                        ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SerifSectionTitle('Parcours', fontSize: 18),
                        IconButton(
                          onPressed: _openAddFormationSheet,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(
                            Icons.add_circle_rounded,
                            color: DashboardColors.accent,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (formations.isEmpty)
                      Text(
                        'Aucune formation renseignée pour le moment.',
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colors.textTertiary,
                        ),
                      )
                    else
                      for (int i = 0; i < formations.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        _buildFormationCard(colors, i, formations[i]),
                      ],
                    const SizedBox(height: AppSpacing.sectionSpacing),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    AppSurfaceColors colors, {
    required bool isLast,
    required VoidCallback onDelete,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SoftUi.tint(colors, DashboardColors.accent),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.work_outline_rounded, color: SoftUi.brandInk(colors), size: 18),
            ),
            if (!isLast)
              Expanded(
                child: Container(width: 2, color: colors.divider, margin: const EdgeInsets.symmetric(vertical: 6)),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child),
                IconButton(
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceContent(AppSurfaceColors colors, JobExperience experience) {
    final period = experience.enCours
        ? '${experience.dateDebut} - Aujourd\'hui'
        : (experience.dateFin != null && experience.dateFin!.isNotEmpty)
            ? '${experience.dateDebut} - ${experience.dateFin}'
            : experience.dateDebut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          experience.poste,
          style: AppTypography.interRegular.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          experience.entreprise,
          style: AppTypography.interRegular.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SoftUi.brandInk(colors),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          period,
          style: AppTypography.interRegular.copyWith(fontSize: 12, color: colors.textTertiary),
        ),
        if (experience.description != null && experience.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            experience.description!,
            style: AppTypography.interRegular.copyWith(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormationCard(AppSurfaceColors colors, int index, Formation formation) {
    final period = (formation.dateFin != null && formation.dateFin!.isNotEmpty)
        ? '${formation.dateDebut} — ${formation.dateFin}'
        : formation.dateDebut;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SoftUi.tint(colors, DashboardColors.accent),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.school_outlined, color: SoftUi.brandInk(colors), size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formation.etablissement,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                if ((formation.filiere ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    formation.filiere!,
                    style: AppTypography.interRegular.copyWith(fontSize: 12.5, color: colors.textSecondary),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  period,
                  style: AppTypography.interRegular.copyWith(fontSize: 11.5, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteFormation(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
          ),
        ],
      ),
    );
  }
}

/// Formulaire "Ajouter une expérience" — même comportement que celui de
/// `JobProfileScreen` (`AuthService.addExperience`), dupliqué ici pour que
/// l'expérience soit éditable directement depuis le Portfolio aussi.
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
    final colors = AppSurfaceColors.of(context);
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
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SerifSectionTitle('Ajouter une expérience', fontSize: 21),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Poste',
              hint: 'Ex: Développeur Web',
              icon: Icons.badge_outlined,
              controller: _posteController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Entreprise',
              hint: 'Ex: Tech Solutions',
              icon: Icons.apartment_outlined,
              controller: _entrepriseController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
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
                      color: _enCours ? DashboardColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _enCours ? DashboardColors.accent : const Color(0xFFD8D8E2),
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
                    style: AppTypography.interRegular.copyWith(fontSize: 14, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
            if (!_enCours) ...[
              const SizedBox(height: AppSpacing.md),
              LightTextField(
                accentColor: DashboardColors.accent,
                label: 'Date de fin',
                hint: 'Ex: Mars 2024',
                icon: Icons.calendar_today_outlined,
                controller: _dateFinController,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
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
                  backgroundColor: SoftUi.tint(colors, DashboardColors.accent),
                  foregroundColor: SoftUi.brandInk(colors),
                  disabledBackgroundColor: colors.divider,
                  disabledForegroundColor: colors.textTertiary,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(SoftUi.brandInk(colors)),
                        ),
                      )
                    : Text('Ajouter', style: AppTypography.interSemiBold.copyWith(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire "Ajouter une formation" (section "Parcours") — persisté via
/// `AuthService.addFormation` (`job_seeker_formations`).
class _AddFormationSheet extends StatefulWidget {
  const _AddFormationSheet();

  @override
  State<_AddFormationSheet> createState() => _AddFormationSheetState();
}

class _AddFormationSheetState extends State<_AddFormationSheet> {
  final _etablissementController = TextEditingController();
  final _filiereController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _etablissementController.addListener(_onFieldChanged);
    _dateDebutController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _etablissementController.dispose();
    _filiereController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _etablissementController.text.trim().isNotEmpty &&
      _dateDebutController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    await AuthService().addFormation(
      etablissement: _etablissementController.text.trim(),
      filiere: _filiereController.text.trim().isEmpty ? null : _filiereController.text.trim(),
      dateDebut: _dateDebutController.text.trim(),
      dateFin: _dateFinController.text.trim().isEmpty ? null : _dateFinController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
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
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SerifSectionTitle('Ajouter une formation', fontSize: 21),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Établissement',
              hint: 'Ex: Institut Supérieur Polytechnique de Madagascar',
              icon: Icons.school_outlined,
              controller: _etablissementController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Filière / niveau (facultatif)',
              hint: 'Ex: 3ème année — Informatique',
              icon: Icons.menu_book_outlined,
              controller: _filiereController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Date de début',
              hint: 'Ex: 2023',
              icon: Icons.calendar_today_outlined,
              controller: _dateDebutController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Date de fin (facultatif)',
              hint: 'Ex: 2026',
              icon: Icons.calendar_today_outlined,
              controller: _dateFinController,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isValid && !_isSaving) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SoftUi.tint(colors, DashboardColors.accent),
                  foregroundColor: SoftUi.brandInk(colors),
                  disabledBackgroundColor: colors.divider,
                  disabledForegroundColor: colors.textTertiary,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(SoftUi.brandInk(colors)),
                        ),
                      )
                    : Text('Ajouter', style: AppTypography.interSemiBold.copyWith(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
