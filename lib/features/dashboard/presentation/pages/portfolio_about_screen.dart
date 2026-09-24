import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/light_text_field.dart';
import 'edit_job_seeker_profile_screen.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Sous-écran "À propos" du Portfolio candidat — identité, "Ma présentation",
/// "Mes objectifs" (`job_seeker_profiles.objectifs`) et "Mes liens"
/// (`job_seeker_professional_links`, ajout/suppression réels). L'identité et
/// les deux blocs de texte sont en lecture seule ici : leur modification se
/// fait via `EditJobSeekerProfileScreen` (icône stylo), comme le reste du
/// profil chercheur d'emploi.
class PortfolioAboutScreen extends StatefulWidget {
  const PortfolioAboutScreen({super.key});

  @override
  State<PortfolioAboutScreen> createState() => _PortfolioAboutScreenState();
}

class _PortfolioAboutScreenState extends State<PortfolioAboutScreen> {
  final AuthService _authService = AuthService();

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditJobSeekerProfileScreen()),
    );
    if (!mounted || updated != true) return;
    setState(() {});
  }

  Future<void> _openAddLinkSheet() async {
    final colors = AppSurfaceColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddProfessionalLinkSheet(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteLink(int index) async {
    await _authService.deleteProfessionalLinkAt(index);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openLink(String rawUrl) async {
    final trimmed = rawUrl.trim();
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
    final user = _authService.currentUser;
    final fullName = (user != null && (user.firstName.isNotEmpty || user.lastName.isNotEmpty))
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Vous';
    final position = user?.position?.trim() ?? '';
    final location = user?.localisation?.trim() ?? '';
    final email = user?.email ?? '';
    final about = user?.presentation?.trim() ?? '';
    final objectifs = user?.objectifs?.trim() ?? '';
    final links = user?.professionalLinks ?? const [];

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
                    Expanded(child: SerifSectionTitle('À propos')),
                    IconButton(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.edit_outlined, color: DashboardColors.accent),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: DashboardColors.accent.withValues(alpha: 0.1),
                            backgroundImage:
                                user?.photoBytes != null ? MemoryImage(user!.photoBytes!) : null,
                            child: user?.photoBytes == null
                                ? const Icon(Icons.person_rounded, color: DashboardColors.accent, size: 32)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SerifSectionTitle(fullName, fontSize: 21),
                              const SizedBox(height: 2),
                              Text(
                                position.isNotEmpty ? position : "Chercheur d'emploi",
                                style: AppTypography.interRegular.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (location.isNotEmpty) _buildFieldRow(colors, Icons.location_on_outlined, location),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildFieldRow(colors, Icons.mail_outline_rounded, email),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildTextCard(
                      colors,
                      icon: Icons.edit_note_rounded,
                      title: 'Ma présentation',
                      text: about,
                      placeholder: "Vous n'avez pas encore ajouté de présentation.",
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextCard(
                      colors,
                      icon: Icons.track_changes_outlined,
                      title: 'Mes objectifs',
                      text: objectifs,
                      placeholder: "Vous n'avez pas encore renseigné vos objectifs.",
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SerifSectionTitle('Mes liens', fontSize: 18),
                              IconButton(
                                onPressed: _openAddLinkSheet,
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
                          if (links.isEmpty)
                            Text(
                              'Ajoutez GitHub, LinkedIn ou votre site personnel.',
                              style: AppTypography.interRegular.copyWith(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: colors.textTertiary,
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (int i = 0; i < links.length; i++) ...[
                                  if (i > 0) Divider(height: 20, color: colors.divider),
                                  _buildLinkRow(colors, i, links[i]),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
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

  Widget _buildFieldRow(AppSurfaceColors colors, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: colors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.interRegular.copyWith(fontSize: 13, color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTextCard(
    AppSurfaceColors colors, {
    required IconData icon,
    required String title,
    required String text,
    required String placeholder,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: DashboardColors.accent),
              const SizedBox(width: 8),
              SerifSectionTitle(title, fontSize: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text.isNotEmpty ? text : placeholder,
            style: AppTypography.interRegular.copyWith(
              fontSize: 13.5,
              height: 1.6,
              fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(AppSurfaceColors colors, int index, ProfessionalLink link) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: SoftUi.tint(colors, DashboardColors.accent),
            shape: BoxShape.circle,
          ),
          child: Icon(_iconForLink(link.url), color: SoftUi.brandInk(colors), size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: () => _openLink(link.url),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.label,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 12,
                    color: DashboardColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => _deleteLink(index),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
        ),
      ],
    );
  }

  IconData _iconForLink(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('github')) return Icons.integration_instructions_outlined;
    if (lower.contains('linkedin')) return Icons.business_center_outlined;
    if (lower.contains('behance') || lower.contains('dribbble')) return Icons.palette_outlined;
    return Icons.public_rounded;
  }
}

class _AddProfessionalLinkSheet extends StatefulWidget {
  const _AddProfessionalLinkSheet();

  @override
  State<_AddProfessionalLinkSheet> createState() => _AddProfessionalLinkSheetState();
}

class _AddProfessionalLinkSheetState extends State<_AddProfessionalLinkSheet> {
  final _labelController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelController.addListener(_onFieldChanged);
    _urlController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _labelController.text.trim().isNotEmpty && _urlController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    await AuthService().addProfessionalLink(
      label: _labelController.text.trim(),
      url: _urlController.text.trim(),
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
            SerifSectionTitle('Ajouter un lien', fontSize: 21),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Libellé',
              hint: 'Ex: GitHub, LinkedIn, Site personnel...',
              icon: Icons.label_outline_rounded,
              controller: _labelController,
            ),
            const SizedBox(height: AppSpacing.md),
            LightTextField(
              accentColor: DashboardColors.accent,
              label: 'Lien',
              hint: 'Ex: github.com/vous',
              icon: Icons.link_rounded,
              controller: _urlController,
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
