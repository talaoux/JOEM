import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/services/display_preferences_controller.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/features/login/presentation/login_screen.dart';

import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import 'change_password_screen.dart';
import 'edit_job_seeker_profile_screen.dart';
import '../widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Écran "Paramètres" du chercheur d'emploi, ouvert depuis l'item
/// "Paramètres" de `ProfileSidePanel`. Regroupe les seuls réglages
/// réellement câblés à `AuthService`/aux repositories du dashboard — pas de
/// bascule décorative sans effet (thème, langue, notifications push...)
/// tant qu'aucune infrastructure ne les soutient réellement, voir CLAUDE.md.
class JobSeekerSettingsScreen extends StatefulWidget {
  const JobSeekerSettingsScreen({super.key});

  @override
  State<JobSeekerSettingsScreen> createState() => _JobSeekerSettingsScreenState();
}

class _JobSeekerSettingsScreenState extends State<JobSeekerSettingsScreen> {
  final AuthService _authService = AuthService();
  final AccountSearchRepository _searchRepository = const AccountSearchRepository();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  bool _isProcessing = false;

  Future<void> _toggleProfileVisibility(bool visible) async {
    await _authService.updateProfileVisibility(visible);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          visible
              ? 'Votre profil est de nouveau visible par les recruteurs.'
              : 'Votre profil est masqué des résultats de recherche des recruteurs.',
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    await _authService.updateNotificationsEnabled(enabled);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Vous recevrez de nouveau des notifications de nouvelles offres.'
              : 'Notifications de nouvelles offres désactivées.',
        ),
      ),
    );
  }

  Future<void> _toggleAdsPersonalized(bool enabled) async {
    await _authService.updateAdsPersonalized(enabled);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleMarketingOptIn(bool enabled) async {
    await _authService.updateMarketingOptIn(enabled);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleDarkMode(bool enabled) async {
    await _authService.updateDarkMode(enabled);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _updateTextScale(double scale) async {
    await _authService.updateTextScale(scale);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleReducedAnimations(bool enabled) async {
    await _authService.updateReducedAnimations(enabled);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _markAllNotificationsRead() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Le message annonce "toutes les notifications" : entretiens et
    // décisions compris, pas seulement les nouvelles offres.
    await _jobOfferRepository.markAllNotificationsRead(user.id);
    await const InterviewRepository().markAllSeekerNotificationsRead(user.id);
    await _jobOfferRepository.markAllDecisionNotificationsRead(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toutes les notifications ont été marquées comme lues.')),
    );
  }

  Future<bool> _confirm({required String title, required String message, required String confirmLabel}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _clearSearchHistory() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final confirmed = await _confirm(
      title: 'Effacer l\'historique de recherche',
      message: 'Toutes vos recherches d\'entreprises enregistrées seront supprimées.',
      confirmLabel: 'Effacer',
    );
    if (!confirmed || !mounted) return;

    await _searchRepository.clearHistory(userId: user.id, searchType: SearchAccountType.company);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique de recherche effacé.')),
    );
  }

  Future<void> _clearSavedOffers() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final confirmed = await _confirm(
      title: 'Vider mes offres enregistrées',
      message: 'Toutes les offres que vous avez enregistrées ("Favoris") seront retirées.',
      confirmLabel: 'Vider',
    );
    if (!confirmed || !mounted) return;

    await _jobOfferRepository.clearSavedOffers(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offres enregistrées supprimées.')),
    );
  }

  Future<void> _deleteCv() async {
    final confirmed = await _confirm(
      title: 'Supprimer mon CV',
      message: 'Votre CV sera retiré de votre profil. Vous pourrez en ajouter un nouveau à tout moment.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed || !mounted) return;

    await _authService.deleteCv();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CV supprimé.')),
    );
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditJobSeekerProfileScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openChangePassword() async {
    if (_authService.isDemoAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les comptes de démonstration ne peuvent pas changer de mot de passe.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter de votre compte ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Se déconnecter', style: TextStyle(color: DashboardColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    if (_authService.isDemoAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les comptes de démonstration ne peuvent pas être supprimés.'),
        ),
      );
      return;
    }

    await _showDeleteAccountDialog();
  }

  Future<void> _showDeleteAccountDialog() async {
    final colors = AppSurfaceColors.of(context);
    int currentStep = 0;
    String password = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Supprimer mon compte',
            style: colors.cardTitle.copyWith(fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentStep == 0) ...[
                  _buildInstructionItem(
                    colors,
                    icon: Icons.warning_amber_rounded,
                    title: 'Action irréversible',
                    description: 'Cette action est permanente et ne peut pas être annulée.',
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    colors,
                    icon: Icons.delete_forever_rounded,
                    title: 'Données supprimées',
                    description: 'Votre profil, vos candidatures, vos offres enregistrées et votre historique de recherche seront définitivement supprimés.',
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    colors,
                    icon: Icons.cloud_off_rounded,
                    title: 'Perte d\'accès',
                    description: 'Vous perdrez immédiatement l\'accès à votre compte et à toutes vos données.',
                  ),
                ] else if (currentStep == 1) ...[
                  Text(
                    'Pour confirmer la suppression, veuillez entrer votre mot de passe.',
                    style: colors.cardDescription.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Mot de passe',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: SoftUi.tint(colors, DashboardColors.accent)),
                      ),
                    ),
                    onChanged: (value) => password = value,
                  ),
                ] else if (currentStep == 2) ...[
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Suppression de votre compte en cours...',
                      style: colors.cardDescription,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (currentStep != 2)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: colors.cardDescription.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (currentStep == 0)
              TextButton(
                onPressed: () => setState(() => currentStep = 1),
                child: Text(
                  'Continuer',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (currentStep == 1)
              TextButton(
                onPressed: password.isEmpty
                    ? null
                    : () async {
                        setState(() => currentStep = 2);
                        Navigator.pop(context);
                        await _performDeleteAccount(password);
                      },
                child: Text(
                  'Supprimer définitivement',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
    AppSurfaceColors colors, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.red),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: colors.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: colors.cardDescription.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performDeleteAccount(String password) async {
    setState(() => _isProcessing = true);
    
    // TODO: Verify password with backend before deletion
    // For now, proceed with deletion (password verification should be added)
    final deleted = await _authService.deleteAccount();
    if (!mounted) return;

    if (!deleted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer ce compte.')),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final fullName = (user != null && (user.firstName.isNotEmpty || user.lastName.isNotEmpty))
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Utilisateur';
    final isDemo = _authService.isDemoAccount;
    final colors = AppSurfaceColors.of(context);

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      appBar: const SoftAppBar(title: 'Paramètres'),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isProcessing,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: staggered([
                _buildAccountSummary(colors, fullName, user?.email ?? '', user?.photoBytes),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  colors,
                  title: 'Compte',
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Modifier le profil',
                      subtitle: 'Identité, coordonnées, compétences, CV...',
                      onTap: _openEditProfile,
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Changer le mot de passe',
                      subtitle: isDemo ? 'Indisponible pour ce compte de démonstration' : null,
                      enabled: !isDemo,
                      onTap: _openChangePassword,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  colors,
                  title: 'Notifications',
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      label: 'Nouvelles offres',
                      subtitle: user?.notificationsEnabled == false
                          ? 'Désactivées : la pastille de compteur reste à zéro'
                          : 'Être notifié des offres qui correspondent à mon profil',
                      value: user?.notificationsEnabled ?? true,
                      onChanged: _toggleNotifications,
                    ),
                    _SettingsTile(
                      icon: Icons.done_all_rounded,
                      label: 'Tout marquer comme lu',
                      subtitle: 'Vide la pastille de compteur sans rien supprimer',
                      onTap: _markAllNotificationsRead,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  colors,
                  title: 'Confidentialité',
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.visibility_outlined,
                      label: 'Profil visible par les recruteurs',
                      subtitle: user?.profilVisible == false
                          ? 'Masqué : vous n\'apparaissez plus dans leurs recherches'
                          : 'Les recruteurs peuvent vous trouver en recherchant un profil',
                      value: user?.profilVisible ?? true,
                      onChanged: _toggleProfileVisibility,
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.ads_click_rounded,
                      label: 'Publicités personnalisées',
                      subtitle: 'JOEM ne diffuse pas encore de publicité — préférence '
                          'enregistrée pour plus tard',
                      value: user?.adsPersonalized ?? true,
                      onChanged: _toggleAdsPersonalized,
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.campaign_outlined,
                      label: 'Communications marketing',
                      subtitle: 'Offres promotionnelles et actualités JOEM',
                      value: user?.marketingOptIn ?? false,
                      onChanged: _toggleMarketingOptIn,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  colors,
                  title: 'Affichage',
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      label: 'Mode nuit',
                      subtitle: 'Assombrit tout votre espace (accueil, profil, recherche...)',
                      value: user?.darkModeEnabled ?? false,
                      onChanged: _toggleDarkMode,
                    ),
                    _TextScaleSliderTile(
                      icon: Icons.text_fields_rounded,
                      label: 'Taille du texte',
                      subtitle: 'Ajustez la taille du texte dans toute l\'application',
                      value: user?.textScale ?? 1.0,
                      onChanged: _updateTextScale,
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.motion_photos_off_outlined,
                      label: 'Réduire les animations',
                      subtitle: 'Accueil et panneau de profil s\'affichent sans fondu ni glissement',
                      value: user?.reducedAnimationsEnabled ?? false,
                      onChanged: _toggleReducedAnimations,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  colors,
                  title: 'Données',
                  children: [
                    _SettingsTile(
                      icon: Icons.history_rounded,
                      label: 'Effacer l\'historique de recherche',
                      subtitle: 'Vos recherches d\'entreprises enregistrées',
                      onTap: _clearSearchHistory,
                    ),
                    _SettingsTile(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Vider mes offres enregistrées',
                      subtitle: 'Retire toutes vos offres mises en favoris',
                      onTap: _clearSavedOffers,
                    ),
                    if (user?.cvFileName != null)
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        label: 'Supprimer mon CV',
                        subtitle: user!.cvFileName,
                        destructive: true,
                        onTap: _deleteCv,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  colors,
                  title: 'Zone de danger',
                  children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Se déconnecter',
                      onTap: _confirmLogout,
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      label: 'Supprimer mon compte',
                      subtitle: isDemo
                          ? 'Indisponible pour ce compte de démonstration'
                          : 'Suppression définitive de toutes vos données',
                      enabled: !isDemo,
                      destructive: true,
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSummary(
    AppSurfaceColors colors,
    String fullName,
    String email,
    Uint8List? photoBytes,
  ) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: Row(
        children: [
          SoftAvatar(
            name: fullName,
            size: 56,
            photo: photoBytes != null ? MemoryImage(photoBytes) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: AppTypography.frauncesBold.copyWith(
                    fontSize: 19,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: colors.cardDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    AppSurfaceColors colors, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: SerifSectionTitle(title, fontSize: 18),
        ),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 1, indent: 64, endIndent: 16, color: colors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Pastille ronde teintée derrière l'icône d'une ligne de réglage.
class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon, required this.color, this.enabled = true});

  final IconData icon;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final ink = !enabled
        ? colors.textTertiary
        : (color == DashboardColors.accent ? SoftUi.brandInk(colors) : SoftUi.accentInk(colors, color));
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: SoftUi.tint(colors, enabled ? color : colors.textTertiary),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: ink),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool enabled;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final color = !enabled
        ? colors.textSecondary.withValues(alpha: 0.5)
        : (destructive ? AppColors.error : colors.textPrimary);

    return ListTile(
      onTap: onTap,
      leading: _TileIcon(
        icon: icon,
        color: destructive ? AppColors.error : DashboardColors.accent,
        enabled: enabled,
      ),
      title: Text(label, style: colors.cardTitle.copyWith(fontSize: 15, color: color)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: colors.cardDescription.copyWith(fontSize: 12))
          : null,
      trailing: enabled
          ? Icon(Icons.chevron_right_rounded, color: colors.textSecondary)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: SoftUi.brandInk(colors),
      activeTrackColor: SoftUi.tint(colors, DashboardColors.accent),
      secondary: _TileIcon(icon: icon, color: DashboardColors.accent),
      title: Text(label, style: colors.cardTitle.copyWith(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: colors.cardDescription.copyWith(fontSize: 12))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _TextScaleSliderTile extends StatelessWidget {
  const _TextScaleSliderTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final minScale = DisplayPreferencesController.minTextScale;
    final maxScale = DisplayPreferencesController.maxTextScale;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TileIcon(icon: icon, color: DashboardColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: colors.cardTitle.copyWith(fontSize: 15)),
                    Text(subtitle, style: colors.cardDescription.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.text_decrease, size: 16, color: colors.textSecondary),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: SoftUi.tint(colors, DashboardColors.accent),
                    inactiveTrackColor: colors.divider,
                    thumbColor: SoftUi.brandInk(colors),
                    overlayColor: SoftUi.tint(colors, DashboardColors.accent).withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: value,
                    min: minScale,
                    max: maxScale,
                    divisions: 9,
                    label: '${(value * 100).round()}%',
                    onChanged: onChanged,
                  ),
                ),
              ),
              Icon(Icons.text_increase, size: 16, color: colors.textSecondary),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${(value * 100).round()}%',
              style: colors.cardDescription.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
