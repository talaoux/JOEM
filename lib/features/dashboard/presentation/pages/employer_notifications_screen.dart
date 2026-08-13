import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/job_offer_repository.dart';
import 'candidate_application_detail_screen.dart';

/// Notifications recruteur — équivalent recruteur de
/// `JobNotificationsScreen` : chaque candidature reçue sur une offre de ce
/// recruteur (`job_applications`) EST une notification, pas de données
/// mockées ici, voir `JobOfferRepository.fetchApplicationNotificationsForEmployer`.
class EmployerNotificationsScreen extends StatefulWidget {
  const EmployerNotificationsScreen({super.key});

  @override
  State<EmployerNotificationsScreen> createState() =>
      _EmployerNotificationsScreenState();
}

class _EmployerNotificationsScreenState
    extends State<EmployerNotificationsScreen> {
  final AuthService _authService = AuthService();
  final JobOfferRepository _repository = const JobOfferRepository();

  List<JobApplicationNotification> _notifications = [];
  bool _loading = true;

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) {
      setState(() => _loading = false);
      return;
    }
    final notifications =
        await _repository.fetchApplicationNotificationsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  bool get _hasUnread => _notifications.any((n) => !n.isRead);

  Future<void> _markAllAsRead() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    await _repository.markAllApplicationNotificationsRead(employerUserId);
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map((n) => JobApplicationNotification(
                applicationId: n.applicationId,
                jobSeekerUserId: n.jobSeekerUserId,
                offer: n.offer,
                candidateName: n.candidateName,
                candidatePosition: n.candidatePosition,
                appliedAt: n.appliedAt,
                isRead: true,
              ))
          .toList();
    });
  }

  Future<void> _markAsRead(int index) async {
    if (_notifications[index].isRead) return;
    final notification = _notifications[index];
    await _repository.markApplicationNotificationRead(notification.applicationId);
    if (!mounted) return;
    setState(() {
      _notifications[index] = JobApplicationNotification(
        applicationId: notification.applicationId,
        jobSeekerUserId: notification.jobSeekerUserId,
        offer: notification.offer,
        candidateName: notification.candidateName,
        candidatePosition: notification.candidatePosition,
        appliedAt: notification.appliedAt,
        isRead: true,
      );
    });
  }

  Future<void> _markAsUnread(int index) async {
    final notification = _notifications[index];
    await _repository.markApplicationNotificationUnread(notification.applicationId);
    if (!mounted) return;
    setState(() {
      _notifications[index] = JobApplicationNotification(
        applicationId: notification.applicationId,
        jobSeekerUserId: notification.jobSeekerUserId,
        offer: notification.offer,
        candidateName: notification.candidateName,
        candidatePosition: notification.candidatePosition,
        appliedAt: notification.appliedAt,
        isRead: false,
      );
    });
  }

  Future<void> _deleteNotification(int index) async {
    final notification = _notifications[index];
    await _repository.deleteApplicationNotification(notification.applicationId);
    if (!mounted) return;
    setState(() {
      _notifications.removeAt(index);
    });
  }

  /// Marque la candidature comme lue puis ouvre son détail (profil du
  /// candidat + offre concernée).
  Future<void> _openApplicationDetail(int index) async {
    await _markAsRead(index);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateApplicationDetailScreen(
          notification: _notifications[index],
        ),
      ),
    );
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.safeAreaHorizontal,
                            ),
                            child: Text(
                              "Aucune candidature reçue pour le moment. Vous serez prévenu dès qu'un candidat postule à l'une de vos offres.",
                              textAlign: TextAlign.center,
                              style: AppTypography.interRegular.copyWith(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
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
    final isRead = notification.isRead;

    return InkWell(
      onTap: () => _openApplicationDetail(index),
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
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Color(0xFF3B82F6),
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
                    notification.title,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.message,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.timeLabel,
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
