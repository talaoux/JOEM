import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import 'candidate_interview_detail_screen.dart';
import 'job_offer_detail_screen.dart';

/// Notifications du chercheur d'emploi. Deux sources réelles, fusionnées et
/// triées par date décroissante :
/// - chaque offre publiée par un recruteur (`job_offers`, via
///   `JobOfferRepository.fetchNotificationsForJobSeeker`) ;
/// - chaque entretien planifié pour ce candidat (`interviews`, via
///   `InterviewRepository.fetchNotificationsForJobSeeker`) — "L'entreprise
///   souhaite vous rencontrer", avec la date/heure/lieu.
class JobNotificationsScreen extends StatefulWidget {
  const JobNotificationsScreen({super.key});

  @override
  State<JobNotificationsScreen> createState() => _JobNotificationsScreenState();
}

class _JobNotificationsScreenState extends State<JobNotificationsScreen> {
  final AuthService _authService = AuthService();
  final JobOfferRepository _repository = const JobOfferRepository();
  final InterviewRepository _interviewRepository = const InterviewRepository();

  List<_NotifItem> _items = [];
  bool _loading = true;

  String? get _jobSeekerUserId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = _jobSeekerUserId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final offers = await _repository.fetchNotificationsForJobSeeker(userId);
    final interviews = await _interviewRepository.fetchNotificationsForJobSeeker(userId);

    final items = <_NotifItem>[
      ...offers.map(_NotifItem.offer),
      ...interviews.map(_NotifItem.interview),
    ]..sort((a, b) => b.sortKey.compareTo(a.sortKey));

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  bool get _hasUnread => _items.any((n) => !n.isRead);

  Future<void> _markAllAsRead() async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    await _repository.markAllNotificationsRead(userId);
    await _interviewRepository.markAllSeekerNotificationsRead(userId);
    await _loadNotifications();
  }

  Future<void> _markAsRead(_NotifItem item) async {
    final userId = _jobSeekerUserId;
    if (userId == null || item.isRead) return;
    if (item.isInterview) {
      await _interviewRepository.markSeekerNotificationRead(item.interview!.id);
    } else {
      await _repository.markNotificationRead(item.offerNotif!.offer.id, userId);
    }
  }

  Future<void> _markAsUnread(_NotifItem item) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    if (item.isInterview) {
      await _interviewRepository.markSeekerNotificationRead(item.interview!.id, read: false);
    } else {
      await _repository.markNotificationUnread(item.offerNotif!.offer.id, userId);
    }
    await _loadNotifications();
  }

  Future<void> _deleteNotification(_NotifItem item) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    if (item.isInterview) {
      await _interviewRepository.deleteSeekerNotification(item.interview!.id);
    } else {
      await _repository.deleteNotification(item.offerNotif!.offer.id, userId);
    }
    await _loadNotifications();
  }

  Future<void> _openNotification(_NotifItem item) async {
    await _markAsRead(item);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.isInterview
            ? CandidateInterviewDetailScreen(interview: item.interview!)
            : JobOfferDetailScreen(offer: item.offerNotif!.offer),
      ),
    );
    await _loadNotifications();
  }

  void _showOptionsMenu(_NotifItem item) {
    final colors = AppSurfaceColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
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
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(Icons.mark_email_unread_outlined, color: colors.textPrimary),
                title: Text(
                  'Marquer comme non lue',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _markAsUnread(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: Text(
                  'Supprimer',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNotification(item);
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
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Expanded(child: Text('Notifications', style: colors.sectionTitle)),
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
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.safeAreaHorizontal,
                            ),
                            child: Text(
                              'Aucune notification pour le moment. Vous serez prévenu dès qu\'une entreprise publie une offre ou vous propose un entretien.',
                              textAlign: TextAlign.center,
                              style: AppTypography.interRegular.copyWith(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.safeAreaHorizontal,
                          ),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) => _buildNotificationItem(colors, _items[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppSurfaceColors colors, _NotifItem item) {
    final isRead = item.isRead;

    return InkWell(
      onTap: () => _openNotification(item),
      onLongPress: () => _showOptionsMenu(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isRead ? colors.background : OnboardingColors.lavender.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(builder: (_) {
              final accent = !item.isInterview
                  ? OnboardingColors.violet
                  : (item.interview!.isModified
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981));
              final icon = !item.isInterview
                  ? Icons.campaign_rounded
                  : (item.interview!.isModified
                      ? Icons.edit_calendar_rounded
                      : Icons.event_available_rounded);
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 20),
              );
            }),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 14,
                      color: colors.textPrimary,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.message,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (item.isInterview) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      children: [
                        _chip(colors, Icons.calendar_today_rounded, item.interview!.dateLabel),
                        _chip(colors, Icons.access_time_rounded, item.interview!.time),
                        _chip(
                          colors,
                          item.interview!.isVisio
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          item.interview!.locationLabel,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.timeLabel,
                    style: AppTypography.interRegular.copyWith(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _chip(AppSurfaceColors colors, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.interRegular.copyWith(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Une entrée de la liste de notifications du candidat — soit une offre
/// publiée ([offerNotif]), soit un entretien planifié ([interview]).
class _NotifItem {
  _NotifItem.offer(this.offerNotif) : interview = null;
  _NotifItem.interview(this.interview) : offerNotif = null;

  final JobOfferNotification? offerNotif;
  final Interview? interview;

  bool get isInterview => interview != null;

  bool get isRead => isInterview ? interview!.seekerRead : offerNotif!.isRead;

  DateTime get sortKey =>
      isInterview ? interview!.notifiedAt : offerNotif!.offer.createdAt;

  String get title {
    if (!isInterview) return offerNotif!.title;
    return interview!.isModified ? 'Entretien modifié' : 'Proposition d\'entretien';
  }

  String get message {
    if (!isInterview) return offerNotif!.message;
    final offer = interview!.offerTitle.trim();
    final forPost = offer.isNotEmpty ? ' pour le poste "$offer"' : '';
    return interview!.isModified
        ? 'Une entreprise a modifié les informations de votre entretien$forPost — vérifiez la nouvelle date, l\'heure et le lieu.'
        : (offer.isNotEmpty
            ? 'Une entreprise souhaite vous rencontrer$forPost.'
            : 'Une entreprise souhaite vous rencontrer en entretien.');
  }

  String get timeLabel => isInterview
      ? _relativeLabel(interview!.notifiedAt)
      : offerNotif!.offer.publishedLabel;

  static String _relativeLabel(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    final sameDay = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    if (sameDay) return "Aujourd'hui à $time";
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == dateTime.year &&
        yesterday.month == dateTime.month &&
        yesterday.day == dateTime.day) {
      return 'Hier à $time';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à $time';
  }
}
