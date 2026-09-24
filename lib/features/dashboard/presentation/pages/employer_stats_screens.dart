import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/soft_ui.dart';
import 'candidate_application_detail_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Écrans de détail derrière les cartes chiffrées du recruteur — le
/// "Tableau de bord" (`EmployerDashboard._buildStatisticsSection`) et le
/// bloc "Les Statistiques" du panneau latéral (`EmployerProfileSidePanel`)
/// partagent les mêmes 4 cibles :
///  - Offres actives  → `EmployerOffersScreen` (existant)
///  - Candidatures    → `EmployerNotificationsScreen` (existant)
///  - Entretiens      → [EmployerInterviewsScreen]
///  - Vues totales    → [EmployerOfferViewsScreen]
/// Toutes les listes sont réelles (aucune donnée simulée).

String _relativeLabel(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem';
  if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
  return 'il y a ${(diff.inDays / 365).floor()} an${diff.inDays >= 730 ? 's' : ''}';
}

class _StatScaffold extends StatelessWidget {
  const _StatScaffold({
    required this.title,
    required this.loading,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.child,
    this.onRefresh,
  });

  final String title;
  final bool loading;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    Widget body;
    if (loading) {
      body = Center(child: CircularProgressIndicator(color: SoftUi.brandInk(colors)));
    } else if (isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
        child: Align(
          alignment: Alignment.topCenter,
          child: SoftEmptyState(icon: emptyIcon, text: emptyMessage),
        ),
      );
    } else {
      body = child;
    }

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      appBar: SoftAppBar(title: title),
      body: SafeArea(
        child: onRefresh != null && !loading && !isEmpty
            ? RefreshIndicator(onRefresh: onRefresh!, child: body)
            : body,
      ),
    );
  }
}

/// Liste de cartes espacées, marges de page — commune aux deux écrans.
ListView _cardList({required int itemCount, required IndexedWidgetBuilder itemBuilder}) {
  return ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.safeAreaHorizontal,
      AppSpacing.sm,
      AppSpacing.safeAreaHorizontal,
      AppSpacing.xl,
    ),
    itemCount: itemCount,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, index) => FadeSlideIn(
      delay: staggerDelayFor(index),
      child: itemBuilder(context, index),
    ),
  );
}

// ===========================================================================
// Entretiens
// ===========================================================================

class EmployerInterviewsScreen extends StatefulWidget {
  const EmployerInterviewsScreen({super.key});

  @override
  State<EmployerInterviewsScreen> createState() => _EmployerInterviewsScreenState();
}

class _EmployerInterviewsScreenState extends State<EmployerInterviewsScreen> {
  final AuthService _authService = AuthService();
  final InterviewRepository _interviewRepository = const InterviewRepository();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  List<Interview> _interviews = const [];
  bool _loading = true;

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _employerUserId;
    final interviews =
        id == null ? <Interview>[] : await _interviewRepository.fetchForEmployer(id);
    if (!mounted) return;
    setState(() {
      _interviews = interviews;
      _loading = false;
    });
  }

  /// Ouvre la candidature liée à l'entretien (comme le "Voir" des cartes
  /// "Entretiens du jour" du dashboard). Si elle a été retirée entretemps,
  /// message d'info.
  Future<void> _openLinkedApplication(Interview interview) async {
    final applicationId = interview.jobApplicationId;
    final offerId = interview.jobOfferId;
    if (applicationId == null || offerId == null) {
      _showGone();
      return;
    }
    final applications = await _jobOfferRepository.fetchApplicationsForOffer(offerId);
    if (!mounted) return;
    final match =
        applications.where((a) => a.applicationId == applicationId).toList();
    if (match.isEmpty) {
      _showGone();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateApplicationDetailScreen(notification: match.first),
      ),
    );
    _load();
  }

  void _showGone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La candidature liée à cet entretien a été retirée.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _StatScaffold(
      title: 'Entretiens',
      loading: _loading,
      isEmpty: _interviews.isEmpty,
      emptyIcon: Icons.calendar_today_rounded,
      emptyMessage:
          "Aucun entretien planifié. Ouvrez une candidature reçue pour en planifier un.",
      onRefresh: _load,
      child: _cardList(
        itemCount: _interviews.length,
        itemBuilder: (context, index) {
          final interview = _interviews[index];
          // Date à définir : jamais "passé", l'entretien reste à organiser.
          final isPast = interview.scheduledDateTime?.isBefore(now) ?? false;
          return _InterviewTile(
            interview: interview,
            isPast: isPast,
            onTap: () => _openLinkedApplication(interview),
          );
        },
      ),
    );
  }
}

class _InterviewTile extends StatelessWidget {
  const _InterviewTile({
    required this.interview,
    required this.isPast,
    required this.onTap,
  });

  final Interview interview;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final name = interview.candidateName.trim().isNotEmpty
        ? interview.candidateName.trim()
        : 'Candidat';
    const amber = Color(0xFFC2780E);
    final amberInk = SoftUi.accentInk(colors, amber);
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: SoftUi.tint(colors, isPast ? colors.textTertiary : amber),
              shape: BoxShape.circle,
            ),
            child: Icon(
              interview.isVisio ? Icons.videocam_rounded : Icons.event_available_rounded,
              color: isPast ? colors.textTertiary : amberInk,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.interSemiBold.copyWith(fontSize: 15, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (interview.offerTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    interview.offerTitle.trim(),
                    style: colors.cardDescription.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${interview.whenLabel} · ${interview.locationLabel}',
                  style: colors.jobInfo.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isPast || interview.isModified) ...[
                  const SizedBox(height: 8),
                  isPast
                      ? SoftDotBadge(label: 'Passé', color: colors.textTertiary)
                      : const SoftDotBadge(label: 'Modifié', color: Color(0xFFB45309)),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
        ],
      ),
    );
  }
}

// ===========================================================================
// Vues totales
// ===========================================================================

class EmployerOfferViewsScreen extends StatefulWidget {
  const EmployerOfferViewsScreen({super.key});

  @override
  State<EmployerOfferViewsScreen> createState() => _EmployerOfferViewsScreenState();
}

class _EmployerOfferViewsScreenState extends State<EmployerOfferViewsScreen> {
  final AuthService _authService = AuthService();
  final JobOfferRepository _repository = const JobOfferRepository();
  List<OfferView> _views = const [];
  bool _loading = true;

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _employerUserId;
    final views =
        id == null ? <OfferView>[] : await _repository.fetchOfferViewsForEmployer(id);
    if (!mounted) return;
    setState(() {
      _views = views;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _StatScaffold(
      title: 'Vues totales',
      loading: _loading,
      isEmpty: _views.isEmpty,
      emptyIcon: Icons.visibility_outlined,
      emptyMessage: "Aucun candidat n'a encore consulté vos offres.",
      onRefresh: _load,
      child: _cardList(
        itemCount: _views.length,
        itemBuilder: (context, index) => _OfferViewTile(view: _views[index]),
      ),
    );
  }
}

class _OfferViewTile extends StatelessWidget {
  const _OfferViewTile({required this.view});

  final OfferView view;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final subtitleParts = <String>[
      if (view.viewerPosition != null && view.viewerPosition!.isNotEmpty)
        view.viewerPosition!,
    ];
    return SoftCard(
      child: Row(
        children: [
          SoftAvatar(
            name: view.viewerName,
            photo: view.viewerPhoto != null ? MemoryImage(view.viewerPhoto!) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.viewerName,
                  style: AppTypography.interSemiBold.copyWith(fontSize: 15, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    style: colors.cardDescription.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'A vu « ${view.offerTitle} » ${_relativeLabel(view.viewedAt)}',
                  style: colors.jobInfo.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
