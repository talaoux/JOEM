import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/light_text_field.dart';
import 'portfolio_project_detail_screen.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Sous-écran "Projets" du Portfolio candidat — section la plus visuelle du
/// Portfolio : grandes cartes (image de couverture, titre, description,
/// technologies) plutôt qu'une simple liste texte. Ajout/suppression réels
/// (`job_seeker_portfolio_projects`, `AuthService.addPortfolioProject`/
/// `deletePortfolioProjectAt`) ; le détail (rôle, fonctionnalités, liens
/// GitHub/démo) s'ouvre sur `PortfolioProjectDetailScreen`.
class PortfolioProjectsScreen extends StatefulWidget {
  const PortfolioProjectsScreen({super.key});

  @override
  State<PortfolioProjectsScreen> createState() => _PortfolioProjectsScreenState();
}

class _PortfolioProjectsScreenState extends State<PortfolioProjectsScreen> {
  final AuthService _authService = AuthService();

  Future<void> _openAddProjectSheet() async {
    final colors = AppSurfaceColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddPortfolioProjectSheet(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteProject(int index) async {
    await _authService.deletePortfolioProjectAt(index);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openDetail(PortfolioProject project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PortfolioProjectDetailScreen(project: project)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final projects = _authService.currentUser?.portfolioProjects ?? const [];

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
                    Expanded(child: SerifSectionTitle('Projets')),
                    TextButton.icon(
                      onPressed: _openAddProjectSheet,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Ajouter'),
                      style: TextButton.styleFrom(
                        backgroundColor: SoftUi.tint(colors, DashboardColors.accent),
                        foregroundColor: SoftUi.brandInk(colors),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                child: projects.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "Aucun projet ajouté pour le moment — montrez vos réalisations aux recruteurs.",
                          textAlign: TextAlign.center,
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: colors.textTertiary,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < projects.length; i++) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.md),
                            _ProjectCard(
                              colors: colors,
                              project: projects[i],
                              onDelete: () => _deleteProject(i),
                              onTap: () => _openDetail(projects[i]),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.colors,
    required this.project,
    required this.onDelete,
    required this.onTap,
  });

  final AppSurfaceColors colors;
  final PortfolioProject project;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = project.imageBytes != null;
    final hasDescription = (project.description ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              hasImage
                  ? Image.memory(
                      project.imageBytes!,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [DashboardColors.accentLight, DashboardColors.accentDeep],
                        ),
                      ),
                      child: Icon(
                        Icons.collections_bookmark_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                    ],
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      project.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (project.technologies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: project.technologies.map((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: SoftUi.tint(colors, DashboardColors.accent),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tech,
                            style: AppTypography.interRegular.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SoftUi.brandInk(colors),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulaire "Ajouter un projet" — titre et image comme avant, plus les
/// champs facultatifs affichés sur `PortfolioProjectDetailScreen` (rôle,
/// technologies, fonctionnalités, liens GitHub/démo). Persisté via
/// `AuthService.addPortfolioProject`, aucune donnée simulée.
class _AddPortfolioProjectSheet extends StatefulWidget {
  const _AddPortfolioProjectSheet();

  @override
  State<_AddPortfolioProjectSheet> createState() => _AddPortfolioProjectSheetState();
}

class _AddPortfolioProjectSheetState extends State<_AddPortfolioProjectSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _roleController = TextEditingController();
  final _technologiesController = TextEditingController();
  final _featuresController = TextEditingController();
  final _linkController = TextEditingController();
  final _githubController = TextEditingController();
  final _demoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _roleController.dispose();
    _technologiesController.dispose();
    _featuresController.dispose();
    _linkController.dispose();
    _githubController.dispose();
    _demoController.dispose();
    super.dispose();
  }

  bool get _isValid => _titleController.text.trim().isNotEmpty;

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  void _removeImage() => setState(() => _imageBytes = null);

  List<String> _parseCommaList(String raw) =>
      raw.split(',').map((entry) => entry.trim()).where((entry) => entry.isNotEmpty).toList();

  List<String> _parseLineList(String raw) =>
      raw.split('\n').map((entry) => entry.trim()).where((entry) => entry.isNotEmpty).toList();

  Future<void> _submit() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    await AuthService().addPortfolioProject(
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      imageBytes: _imageBytes,
      role: _roleController.text.trim().isEmpty ? null : _roleController.text.trim(),
      technologies: _parseCommaList(_technologiesController.text),
      features: _parseLineList(_featuresController.text),
      githubLink: _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
      demoLink: _demoController.text.trim().isEmpty ? null : _demoController.text.trim(),
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
            SerifSectionTitle('Ajouter un projet', fontSize: 21),
            const SizedBox(height: AppSpacing.md),
            _buildImagePicker(colors),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Titre',
              hint: 'Ex: Application de gestion de stock',
              icon: Icons.title_rounded,
              controller: _titleController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Description (facultatif)',
              hint: 'Contexte, objectif du projet...',
              icon: Icons.notes_rounded,
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Votre rôle (facultatif)',
              hint: 'Ex: Développement full-stack mobile et web',
              icon: Icons.person_outline_rounded,
              controller: _roleController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Technologies (facultatif, séparées par des virgules)',
              hint: 'Ex: Flutter, Dart, Laravel',
              icon: Icons.memory_rounded,
              controller: _technologiesController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Fonctionnalités principales (facultatif, une par ligne)',
              hint: 'Ex: Recherche d\'emploi\nProfil candidat',
              icon: Icons.checklist_rounded,
              controller: _featuresController,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Lien (facultatif)',
              hint: 'Ex: github.com/vous/projet',
              icon: Icons.link_rounded,
              controller: _linkController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Lien GitHub (facultatif)',
              hint: 'Ex: github.com/vous/projet',
              icon: Icons.integration_instructions_outlined,
              controller: _githubController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Lien de démo (facultatif)',
              hint: 'Ex: demo.joem.mg',
              icon: Icons.play_circle_outline_rounded,
              controller: _demoController,
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

  Widget _buildImagePicker(AppSurfaceColors colors) {
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Image.memory(_imageBytes!, width: double.infinity, height: 140, fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8D8E2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: DashboardColors.accent, size: 26),
            const SizedBox(height: 6),
            Text(
              'Ajouter une image de couverture (facultatif)',
              style: AppTypography.jobInfo.copyWith(color: const Color(0xFFA6A6B4)),
            ),
          ],
        ),
      ),
    );
  }
}
