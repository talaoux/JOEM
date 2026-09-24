import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/profile_photo_viewer_screen.dart';
import 'soft_ui.dart';
import 'stat_card.dart';
import 'package:joem/core/widgets/animated_entrance.dart';
import 'advice_card.dart';

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

  /// Conseil affiché sous "Profil complété" ("Complétez votre profil" tant
  /// que des champs manquent, puis un conseil carrière) — calculé par
  /// `JobSeekerDashboard._careerAdvice`. `null` = pas de carte.
  final ({String title, String text})? advice;

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
    this.advice,
    this.stats = const [
      {
        'title': 'Candidatures envoyées',
        'value': '0',
        'icon': Icons.send_rounded,
        'iconColor': Color(0xFF0F8A6E),
      },
      {
        'title': 'Entretiens',
        'value': '0',
        'icon': Icons.calendar_today_rounded,
        'iconColor': Color(0xFFC2780E),
      },
      {
        'title': 'Favoris',
        'value': '0',
        'icon': Icons.favorite_rounded,
        'iconColor': Color(0xFFD1366E),
      },
      {
        'title': 'Vues du profil',
        'value': '0',
        'icon': Icons.visibility_rounded,
        'iconColor': DashboardColors.accentStrong,
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
        widthFactor: 0.78,
        heightFactor: 1,
        child: Material(
          color: SoftUi.pageBackground(colors),
          elevation: 12,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: staggered([
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
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: SoftUi.tint(colors, DashboardColors.accent),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: avatarBytes != null
                                  ? MemoryImage(avatarBytes!) as ImageProvider
                                  : AssetImage(avatarAsset),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            fullName,
                            style: AppTypography.frauncesBold.copyWith(
                              fontSize: 22,
                              color: colors.textPrimary,
                              height: 1.15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            skills,
                            style: colors.cardDescription,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: colors.cardDescription.copyWith(fontSize: 12.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const SizedBox(
                          width: double.infinity,
                          child: SerifSectionTitle('Les statistiques', fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        StatCardGroup(
                          tint: DashboardColors.accent,
                          child: GridView.count(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.05,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            children: stats.map((stat) {
                              return _buildStatItem(
                                colors,
                                title: stat['title'] as String,
                                value: stat['value'] as String,
                                accent: stat['iconColor'] as Color,
                                onTap: stat['onTap'] as VoidCallback?,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildProfileCompletionCard(colors),
                        if (advice != null) ...[
                          const SizedBox(height: 10),
                          AdviceCard(
                            title: advice!.title,
                            text: advice!.text,
                            compact: true,
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
    final accent = color ?? DashboardColors.accent;
    final ink = color == null ? SoftUi.brandInk(colors) : SoftUi.accentInk(colors, accent);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: SoftUi.tint(colors, accent),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: ink, size: 18),
      ),
      title: Text(
        label,
        style: AppTypography.interSemiBold.copyWith(
          fontSize: 14,
          color: color ?? colors.textPrimary,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  /// Rouge sous 40%, ambre entre 40% et 74%, vert à partir de 75%.
  Color _progressColor(double ratio) {
    if (ratio < 0.4) return const Color(0xFFD1366E);
    if (ratio < 0.75) return const Color(0xFFC2780E);
    return const Color(0xFF0F8A6E);
  }

  Widget _buildProfileCompletionCard(AppSurfaceColors colors) {
    final ratio = profileCompletion.clamp(0.0, 1.0);
    final percentage = (ratio * 100).round();
    final color = SoftUi.accentInk(colors, _progressColor(ratio));

    return Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onProfileCompletionTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percentage %',
                    style: AppTypography.frauncesBold.copyWith(
                      fontSize: 26,
                      color: colors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'profil complété',
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
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

  /// Tuile chiffrée : gros nombre serif teinté, point + libellé.
  Widget _buildStatItem(
    AppSurfaceColors colors, {
    required String title,
    required String value,
    required Color accent,
    VoidCallback? onTap,
  }) {
    final ink = SoftUi.accentInk(colors, accent);
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTypography.frauncesBold.copyWith(
                    fontSize: 28,
                    color: ink,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.interMedium.copyWith(
                        fontSize: 11,
                        color: colors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
