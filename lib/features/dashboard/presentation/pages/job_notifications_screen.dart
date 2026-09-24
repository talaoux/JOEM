import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import 'candidate_interview_detail_screen.dart';
import 'job_categories_screen.dart';
import 'job_offer_detail_screen.dart';
import 'job_profile_screen.dart';
import 'portfolio_screen.dart';
import '../widgets/soft_ui.dart';

/// Notifications du chercheur d'emploi. Trois sources réelles, fusionnées et
/// triées par date décroissante :
/// - chaque offre publiée par un recruteur (`job_offers`, via
///   `JobOfferRepository.fetchNotificationsForJobSeeker`) ;
/// - chaque entretien planifié pour ce candidat (`interviews`, via
///   `InterviewRepository.fetchNotificationsForJobSeeker`) — "L'entreprise
///   souhaite vous rencontrer", avec la date/heure/lieu ;
/// - chaque candidature acceptée ou rejetée par un recruteur
///   (`job_applications.status`, via
///   `JobOfferRepository.fetchDecisionNotificationsForJobSeeker`) —
///   "Candidature acceptée" / "Candidature non retenue", avec le message
///   éventuel du recruteur.
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

  /// Pastille de la nav basse — même calcul que sur le dashboard, pas le
  /// nombre d'éléments non lus de [_items] (qui ignorerait le mode
  /// "muet" des notifications de nouvelles offres).
  int _navNotificationCount = 0;

  String? get _jobSeekerUserId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadNavNotificationCount();
  }

  Future<void> _loadNavNotificationCount() async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    final offersMuted = _authService.currentUser?.notificationsEnabled == false;
    final offerCount = offersMuted ? 0 : await _repository.countUnreadNotificationsForJobSeeker(userId);
    final interviewCount = await _interviewRepository.countUnreadNotificationsForJobSeeker(userId);
    final decisionCount = await _repository.countUnreadDecisionNotificationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() => _navNotificationCount = offerCount + interviewCount + decisionCount);
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
        screen = const JobCategoriesScreen();
        break;
      case 2:
        screen = const PortfolioScreen();
        break;
      default:
        screen = const JobProfileScreen();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _loadNotifications() async {
    final userId = _jobSeekerUserId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final offers = await _repository.fetchNotificationsForJobSeeker(userId);
    final interviews = await _interviewRepository.fetchNotificationsForJobSeeker(userId);
    final decisions = await _repository.fetchDecisionNotificationsForJobSeeker(userId);

    final items = <_NotifItem>[
      ...offers.map(_NotifItem.offer),
      ...interviews.map(_NotifItem.interview),
      ...decisions.map(_NotifItem.decision),
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
    await _repository.markAllDecisionNotificationsRead(userId);
    await _loadNotifications();
    _loadNavNotificationCount();
  }

  Future<void> _markAsRead(_NotifItem item) async {
    final userId = _jobSeekerUserId;
    if (userId == null || item.isRead) return;
    if (item.isDecision) {
      await _repository.markDecisionNotificationRead(item.decision!.applicationId);
    } else if (item.isInterview) {
      await _interviewRepository.markSeekerNotificationRead(item.interview!.id);
    } else {
      await _repository.markNotificationRead(item.offerNotif!.offer.id, userId);
    }
  }

  Future<void> _markAsUnread(_NotifItem item) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    if (item.isDecision) {
      await _repository.markDecisionNotificationRead(item.decision!.applicationId, read: false);
    } else if (item.isInterview) {
      await _interviewRepository.markSeekerNotificationRead(item.interview!.id, read: false);
    } else {
      await _repository.markNotificationUnread(item.offerNotif!.offer.id, userId);
    }
    await _loadNotifications();
    _loadNavNotificationCount();
  }

  Future<void> _deleteNotification(_NotifItem item) async {
    final userId = _jobSeekerUserId;
    if (userId == null) return;
    if (item.isDecision) {
      await _repository.deleteDecisionNotification(item.decision!.applicationId);
    } else if (item.isInterview) {
      await _interviewRepository.deleteSeekerNotification(item.interview!.id);
    } else {
      await _repository.deleteNotification(item.offerNotif!.offer.id, userId);
    }
    await _loadNotifications();
    _loadNavNotificationCount();
  }

  Future<void> _openNotification(_NotifItem item) async {
    await _markAsRead(item);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.isInterview
            ? CandidateInterviewDetailScreen(interview: item.interview!)
            // Offre publiée ou décision sur une candidature : le détail de
            // l'offre affiche aussi le statut et le message du recruteur.
            : JobOfferDetailScreen(offer: item.offer!),
      ),
    );
    await _loadNotifications();
    _loadNavNotificationCount();
  }

  void _showOptionsMenu(_NotifItem item) {
    final colors = AppSurfaceColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(Icons.mark_email_unread_outlined, color: colors.textPrimary),
                title: Text(
                  'Marquer comme non lue',
                  style: AppTypography.interRegular.copyWith(fontSize: 14, color: colors.textPrimary),
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
                  style: AppTypography.interRegular.copyWith(fontSize: 14, color: const Color(0xFFEF4444)),
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
      backgroundColor: SoftUi.pageBackground(colors),
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
                      child: SkeletonCardList(count: 4, cardBuilder: (context, index) => const ListRowSkeleton()),
                    )
                  : _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SoftEmptyState(
                          icon: Icons.notifications_none_rounded,
                          text:
                              'Aucune notification pour le moment. Vous serez prévenu dès qu\'une entreprise publie une offre ou vous propose un entretien.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeAreaHorizontal),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => FadeSlideIn(
                        key: ValueKey(index),
                        delay: staggerDelayFor(index),
                        child: _buildNotificationItem(colors, _items[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 3,
        onTap: _onNavTap,
        notificationCount: _navNotificationCount,
        accentColor: DashboardColors.accent,
        softHomeButton: true,
        thirdItemIcon: Icons.collections_bookmark_rounded,
        thirdItemLabel: 'Portfolio',
      ),
    );
  }

  Widget _buildNotificationItem(AppSurfaceColors colors, _NotifItem item) {
    final isRead = item.isRead;

    // Non lue : fond violet très pâle + bordure violette légère ; lue :
    // carte blanche standard (même rendu que les notifications recruteur).
    final dark = SoftUi.isDark(colors);
    return Material(
      color: isRead ? colors.background : DashboardColors.accent.withValues(alpha: dark ? 0.16 : 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isRead ? colors.divider : DashboardColors.accent.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNotification(item),
        onLongPress: () => _showOptionsMenu(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (_) {
                  // Palette de sens : offres bleu, entretiens ambre
                  // (modifié = ambre plus soutenu), candidature acceptée
                  // vert, non retenue gris ardoise (information, pas une
                  // alerte).
                  final Color accent;
                  final IconData icon;
                  if (item.isDecision) {
                    final accepted = item.decision!.isAccepted;
                    accent = accepted ? const Color(0xFF0F8A6E) : const Color(0xFF64748B);
                    icon = accepted ? Icons.verified_rounded : Icons.do_not_disturb_on_outlined;
                  } else if (item.isInterview) {
                    accent = item.interview!.isModified ? const Color(0xFFB45309) : const Color(0xFFC2780E);
                    icon = item.interview!.isModified ? Icons.edit_calendar_rounded : Icons.event_available_rounded;
                  } else {
                    accent = DashboardColors.accentStrong;
                    icon = Icons.campaign_rounded;
                  }
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: SoftUi.tint(colors, accent), shape: BoxShape.circle),
                    child: Icon(icon, color: SoftUi.accentInk(colors, accent), size: 20),
                  );
                },
              ),
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
                      style: AppTypography.interRegular.copyWith(fontSize: 13, color: colors.textSecondary),
                    ),
                    if (item.decisionMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '« ${item.decisionMessage} »',
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (item.isInterview) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          _chip(colors, Icons.calendar_today_rounded, item.interview!.dateLabel),
                          if (!item.interview!.isDateToBeDefined)
                            _chip(colors, Icons.access_time_rounded, item.interview!.timeLabel),
                          _chip(
                            colors,
                            item.interview!.isVisio ? Icons.videocam_outlined : Icons.location_on_outlined,
                            item.interview!.locationLabel,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.timeLabel,
                      style: AppTypography.interRegular.copyWith(fontSize: 12, color: colors.textTertiary),
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
                  decoration: BoxDecoration(color: SoftUi.brandInk(colors), shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(AppSurfaceColors colors, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: SoftUi.tint(colors, const Color(0xFFC2780E)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SoftUi.accentInk(colors, const Color(0xFFC2780E))),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.interRegular.copyWith(fontSize: 11, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

/// Une entrée de la liste de notifications du candidat — une offre publiée
/// ([offerNotif]), un entretien planifié ([interview]) ou une décision sur
/// une candidature — acceptée ou non retenue ([decision]).
class _NotifItem {
  _NotifItem.offer(this.offerNotif)
      : interview = null,
        decision = null;
  _NotifItem.interview(this.interview)
      : offerNotif = null,
        decision = null;
  _NotifItem.decision(this.decision)
      : offerNotif = null,
        interview = null;

  final JobOfferNotification? offerNotif;
  final Interview? interview;
  final ApplicationDecisionNotification? decision;

  bool get isInterview => interview != null;
  bool get isDecision => decision != null;

  /// Offre à ouvrir au tap (`null` pour un entretien).
  JobOffer? get offer => decision?.offer ?? offerNotif?.offer;

  /// Message laissé par le recruteur avec sa décision, s'il y en a un.
  String? get decisionMessage {
    final message = decision?.decisionMessage?.trim() ?? '';
    return message.isEmpty ? null : message;
  }

  bool get isRead {
    if (isDecision) return decision!.isRead;
    return isInterview ? interview!.seekerRead : offerNotif!.isRead;
  }

  DateTime get sortKey {
    if (isDecision) return decision!.decidedAt;
    return isInterview ? interview!.notifiedAt : offerNotif!.offer.createdAt;
  }

  String get title {
    if (isDecision) return decision!.title;
    if (!isInterview) return offerNotif!.title;
    return interview!.isModified ? 'Entretien modifié' : 'Proposition d\'entretien';
  }

  String get message {
    if (isDecision) return decision!.message;
    if (!isInterview) return offerNotif!.message;
    final offer = interview!.offerTitle.trim();
    final forPost = offer.isNotEmpty ? ' pour le poste "$offer"' : '';
    return interview!.isModified
        ? 'Une entreprise a modifié les informations de votre entretien$forPost — vérifiez la nouvelle date, l\'heure et le lieu.'
        : (offer.isNotEmpty
              ? 'Une entreprise souhaite vous rencontrer$forPost.'
              : 'Une entreprise souhaite vous rencontrer en entretien.');
  }

  String get timeLabel {
    if (isDecision) return decision!.timeLabel;
    return isInterview ? _relativeLabel(interview!.notifiedAt) : offerNotif!.offer.publishedLabel;
  }

  static String _relativeLabel(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    final sameDay = now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    if (sameDay) return "Aujourd'hui à $time";
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == dateTime.year && yesterday.month == dateTime.month && yesterday.day == dateTime.day) {
      return 'Hier à $time';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à $time';
  }
}
