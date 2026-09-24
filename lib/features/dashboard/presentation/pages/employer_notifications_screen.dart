import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/soft_ui.dart';
import 'candidate_application_detail_screen.dart';
import 'candidate_search_screen.dart';
import 'employer_profile_screen.dart';
import 'job_offer_publish_screen.dart';

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

  /// Pastille de la nav basse — même calcul que sur le dashboard, pas le
  /// nombre d'éléments non lus de [_notifications] (qui ignorerait le mode
  /// "muet" des notifications de nouvelles candidatures).
  int _navNotificationCount = 0;

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  AppSurfaceColors get _colors => AppSurfaceColors.of(context);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadNavNotificationCount();
  }

  Future<void> _loadNavNotificationCount() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    if (_authService.currentUser?.notificationsEnabled == false) {
      if (!mounted) return;
      setState(() => _navNotificationCount = 0);
      return;
    }
    final count = await _repository
        .countUnreadApplicationNotificationsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() => _navNotificationCount = count);
  }

  /// Navigation de la barre basse : remplace l'écran courant par l'écran
  /// cible (comportement d'onglets, pas d'empilement) ou revient au
  /// dashboard ("Accueil", toujours la racine de la pile de navigation
  /// après connexion).
  void _onNavTap(int index) {
    if (index == 3) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    late final Widget screen;
    switch (index) {
      case 1:
        screen = const CandidateSearchScreen();
        break;
      case 2:
        screen = const JobOfferPublishScreen();
        break;
      default:
        screen = const EmployerProfileScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
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
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
    _loadNavNotificationCount();
  }

  Future<void> _markAsRead(int index) async {
    if (_notifications[index].isRead) return;
    final notification = _notifications[index];
    await _repository.markApplicationNotificationRead(notification.applicationId);
    if (!mounted) return;
    setState(() {
      _notifications[index] = notification.copyWith(isRead: true);
    });
    _loadNavNotificationCount();
  }

  Future<void> _markAsUnread(int index) async {
    final notification = _notifications[index];
    await _repository.markApplicationNotificationUnread(notification.applicationId);
    if (!mounted) return;
    setState(() {
      _notifications[index] = notification.copyWith(isRead: false);
    });
    _loadNavNotificationCount();
  }

  Future<void> _deleteNotification(int index) async {
    final notification = _notifications[index];
    await _repository.deleteApplicationNotification(notification.applicationId);
    if (!mounted) return;
    setState(() {
      _notifications.removeAt(index);
    });
    _loadNavNotificationCount();
  }

  /// Marque la candidature comme lue puis ouvre son détail (profil du
  /// candidat + offre concernée).
  Future<void> _openApplicationDetail(int index) async {
    await _markAsRead(index);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateApplicationDetailScreen(
          notification: _notifications[index],
        ),
      ),
    );
    // Le recruteur a pu rejeter (ou rétablir) la candidature.
    if (mounted) _loadNotifications();
  }

  void _showOptionsMenu(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _colors.background,
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
                  color: _colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(
                  Icons.mark_email_unread_outlined,
                  color: _colors.textPrimary,
                ),
                title: Text(
                  'Marquer comme non lue',
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 14,
                    color: _colors.textPrimary,
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
      backgroundColor: SoftUi.pageBackground(_colors),
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
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _colors.textPrimary,
                    ),
                  ),
                  const Expanded(child: SerifSectionTitle('Notifications')),
                  if (_hasUnread)
                    SoftPillButton(
                      label: 'Tout lire',
                      icon: Icons.done_all_rounded,
                      compact: true,
                      onPressed: _markAllAsRead,
                    ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                      child: SkeletonCardList(
                        count: 4,
                        cardBuilder: (context, index) => const ListRowSkeleton(),
                      ),
                    )
                  : _notifications.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.safeAreaHorizontal,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SoftEmptyState(
                              icon: Icons.notifications_none_rounded,
                              text: "Aucune candidature reçue pour le moment. Vous serez prévenu dès qu'un candidat postule à l'une de vos offres.",
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.safeAreaHorizontal,
                          ),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            return FadeSlideIn(
                              key: ValueKey(index),
                              delay: staggerDelayFor(index),
                              child: _buildNotificationItem(index),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 3,
        onTap: _onNavTap,
        secondItemIcon: Icons.search_rounded,
        secondItemLabel: 'Recherche',
        notificationCount: _navNotificationCount,
        accentColor: DashboardColors.accent,
        softHomeButton: true,
      ),
    );
  }

  /// Même vert que "Candidatures" sur le Tableau de bord.
  static const Color _applicationColor = Color(0xFF0F8A6E);

  Widget _buildNotificationItem(int index) {
    final notification = _notifications[index];
    final isRead = notification.isRead;
    final dark = SoftUi.isDark(_colors);

    // Non lue : fond violet très pâle + bordure violette légère ; lue :
    // carte blanche standard.
    return Material(
      color: isRead
          ? _colors.background
          : DashboardColors.accent.withValues(alpha: dark ? 0.16 : 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isRead
              ? _colors.divider
              : DashboardColors.accent.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openApplicationDetail(index),
        onLongPress: () => _showOptionsMenu(index),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SoftUi.tint(_colors, _applicationColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: SoftUi.accentInk(_colors, _applicationColor),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 14,
                        color: _colors.textPrimary,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 13,
                        color: _colors.textSecondary,
                      ),
                    ),
                    if (notification.isRejected) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const SoftDotBadge(label: 'Rejetée', color: Color(0xFFDC2626)),
                    ] else if (notification.isAccepted) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const SoftDotBadge(label: 'Acceptée', color: Color(0xFF0F8A6E)),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.timeLabel,
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 12,
                        color: _colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: SoftUi.brandInk(_colors),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
