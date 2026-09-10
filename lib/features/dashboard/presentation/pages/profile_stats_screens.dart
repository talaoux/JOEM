import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import 'candidate_interview_detail_screen.dart';
import 'company_profile_view_screen.dart';
import 'job_offer_detail_screen.dart';

/// Les 4 écrans de détail derrière les cartes "Les Statistiques" du panneau
/// latéral candidat (`ProfileSidePanel`) : "Candidatures envoyées",
/// "Entretiens", "Favoris" et "Vues du profil". Chaque carte ouvre l'écran
/// correspondant ; toutes les listes sont réelles (aucune donnée simulée).

/// "il y a 3 j" / "il y a 2 h" / "à l'instant".
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

/// Coquille commune : AppBar sobre + fond selon le thème + gestion des
/// états "chargement" / "liste vide".
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
      body = const Center(child: CircularProgressIndicator());
    } else if (isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 48, color: colors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: colors.cardDescription.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    } else {
      body = child;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        title: Text(title, style: colors.sectionTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: onRefresh != null && !loading && !isEmpty
            ? RefreshIndicator(onRefresh: onRefresh!, child: body)
            : body,
      ),
    );
  }
}

/// Ligne compacte d'une offre — réutilisée par "Candidatures envoyées" et
/// "Favoris". Tap → `JobOfferDetailScreen`.
class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, required this.onTap});

  final JobOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.safeAreaHorizontal,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _LogoAvatar(bytes: offer.companyLogo, fallbackIcon: Icons.business_rounded),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    style: colors.cardTitle.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offer.companyName,
                    style: colors.cardDescription.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (offer.location.isNotEmpty) offer.location,
                      if (offer.salary.isNotEmpty) offer.salary,
                      if (offer.contractType.isNotEmpty) offer.contractType,
                    ].join(' · '),
                    style: colors.jobInfo.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({this.bytes, required this.fallbackIcon});

  final Uint8List? bytes;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: OnboardingColors.lavender,
      backgroundImage: bytes != null ? MemoryImage(bytes!) : null,
      child: bytes == null
          ? Icon(fallbackIcon, color: OnboardingColors.violet, size: 20)
          : null,
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.safeAreaHorizontal,
      endIndent: AppSpacing.safeAreaHorizontal,
      color: AppSurfaceColors.of(context).divider,
    );
  }
}

// ===========================================================================
// 1. Candidatures envoyées
// ===========================================================================

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final AuthService _authService = AuthService();
  final JobOfferRepository _repository = const JobOfferRepository();
  List<JobOffer> _offers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _authService.currentUser?.id;
    final offers = userId == null
        ? <JobOffer>[]
        : await _repository.fetchAppliedOffers(userId);
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _StatScaffold(
      title: 'Candidatures envoyées',
      loading: _loading,
      isEmpty: _offers.isEmpty,
      emptyIcon: Icons.send_rounded,
      emptyMessage: "Vous n'avez encore postulé à aucune offre.",
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _offers.length,
        separatorBuilder: (_, _) => const _Separator(),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _OfferTile(
            offer: offer,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobOfferDetailScreen(offer: offer)),
              );
              _load();
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// 2. Entretiens
// ===========================================================================

class MyInterviewsScreen extends StatefulWidget {
  const MyInterviewsScreen({super.key});

  @override
  State<MyInterviewsScreen> createState() => _MyInterviewsScreenState();
}

class _MyInterviewsScreenState extends State<MyInterviewsScreen> {
  final AuthService _authService = AuthService();
  final InterviewRepository _repository = const InterviewRepository();
  List<Interview> _interviews = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _authService.currentUser?.id;
    final interviews = userId == null
        ? <Interview>[]
        : await _repository.fetchNotificationsForJobSeeker(userId);
    if (!mounted) return;
    setState(() {
      _interviews = interviews;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _StatScaffold(
      title: 'Entretiens',
      loading: _loading,
      isEmpty: _interviews.isEmpty,
      emptyIcon: Icons.calendar_today_rounded,
      emptyMessage:
          "Aucun entretien pour le moment. Un recruteur vous en proposera un après votre candidature.",
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _interviews.length,
        separatorBuilder: (_, _) => const _Separator(),
        itemBuilder: (context, index) => _InterviewTile(
          interview: _interviews[index],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CandidateInterviewDetailScreen(interview: _interviews[index]),
              ),
            );
            _load();
          },
        ),
      ),
    );
  }
}

class _InterviewTile extends StatelessWidget {
  const _InterviewTile({required this.interview, required this.onTap});

  final Interview interview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final title = interview.offerTitle.trim().isNotEmpty
        ? interview.offerTitle.trim()
        : 'Entretien';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.safeAreaHorizontal,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: OnboardingColors.violet.withValues(alpha: 0.12),
              child: Icon(
                interview.isVisio ? Icons.videocam_rounded : Icons.event_available_rounded,
                color: OnboardingColors.violet,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: colors.cardTitle.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (interview.isModified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Modifié',
                            style: AppTypography.interSemiBold.copyWith(
                              fontSize: 10,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${interview.dateLabel} · ${interview.time}',
                    style: colors.cardDescription.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    interview.locationLabel,
                    style: colors.jobInfo.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 3. Favoris
// ===========================================================================

class MySavedOffersScreen extends StatefulWidget {
  const MySavedOffersScreen({super.key});

  @override
  State<MySavedOffersScreen> createState() => _MySavedOffersScreenState();
}

class _MySavedOffersScreenState extends State<MySavedOffersScreen> {
  final AuthService _authService = AuthService();
  final JobOfferRepository _repository = const JobOfferRepository();
  List<JobOffer> _offers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _authService.currentUser?.id;
    final offers = userId == null
        ? <JobOffer>[]
        : await _repository.fetchSavedOffers(userId);
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _StatScaffold(
      title: 'Favoris',
      loading: _loading,
      isEmpty: _offers.isEmpty,
      emptyIcon: Icons.favorite_rounded,
      emptyMessage:
          "Aucune offre en favori. Touchez le cœur d'une publication pour l'enregistrer ici.",
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _offers.length,
        separatorBuilder: (_, _) => const _Separator(),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _OfferTile(
            offer: offer,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobOfferDetailScreen(offer: offer)),
              );
              _load();
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// 4. Vues du profil
// ===========================================================================

class ProfileViewersScreen extends StatefulWidget {
  const ProfileViewersScreen({super.key});

  @override
  State<ProfileViewersScreen> createState() => _ProfileViewersScreenState();
}

class _ProfileViewersScreenState extends State<ProfileViewersScreen> {
  final AuthService _authService = AuthService();
  final AccountSearchRepository _repository = const AccountSearchRepository();
  List<ProfileViewer> _viewers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _authService.currentUser?.id;
    final viewers = userId == null
        ? <ProfileViewer>[]
        : await _repository.fetchProfileViewers(userId);
    if (!mounted) return;
    setState(() {
      _viewers = viewers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _StatScaffold(
      title: 'Vues du profil',
      loading: _loading,
      isEmpty: _viewers.isEmpty,
      emptyIcon: Icons.visibility_outlined,
      emptyMessage: "Aucun recruteur n'a encore consulté votre profil.",
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _viewers.length,
        separatorBuilder: (_, _) => const _Separator(),
        itemBuilder: (context, index) => _ViewerTile(viewer: _viewers[index]),
      ),
    );
  }
}

class _ViewerTile extends StatelessWidget {
  const _ViewerTile({required this.viewer});

  final ProfileViewer viewer;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final company = viewer.company;
    final name = company?.companyName ?? 'Une entreprise';
    final subtitleParts = <String>[
      if (company?.contactName != null && company!.contactName!.isNotEmpty)
        company.contactName!,
      if (company?.localisation != null && company!.localisation!.isNotEmpty)
        company.localisation!,
    ];

    return InkWell(
      onTap: company == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyProfileViewScreen(company: company),
                ),
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.safeAreaHorizontal,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _LogoAvatar(bytes: company?.logo, fallbackIcon: Icons.business_rounded),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: colors.cardTitle.copyWith(fontSize: 15),
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
                    'A consulté votre profil ${_relativeLabel(viewer.viewedAt)}',
                    style: colors.jobInfo.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (company != null)
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
