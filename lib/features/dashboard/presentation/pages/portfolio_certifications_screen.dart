import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/light_text_field.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Sous-écran "Certifications" du Portfolio candidat
/// (`job_seeker_certifications`) — nom, organisme, date, image et lien de
/// vérification facultatifs. Ajout/suppression réels, comme le reste du
/// Portfolio ; pas d'édition d'une certification existante (il faut la
/// supprimer et la réajouter), même limite assumée que pour les projets.
class PortfolioCertificationsScreen extends StatefulWidget {
  const PortfolioCertificationsScreen({super.key});

  @override
  State<PortfolioCertificationsScreen> createState() => _PortfolioCertificationsScreenState();
}

class _PortfolioCertificationsScreenState extends State<PortfolioCertificationsScreen> {
  final AuthService _authService = AuthService();

  Future<void> _openAddSheet() async {
    final colors = AppSurfaceColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddCertificationSheet(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _delete(int index) async {
    await _authService.deleteCertificationAt(index);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openLink(String rawLink) async {
    final trimmed = rawLink.trim();
    var uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://$trimmed');
    }
    if (uri == null) return;

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir ce lien.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final certifications = _authService.currentUser?.certifications ?? const [];

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
                    Expanded(child: SerifSectionTitle('Certifications')),
                    IconButton(
                      onPressed: _openAddSheet,
                      icon: const Icon(Icons.add_rounded, color: DashboardColors.accent),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                child: certifications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "Aucune certification ajoutée pour le moment.",
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
                          for (int i = 0; i < certifications.length; i++) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.md),
                            _buildCertificationCard(colors, i, certifications[i]),
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

  Widget _buildCertificationCard(AppSurfaceColors colors, int index, Certification certification) {
    final hasImage = certification.imageBytes != null;
    final hasLink = (certification.verificationLink ?? '').trim().isNotEmpty;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? Image.memory(certification.imageBytes!, width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52,
                    height: 52,
                    color: SoftUi.tint(colors, DashboardColors.accent),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: SoftUi.brandInk(colors),
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certification.name,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                if ((certification.organism ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    certification.organism!,
                    style: AppTypography.interRegular.copyWith(fontSize: 12.5, color: colors.textSecondary),
                  ),
                ],
                if ((certification.date ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    certification.date!,
                    style: AppTypography.interRegular.copyWith(fontSize: 11.5, color: colors.textTertiary),
                  ),
                ],
                if (hasLink) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _openLink(certification.verificationLink!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined, size: 14, color: DashboardColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Vérifier',
                          style: AppTypography.interRegular.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _delete(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
          ),
        ],
      ),
    );
  }
}

class _AddCertificationSheet extends StatefulWidget {
  const _AddCertificationSheet();

  @override
  State<_AddCertificationSheet> createState() => _AddCertificationSheetState();
}

class _AddCertificationSheetState extends State<_AddCertificationSheet> {
  final _nameController = TextEditingController();
  final _organismController = TextEditingController();
  final _dateController = TextEditingController();
  final _linkController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _organismController.dispose();
    _dateController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  void _removeImage() => setState(() => _imageBytes = null);

  Future<void> _submit() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    await AuthService().addCertification(
      name: _nameController.text.trim(),
      organism: _organismController.text.trim().isEmpty ? null : _organismController.text.trim(),
      date: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
      imageBytes: _imageBytes,
      verificationLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
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
            SerifSectionTitle('Ajouter une certification', fontSize: 21),
            const SizedBox(height: AppSpacing.md),
            _buildImagePicker(colors),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Nom de la certification',
              hint: 'Ex: Google IT Support',
              icon: Icons.workspace_premium_outlined,
              controller: _nameController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Organisme (facultatif)',
              hint: 'Ex: Google, Coursera...',
              icon: Icons.apartment_outlined,
              controller: _organismController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Date (facultatif)',
              hint: 'Ex: Juin 2025',
              icon: Icons.calendar_today_outlined,
              controller: _dateController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Lien de vérification (facultatif)',
              hint: 'Ex: credential.net/...',
              icon: Icons.verified_outlined,
              controller: _linkController,
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
            Image.memory(_imageBytes!, width: double.infinity, height: 120, fit: BoxFit.cover),
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
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8D8E2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: DashboardColors.accent, size: 24),
            const SizedBox(height: 6),
            Text(
              'Ajouter une image (facultatif)',
              style: AppTypography.jobInfo.copyWith(color: const Color(0xFFA6A6B4)),
            ),
          ],
        ),
      ),
    );
  }
}
