import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/features/login/presentation/login_screen.dart';

import '../../data/account_search_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/soft_ui.dart';
import 'change_password_screen.dart';
import 'edit_employer_profile_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Écran "Paramètres" du recruteur, ouvert depuis l'item "Paramètres" de
/// `EmployerProfileSidePanel`. Miroir de `JobSeekerSettingsScreen` côté
/// recruteur : mêmes sections (Compte, Notifications, Confidentialité,
/// Affichage, Données, Zone de danger), branchées à `AuthService`/aux
/// repositories du dashboard recruteur (`employer_profiles`, migrations
/// v22/v23). La section "Affichage" (mode nuit / texte agrandi / animations
/// réduites) partage `DisplayPreferencesController` avec le parcours
/// candidat : `main.dart` bascule alors `AppSurfaceColors` clair/sombre et
/// le `MediaQuery.textScaler` global pour tout l'arbre, recruteur inclus.
class EmployerSettingsScreen extends StatefulWidget {
  const EmployerSettingsScreen({super.key});

  @override
  State<EmployerSettingsScreen> createState() => _EmployerSettingsScreenState();
}

class _EmployerSettingsScreenState extends State<EmployerSettingsScreen> {
  final AuthService _authService = AuthService();
  final AccountSearchRepository _searchRepository = const AccountSearchRepository();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  bool _isProcessing = false;

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  Future<void> _toggleCompanyVisibility(bool visible) async {
    await _authService.updateProfileVisibility(visible);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          visible
              ? 'Votre entreprise réapparaît dans la recherche des candidats.'
              : 'Votre entreprise est masquée de la recherche des candidats.',
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
              ? 'Vous serez de nouveau notifié à chaque nouvelle candidature.'
              : 'Notifications de nouvelles candidatures désactivées.',
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

  Future<void> _toggleLargeText(bool enabled) async {
    await _authService.updateLargeText(enabled);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleReducedAnimations(bool enabled) async {
    await _authService.updateReducedAnimations(enabled);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _markAllNotificationsRead() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    await _jobOfferRepository.markAllApplicationNotificationsRead(employerUserId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toutes les candidatures ont été marquées comme lues.')),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
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
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final confirmed = await _confirm(
      title: 'Effacer l\'historique de recherche',
      message: 'Toutes vos recherches de candidats enregistrées seront supprimées.',
      confirmLabel: 'Effacer',
    );
    if (!confirmed || !mounted) return;

    await _searchRepository.clearHistory(
      userId: userId,
      searchType: SearchAccountType.candidate,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique de recherche effacé.')),
    );
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditEmployerProfileScreen()),
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

    final confirmed = await _confirm(
      title: 'Supprimer mon compte',
      message:
          'Cette action est irréversible : votre profil, vos offres publiées, les '
          'candidatures reçues, les entretiens planifiés et votre historique de '
          'recherche seront définitivement supprimés.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
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
    final companyName = (user?.companyName?.trim().isNotEmpty ?? false)
        ? user!.companyName!.trim()
        : 'Votre entreprise';
    final recruiterName = (user != null && (user.firstName.isNotEmpty || user.lastName.isNotEmpty))
        ? '${user.firstName} ${user.lastName}'.trim()
        : null;
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
                _buildAccountSummary(
                  colors,
                  companyName,
                  recruiterName ?? user?.email ?? '',
                  user?.photoBytes,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  colors,
                  title: 'Compte',
                  children: [
                    _SettingsTile(
                      icon: Icons.business_outlined,
                      label: 'Modifier le profil de l\'entreprise',
                      subtitle: 'Nom, catégorie, coordonnées, description...',
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
                      label: 'Nouvelles candidatures',
                      subtitle: user?.notificationsEnabled == false
                          ? 'Désactivées : la pastille de compteur reste à zéro'
                          : 'Être notifié à chaque candidature reçue sur vos offres',
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
                      label: 'Entreprise visible dans la recherche',
                      subtitle: user?.profilVisible == false
                          ? 'Masquée : vous n\'apparaissez plus dans la recherche des candidats'
                          : 'Les candidats peuvent trouver votre entreprise en recherchant',
                      value: user?.profilVisible ?? true,
                      onChanged: _toggleCompanyVisibility,
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
                      subtitle: 'Assombrit votre espace recruteur (dashboard, profil, recherche...)',
                      value: user?.darkModeEnabled ?? false,
                      onChanged: _toggleDarkMode,
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.text_fields_rounded,
                      label: 'Texte agrandi',
                      subtitle: 'Augmente la taille du texte dans toute l\'application',
                      value: user?.largeTextEnabled ?? false,
                      onChanged: _toggleLargeText,
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.motion_photos_off_outlined,
                      label: 'Réduire les animations',
                      subtitle: 'Le dashboard et le panneau de profil s\'affichent sans fondu ni glissement',
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
                      subtitle: 'Vos recherches de candidats enregistrées',
                      onTap: _clearSearchHistory,
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
                          : 'Suppression définitive de l\'entreprise et de toutes ses données',
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
    String companyName,
    String subtitle,
    Uint8List? logoBytes,
  ) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: Row(
        children: [
          SoftAvatar(
            name: companyName,
            size: 56,
            icon: Icons.business_rounded,
            photo: logoBytes != null ? MemoryImage(logoBytes) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: AppTypography.frauncesBold.copyWith(
                    fontSize: 19,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
      onTap: enabled ? onTap : null,
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
