import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class JobNotificationsScreen extends StatefulWidget {
  const JobNotificationsScreen({super.key});

  @override
  State<JobNotificationsScreen> createState() => _JobNotificationsScreenState();
}

class _JobNotificationsScreenState extends State<JobNotificationsScreen> {
  // Simulation de notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.check_circle_rounded,
      'iconColor': const Color(0xFF10B981),
      'title': 'Votre candidature a été vue',
      'message': 'Tech Solutions a consulté votre candidature pour Développeur Flutter.',
      'time': 'Il y a 10 min',
      'isRead': false,
    },
    {
      'icon': Icons.calendar_today_rounded,
      'iconColor': const Color(0xFF3B82F6),
      'title': 'Entretien confirmé',
      'message': 'Votre entretien avec Creative Agency est prévu le 18 Jan à 14:30.',
      'time': 'Il y a 1h',
      'isRead': false,
    },
    {
      'icon': Icons.person_add_alt_1_rounded,
      'iconColor': OnboardingColors.violet,
      'title': 'Complétez votre profil',
      'message': 'Ajoutez vos compétences pour augmenter vos chances d\'être recruté.',
      'time': 'Il y a 2h',
      'isRead': false,
    },
    {
      'icon': Icons.favorite_rounded,
      'iconColor': const Color(0xFFEF4444),
      'title': 'Nouvelle offre correspondant à votre profil',
      'message': 'Designer UI/UX chez Digital Corp à Antananarivo.',
      'time': 'Il y a 3h',
      'isRead': true,
    },
    {
      'icon': Icons.mark_chat_read_rounded,
      'iconColor': const Color(0xFFF59E0B),
      'title': 'Réponse reçue',
      'message': 'Finance Plus a répondu à votre candidature.',
      'time': 'Hier',
      'isRead': true,
    },
    {
      'icon': Icons.send_rounded,
      'iconColor': const Color(0xFF3B82F6),
      'title': 'Candidature envoyée',
      'message': 'Votre candidature pour Chef de Projet chez Digital Corp a bien été envoyée.',
      'time': 'Il y a 2 jours',
      'isRead': true,
    },
  ];

  bool get _hasUnread => _notifications.any((n) => n['isRead'] == false);

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _markAsRead(int index) {
    if (_notifications[index]['isRead'] == true) return;
    setState(() {
      _notifications[index]['isRead'] = true;
    });
  }

  void _markAsUnread(int index) {
    setState(() {
      _notifications[index]['isRead'] = false;
    });
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  void _showOptionsMenu(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  'Marquer comme non lue',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _markAsUnread(index);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: Text(
                  'Supprimer',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNotification(index);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeAreaHorizontal,
                vertical: AppSpacing.headerPadding,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  if (_hasUnread)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Tout marquer comme lu',
                        style: AppTypography.secondaryButton.copyWith(
                          fontSize: 13,
                          color: OnboardingColors.violet,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeAreaHorizontal,
                ),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  return _buildNotificationItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    final notification = _notifications[index];
    final bool isRead = notification['isRead'] as bool;

    return InkWell(
      onTap: () => _markAsRead(index),
      onLongPress: () => _showOptionsMenu(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isRead ? AppColors.background : OnboardingColors.lavender.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (notification['iconColor'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification['icon'] as IconData,
                color: notification['iconColor'] as Color,
                size: 20,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] as String,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification['message'] as String,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification['time'] as String,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // Pastille non lue
            if (!isRead) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: OnboardingColors.violet,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
