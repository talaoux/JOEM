import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/widgets/profile_photo_viewer_screen.dart';

/// Panneau latéral affichant la photo de profil et le nom complet,
/// glissant depuis la droite vers le centre du dashboard.
class ProfileSidePanel extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onClose;
  final String fullName;
  final String avatarAsset;

  /// Photo réellement choisie à l'inscription — prioritaire sur
  /// [avatarAsset] quand elle est renseignée.
  final Uint8List? avatarBytes;
  final String skills;
  final String location;
  final List<Map<String, dynamic>> stats;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  /// Part du profil renseignée à l'inscription (0.0 à 1.0) — affichée
  /// comme une barre de progression sous les statistiques.
  final double profileCompletion;

  /// Les 4 cartes de "Les Statistiques". Le dashboard candidat passe des
  /// valeurs réelles + un `onTap` par carte (voir `_buildProfileSidePanel`
  /// dans `job_seeker_dashboard.dart`) vers les écrans `MyApplicationsScreen`
  /// / `MyInterviewsScreen` / `MySavedOffersScreen` / `ProfileViewersScreen`.
  /// Le défaut ci-dessous n'est qu'un repli statique et non cliquable.

  /// Tap sur la carte "Profil complété" — envoie vers `JobProfileScreen`
  /// pour compléter les champs manquants.
  final VoidCallback? onProfileCompletionTap;

  const ProfileSidePanel({
    super.key,
    required this.animation,
    required this.onClose,
    this.fullName = 'Marie Martin',
    this.avatarAsset = 'assets/images/avatar_portfolio1.jpg',
    this.avatarBytes,
    this.skills = "Développeur Flutter . Chercheur d'emploi",
    this.location = 'Antananarivo, Analamanga',
    this.onSettingsTap,
    this.onLogoutTap,
    this.profileCompletion = 0.0,
    this.onProfileCompletionTap,
    this.stats = const [
      {
        'title': 'Candidatures envoyées',
        'value': '0',
        'icon': Icons.send_rounded,
        'iconColor': Color(0xFF3B82F6),
      },
      {
        'title': 'Entretiens',
        'value': '0',
        'icon': Icons.calendar_today_rounded,
        'iconColor': Color(0xFF10B981),
      },
      {
        'title': 'Favoris',
        'value': '0',
        'icon': Icons.favorite_rounded,
        'iconColor': Color(0xFFEF4444),
      },
      {
        'title': 'Vues du profil',
        'value': '0',
        'icon': Icons.visibility_rounded,
        'iconColor': Color(0xFFF59E0B),
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return IgnorePointer(
          ignoring: animation.value == 0,
          child: Stack(
            children: [
              // Fond assombri, cliquable pour fermer
              GestureDetector(
                onTap: onClose,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45 * animation.value),
                ),
              ),
              // Panneau glissant depuis la droite
              Align(
                alignment: Alignment.centerRight,
                child: FractionalTranslation(
                  translation: Offset(1 - animation.value, 0),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      child: FractionallySizedBox(
        widthFactor: 0.7,
        heightFactor: 1,
        child: Material(
          color: colors.background,
          elevation: 12,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: onClose,
                            icon: Icon(
                              Icons.close,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePhotoViewerScreen(
                                  imageBytes: avatarBytes,
                                  fallbackAsset: avatarAsset,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 56,
                            backgroundImage: avatarBytes != null
                                ? MemoryImage(avatarBytes!) as ImageProvider
                                : AssetImage(avatarAsset),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            fullName,
                            style: colors.sectionTitle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            skills,
                            style: colors.cardDescription,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: colors.cardDescription,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Les Statistiques',
                            style: colors.cardTitle,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: stats.map((stat) {
                            return _buildStatItem(
                              colors,
                              title: stat['title'] as String,
                              value: stat['value'] as String,
                              icon: stat['icon'] as IconData,
                              iconColor: stat['iconColor'] as Color,
                              onTap: stat['onTap'] as VoidCallback?,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileCompletionCard(colors),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _buildActionItem(
                        colors,
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        onTap: onSettingsTap,
                      ),
                      _buildActionItem(
                        colors,
                        icon: Icons.logout_rounded,
                        label: 'Déconnexion',
                        onTap: onLogoutTap,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    AppSurfaceColors colors, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? colors.textPrimary),
      title: Text(
        label,
        style: colors.cardTitle.copyWith(
          fontSize: 14,
          color: color ?? colors.textPrimary,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  /// Rouge sous 40%, jaune entre 40% et 74%, vert à partir de 75%.
  Color _progressColor(double ratio) {
    if (ratio < 0.4) return AppColors.error;
    if (ratio < 0.75) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildProfileCompletionCard(AppSurfaceColors colors) {
    final ratio = profileCompletion.clamp(0.0, 1.0);
    final percentage = (ratio * 100).round();
    final color = _progressColor(ratio);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onProfileCompletionTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profil complété',
                    style: colors.cardTitle.copyWith(fontSize: 14),
                  ),
                  Text(
                    '$percentage%',
                    style: colors.cardTitle.copyWith(fontSize: 14, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    AppSurfaceColors colors, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: 16, color: colors.textTertiary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: colors.statNumber.copyWith(fontSize: 16, height: 1.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: colors.statLabel.copyWith(fontSize: 9, height: 1.1),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
