import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Panneau latéral affichant le logo et le nom de l'entreprise, glissant
/// depuis la droite vers le centre du dashboard — équivalent recruteur de
/// `ProfileSidePanel` (côté candidat), avec un contenu pensé pour un
/// recruteur : logo entreprise plutôt qu'avatar personnel, stats de
/// recrutement plutôt que de candidature.
class EmployerProfileSidePanel extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onClose;
  final String companyName;
  final String recruiterName;

  /// Logo réellement choisi à l'inscription — prioritaire sur l'icône par
  /// défaut quand il est renseigné.
  final Uint8List? logoBytes;
  final String location;
  final List<Map<String, dynamic>> stats;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  /// Part du profil renseignée à l'inscription (0.0 à 1.0) — affichée
  /// comme une barre de progression sous les statistiques.
  final double profileCompletion;

  /// Tap sur la carte "Profil complété" — envoie vers `EmployerProfileScreen`
  /// pour compléter les champs manquants.
  final VoidCallback? onProfileCompletionTap;

  const EmployerProfileSidePanel({
    super.key,
    required this.animation,
    required this.onClose,
    this.companyName = 'Tech Solutions',
    this.recruiterName = 'Jean Dupont',
    this.logoBytes,
    this.location = 'Antananarivo, Analamanga',
    this.onSettingsTap,
    this.onLogoutTap,
    this.profileCompletion = 0.0,
    this.onProfileCompletionTap,
    this.stats = const [
      {
        'title': 'Offres publiées',
        'value': '5',
        'icon': Icons.work_outline_rounded,
        'iconColor': Color(0xFF3B82F6),
      },
      {
        'title': 'Candidatures reçues',
        'value': '25',
        'icon': Icons.people_outline_rounded,
        'iconColor': Color(0xFF10B981),
      },
      {
        'title': 'Entretiens programmés',
        'value': '4',
        'icon': Icons.calendar_today_rounded,
        'iconColor': Color(0xFFF59E0B),
      },
      {
        'title': 'Recrutements',
        'value': '2',
        'icon': Icons.how_to_reg_rounded,
        'iconColor': Color(0xFF8B5CF6),
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
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
          color: AppColors.background,
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
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.primaryLightest,
                          backgroundImage: logoBytes != null
                              ? MemoryImage(logoBytes!) as ImageProvider
                              : null,
                          child: logoBytes == null
                              ? const Icon(
                                  Icons.business_rounded,
                                  color: AppColors.primary,
                                  size: 44,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            companyName,
                            style: AppTypography.sectionTitle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Géré par $recruiterName',
                            style: AppTypography.cardDescription,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: AppTypography.cardDescription,
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
                            style: AppTypography.cardTitle,
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
                              title: stat['title'] as String,
                              value: stat['value'] as String,
                              icon: stat['icon'] as IconData,
                              iconColor: stat['iconColor'] as Color,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileCompletionCard(),
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
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        onTap: onSettingsTap,
                      ),
                      _buildActionItem(
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

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(
        label,
        style: AppTypography.cardTitle.copyWith(
          fontSize: 14,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.statNumber.copyWith(fontSize: 16, height: 1.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.statLabel.copyWith(fontSize: 9, height: 1.1),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Rouge sous 40%, jaune entre 40% et 74%, vert à partir de 75% — même
  /// seuils que la carte "Profil complété" côté candidat.
  Color _progressColor(double ratio) {
    if (ratio < 0.4) return AppColors.error;
    if (ratio < 0.75) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildProfileCompletionCard() {
    final ratio = profileCompletion.clamp(0.0, 1.0);
    final percentage = (ratio * 100).round();
    final color = _progressColor(ratio);

    return Material(
      color: AppColors.surface,
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
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  Text(
                    '$percentage%',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14, color: color),
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
}
