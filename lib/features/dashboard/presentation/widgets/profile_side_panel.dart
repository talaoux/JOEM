import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Panneau latéral affichant la photo de profil et le nom complet,
/// glissant depuis la droite vers le centre du dashboard.
class ProfileSidePanel extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onClose;
  final String fullName;
  final String avatarAsset;
  final String skills;
  final String location;
  final List<Map<String, dynamic>> stats;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  const ProfileSidePanel({
    super.key,
    required this.animation,
    required this.onClose,
    this.fullName = 'Marie Martin',
    this.avatarAsset = 'assets/images/avatar_portfolio1.jpg',
    this.skills = "Développeur Flutter . Chercheur d'emploi",
    this.location = 'Antananarivo, Analamanga',
    this.onSettingsTap,
    this.onLogoutTap,
    this.stats = const [
      {
        'title': 'Candidatures envoyées',
        'value': '12',
        'icon': Icons.send_rounded,
        'iconColor': Color(0xFF3B82F6),
      },
      {
        'title': 'Entretiens',
        'value': '3',
        'icon': Icons.calendar_today_rounded,
        'iconColor': Color(0xFF10B981),
      },
      {
        'title': 'Favoris',
        'value': '8',
        'icon': Icons.favorite_rounded,
        'iconColor': Color(0xFFEF4444),
      },
      {
        'title': 'Réponses reçues',
        'value': '5',
        'icon': Icons.mark_chat_read_rounded,
        'iconColor': Color(0xFFF59E0B),
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
                          backgroundImage: AssetImage(avatarAsset),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            fullName,
                            style: AppTypography.sectionTitle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            skills,
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
}
