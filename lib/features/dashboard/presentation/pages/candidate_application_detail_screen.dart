import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart' show PortfolioProject;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_search_repository.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import '../widgets/soft_ui.dart';
import 'candidate_full_portfolio_screen.dart';
import 'portfolio_project_detail_screen.dart';
import 'schedule_interview_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Détail d'une candidature reçue — ouvert depuis
/// `EmployerNotificationsScreen` en tapant sur une notification "Nouvelle
/// candidature reçue". Combine ce qui est déjà connu de la candidature
/// (nom/poste dupliqués sur `job_applications`, offre visée) avec le reste
/// du profil du candidat quand il est disponible (`fetchJobSeekerProfileSummary`
/// — `null` pour un compte de démo).
class CandidateApplicationDetailScreen extends StatefulWidget {
  const CandidateApplicationDetailScreen({super.key, required this.notification});

  final JobApplicationNotification notification;

  @override
  State<CandidateApplicationDetailScreen> createState() =>
      _CandidateApplicationDetailScreenState();
}

class _CandidateApplicationDetailScreenState
    extends State<CandidateApplicationDetailScreen> {
  final JobOfferRepository _repository = const JobOfferRepository();
  final InterviewRepository _interviewRepository = const InterviewRepository();
  final AccountSearchRepository _accountSearchRepository = const AccountSearchRepository();

  JobSeekerProfileSummary? _profile;

  /// Profil complet du candidat, portfolio compris (projets, formations,
  /// certifications, liens) — `null` tant que non chargé ou pour un compte
  /// de démo (aucune ligne `users`), voir `fetchJobSeekerById`.
  CandidateSearchResult? _portfolio;
  bool _loadingPortfolio = true;
  Interview? _interview;
  bool _loadingProfile = true;
  bool _loadingCv = false;

  /// Décision courante sur la candidature — initialisée depuis
  /// [notification], puis mise à jour localement par [_confirmReject]/
  /// [_confirmAccept]/[_restore] (les listes appelantes se rechargent au
  /// retour).
  late String _status = notification.status;
  late String? _decisionMessage = notification.decisionMessage;
  late DateTime? _decidedAt = notification.decidedAt;
  bool _updatingStatus = false;

  bool get _isRejected => _status == ApplicationStatus.rejected;
  bool get _isAccepted => _status == ApplicationStatus.accepted;

  static const Color _rejectColor = Color(0xFFDC2626);
  static const Color _acceptColor = Color(0xFF0F8A6E);

  JobApplicationNotification get notification => widget.notification;

  AppSurfaceColors get _colors => AppSurfaceColors.of(context);

  /// Nom complet à afficher : le profil réel du candidat (`job_seeker_profiles`,
  /// toujours à jour) prime sur l'instantané pris à la candidature, lui-même
  /// prioritaire sur un texte générique — nécessaire pour les candidatures
  /// enregistrées avant l'ajout de `candidate_name` (colonne alors vide).
  String get _displayName {
    final profileFullName = _profile?.fullName.trim() ?? '';
    if (profileFullName.isNotEmpty) return profileFullName;
    final storedName = notification.candidateName.trim();
    return storedName.isNotEmpty ? storedName : 'Candidat';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadInterview();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    final candidate =
        await _accountSearchRepository.fetchJobSeekerById(notification.jobSeekerUserId);
    if (!mounted) return;
    setState(() {
      _portfolio = candidate;
      _loadingPortfolio = false;
    });
  }

  void _openFullPortfolio() {
    final candidate = _portfolio;
    if (candidate == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CandidateFullPortfolioScreen(candidate: candidate)),
    );
  }

  Future<void> _loadProfile() async {
    final profile =
        await _repository.fetchJobSeekerProfileSummary(notification.jobSeekerUserId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loadingProfile = false;
    });
  }

  Future<void> _loadInterview() async {
    final interview =
        await _interviewRepository.fetchByApplication(notification.applicationId);
    if (!mounted) return;
    setState(() => _interview = interview);
  }

  /// Ouvre `ScheduleInterviewScreen` — pré-rempli si un entretien est déjà
  /// planifié pour cette candidature (re-planification).
  Future<void> _openScheduleInterview() async {
    final result = await Navigator.push<Interview>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleInterviewScreen(
          notification: notification,
          existing: _interview,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _interview = result);
    }
  }

  /// Demande confirmation (avec un mot facultatif pour le candidat) puis
  /// rejette la candidature. Un entretien déjà planifié pour cette
  /// candidature est supprimé : le candidat ne doit pas recevoir à la fois
  /// une invitation et un refus.
  Future<void> _confirmReject() async {
    final interviewNote = _interview != null ? " L'entretien planifié sera annulé." : '';
    // `null` = annulé ; sinon le message saisi (éventuellement vide).
    final message = await showDialog<String>(
      context: context,
      builder: (_) => _ApplicationDecisionDialog(
        title: 'Rejeter cette candidature ?',
        description: "$_displayName sera informé(e) que sa candidature pour "
            "« ${notification.offer.title} » n'a pas été retenue.$interviewNote",
        messageHint: 'Ex : Nous avons retenu un profil plus expérimenté...',
        confirmLabel: 'Rejeter',
        confirmColor: _rejectColor,
      ),
    );
    if (message == null || !mounted) return;

    setState(() => _updatingStatus = true);
    await _repository.rejectApplication(notification.applicationId, message: message);
    final interview = _interview;
    if (interview != null) await _interviewRepository.delete(interview.id);
    if (!mounted) return;
    _applyDecision(ApplicationStatus.rejected, message);
    setState(() => _interview = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Candidature rejetée. Le candidat a été informé.')),
    );
  }

  /// Accepter oblige à proposer un entretien (dont la date peut rester "à
  /// définir"), pour que le candidat accepté sache quelle est la suite :
  /// ouvre `ScheduleInterviewScreen` en mode acceptation (pré-rempli si un
  /// entretien existe déjà). C'est cet écran qui enregistre l'entretien puis
  /// accepte la candidature ; revenir sans enregistrer n'accepte rien.
  Future<void> _confirmAccept() async {
    final interview = await Navigator.push<Interview>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleInterviewScreen(
          notification: notification,
          existing: _interview,
          acceptApplication: true,
        ),
      ),
    );
    if (interview == null || !mounted) return;

    // Relit la décision enregistrée (dont le message saisi sur l'écran).
    final status =
        await _repository.fetchApplicationStatus(notification.offer.id, notification.jobSeekerUserId);
    if (!mounted) return;
    setState(() => _interview = interview);
    _applyDecision(status?.status ?? ApplicationStatus.accepted, status?.decisionMessage ?? '');
  }

  void _applyDecision(String status, String message) {
    setState(() {
      _status = status;
      _decisionMessage = message.isEmpty ? null : message;
      _decidedAt = DateTime.now();
      _updatingStatus = false;
    });
  }

  /// Annule une décision prise par erreur (acceptation ou rejet) — la
  /// candidature repasse en attente et la notification disparaît côté
  /// candidat.
  Future<void> _restore() async {
    setState(() => _updatingStatus = true);
    await _repository.restoreApplication(notification.applicationId);
    if (!mounted) return;
    setState(() {
      _status = ApplicationStatus.pending;
      _decisionMessage = null;
      _decidedAt = null;
      _updatingStatus = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Décision annulée : la candidature est de nouveau en attente.')),
    );
  }

  /// Lance l'appel du candidat via l'application téléphone du système
  /// (`tel:`). Les espaces/points/parenthèses sont retirés — un `tel:` ne
  /// doit contenir que chiffres, `+`, `*`, `#`. Si aucune application ne
  /// peut composer un numéro (bureau, navigateur sans téléphonie...), on
  /// affiche le numéro dans une boîte de dialogue avec un bouton "Copier".
  Future<void> _callCandidate(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+*#]'), '');
    final launched = await _tryLaunch(Uri.parse('tel:$cleaned'));
    if (!launched && mounted) {
      _showFallbackDialog(
        title: 'Appeler le candidat',
        value: phone,
        actionLabel: 'Copier le numéro',
      );
    }
  }

  /// Ouvre le client mail du système sur un nouveau message adressé au
  /// candidat (`mailto:`). Même repli que [_callCandidate].
  Future<void> _emailCandidate(String email) async {
    final launched = await _tryLaunch(Uri(scheme: 'mailto', path: email));
    if (!launched && mounted) {
      _showFallbackDialog(
        title: 'Écrire au candidat',
        value: email,
        actionLabel: 'Copier l\'adresse',
      );
    }
  }

  /// Essaie d'ouvrir [uri] avec l'app externe, puis en mode plateforme par
  /// défaut si le premier échoue — renvoie `true` dès qu'un lancement
  /// réussit. Certaines plateformes (web notamment) ignorent `externalApplication`.
  Future<bool> _tryLaunch(Uri uri) async {
    for (final mode in const [LaunchMode.externalApplication, LaunchMode.platformDefault]) {
      try {
        if (await launchUrl(uri, mode: mode)) return true;
      } catch (error, stackTrace) {
        debugPrint('launchUrl($uri, $mode) a échoué : $error\n$stackTrace');
      }
    }
    return false;
  }

  void _showFallbackDialog({
    required String title,
    required String value,
    required String actionLabel,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SelectableText(value),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copié dans le presse-papiers.')),
                );
              }
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  /// Charge le CV réel à la demande (`JobOfferRepository.fetchJobSeekerCv`,
  /// isolé du reste du profil) puis l'ouvre : aperçu plein écran pour une
  /// image, message informatif pour un PDF (pas de lecteur PDF intégré à
  /// l'app pour l'instant).
  Future<void> _viewCv() async {
    if (_loadingCv) return;
    setState(() => _loadingCv = true);

    try {
      final cv = await _repository.fetchJobSeekerCv(notification.jobSeekerUserId);

      if (cv == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV introuvable.')),
        );
        return;
      }

      if (cv.isImage) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _CvImageViewerScreen(cv: cv),
            fullscreenDialog: true,
          ),
        );
        return;
      }

      await _openPdfWithNativeApp(cv);
    } catch (error, stackTrace) {
      debugPrint('CandidateApplicationDetailScreen._viewCv failed: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir le CV : $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingCv = false);
    }
  }

  /// Écrit le PDF dans le cache temporaire de l'app puis l'ouvre via
  /// l'intent Android standard (`ACTION_VIEW`) — le système propose alors
  /// le choix entre les applications du téléphone capables d'afficher un
  /// PDF (ou l'ouvre directement si l'utilisateur en a déjà défini une par
  /// défaut). Écrit à chaque fois sous le même nom : un appui répété
  /// remplace simplement le fichier temporaire précédent.
  Future<void> _openPdfWithNativeApp(JobSeekerCvFile cv) async {
    final directory = await getTemporaryDirectory();
    final safeName = cv.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final file = File('${directory.path}/$safeName');
    await file.writeAsBytes(cv.bytes, flush: true);

    final result = await OpenFile.open(file.path, type: 'application/pdf');
    debugPrint('OpenFile.open result: ${result.type} ${result.message}');
    if (!mounted || result.type == ResultType.done) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.type == ResultType.noAppToOpen
              ? "Aucune application installée ne peut ouvrir un PDF sur cet appareil."
              : "Impossible d'ouvrir le CV : ${result.message}",
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = notification.offer;
    final phone = _profile?.telephone?.trim();
    final location = _profile?.localisation?.trim();
    final email = _profile?.email?.trim();
    final about = _profile?.presentation?.trim();
    final skills = _profile?.skills ?? const [];
    final hasContactInfo = (phone != null && phone.isNotEmpty) ||
        (location != null && location.isNotEmpty) ||
        (email != null && email.isNotEmpty);

    return Scaffold(
      backgroundColor: SoftUi.pageBackground(_colors),
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
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _colors.textPrimary,
                    ),
                  ),
                  const Expanded(child: SerifSectionTitle('Candidature reçue')),
                ],
              ),
            ),
            Expanded(
              child: _loadingProfile
                  ? Center(child: CircularProgressIndicator(color: SoftUi.brandInk(_colors)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.safeAreaHorizontal,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: staggered([
                          SoftCard(
                            padding: const EdgeInsets.all(18),
                            radius: 28,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCandidateHeader(),
                                if (hasContactInfo) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      if (phone != null && phone.isNotEmpty)
                                        _buildInfoChip(
                                          Icons.phone_outlined,
                                          phone,
                                          onTap: () => _callCandidate(phone),
                                        ),
                                      if (location != null && location.isNotEmpty)
                                        _buildInfoChip(Icons.location_on_outlined, location),
                                      if (email != null && email.isNotEmpty)
                                        _buildInfoChip(
                                          Icons.email_outlined,
                                          email,
                                          onTap: () => _emailCandidate(email),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (about != null && about.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            SoftSection(
                              title: 'À propos',
                              child: Text(
                                about,
                                style: AppTypography.interRegular.copyWith(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: _colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          if (skills.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            SoftSection(
                              title: 'Compétences',
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: skills
                                    .map((skill) => SoftDotBadge(
                                          label: skill,
                                          color: DashboardColors.accent,
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _buildPortfolioSection(),
                          if (_profile?.cvFileName != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            SoftSection(
                              title: 'CV',
                              child: _buildCvRow(_profile!.cvFileName!),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          SoftSection(
                            title: 'Offre concernée',
                            child: _buildOfferSummary(offer),
                          ),
                          SmoothSwitcher(
                            child: (_isRejected || _isAccepted)
                                ? Padding(
                                    key: ValueKey(_status),
                                    padding: const EdgeInsets.only(top: AppSpacing.md),
                                    child: _buildDecisionSummary(),
                                  )
                                : null,
                          ),
                          if (_interview != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            SoftSection(
                              title: 'Entretien planifié',
                              child: _buildInterviewSummary(_interview!),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                        ]),
                      ),
                    ),
            ),
            if (!_loadingProfile) _buildScheduleBar(),
          ],
        ),
      ),
    );
  }

  /// Portfolio du candidat : chiffres clés, aperçu des projets (tap =
  /// détail du projet) et accès au portfolio complet — le même que celui
  /// que le recruteur voit depuis la recherche de candidats.
  Widget _buildPortfolioSection() {
    Widget content;
    VoidCallback? onSeeAll;

    if (_loadingPortfolio) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(color: SoftUi.brandInk(_colors)),
        ),
      );
    } else if (_portfolio == null) {
      content = const SoftEmptyState(
        icon: Icons.collections_bookmark_outlined,
        text: 'Portfolio indisponible pour ce compte (compte de démonstration).',
      );
    } else {
      final candidate = _portfolio!;
      final projects = candidate.portfolioProjects;
      final isEmpty = projects.isEmpty &&
          candidate.experiences.isEmpty &&
          candidate.formations.isEmpty &&
          candidate.certifications.isEmpty &&
          candidate.professionalLinks.isEmpty &&
          candidate.skills.isEmpty &&
          (candidate.presentation ?? '').trim().isEmpty;
      onSeeAll = _openFullPortfolio;

      if (isEmpty) {
        content = const SoftEmptyState(
          icon: Icons.collections_bookmark_outlined,
          text: "Ce candidat n'a pas encore rempli son portfolio.",
        );
      } else {
        String plural(int n, String word) => '$n $word${n > 1 ? 's' : ''}';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                SoftDotBadge(label: plural(projects.length, 'projet'), color: DashboardColors.accentStrong),
                SoftDotBadge(label: plural(candidate.experiences.length, 'expérience'), color: const Color(0xFF0F8A6E)),
                SoftDotBadge(label: plural(candidate.formations.length, 'formation'), color: const Color(0xFFC2780E)),
                SoftDotBadge(label: plural(candidate.certifications.length, 'certification'), color: const Color(0xFFD1366E)),
              ],
            ),
            if (projects.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              for (final project in projects.take(3)) ...[
                _buildProjectRow(project),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (projects.length > 3)
                Text(
                  '+ ${projects.length - 3} autre${projects.length - 3 > 1 ? 's' : ''} projet${projects.length - 3 > 1 ? 's' : ''}',
                  style: AppTypography.interRegular.copyWith(fontSize: 12.5, color: _colors.textTertiary),
                ),
            ],
          ],
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      child: SoftSection(
        title: 'Portfolio',
        trailing: onSeeAll == null
            ? null
            : SoftPillButton(
                label: 'Voir tout',
                icon: Icons.arrow_forward_rounded,
                compact: true,
                onPressed: onSeeAll,
              ),
        child: content,
      ),
    );
  }

  Widget _buildProjectRow(PortfolioProject project) {
    final description = (project.description ?? '').trim();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PortfolioProjectDetailScreen(project: project)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: project.imageBytes != null
                ? Image.memory(project.imageBytes!, width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52,
                    height: 52,
                    color: SoftUi.tint(_colors, DashboardColors.accent),
                    child: Icon(
                      Icons.collections_bookmark_rounded,
                      color: SoftUi.brandInk(_colors),
                      size: 22,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: AppTypography.interSemiBold.copyWith(fontSize: 14, color: _colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.interRegular.copyWith(fontSize: 12.5, color: _colors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: _colors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildScheduleBar() {
    final hasInterview = _interview != null;
    final scheduleButton = SoftPrimaryButton(
      label: hasInterview ? "Modifier l'entretien" : 'Planifier un entretien',
      icon: hasInterview ? Icons.edit_calendar_rounded : Icons.event_available_rounded,
      onPressed: _updatingStatus ? null : _openScheduleInterview,
    );
    final Widget content;
    if (_isRejected) {
      // Rejetée : plus d'entretien possible, seulement revenir en arrière.
      content = SoftPrimaryButton(
        label: 'Annuler le rejet',
        icon: Icons.undo_rounded,
        loading: _updatingStatus,
        onPressed: _updatingStatus ? null : _restore,
      );
    } else if (_isAccepted) {
      content = Row(
        children: [
          Expanded(
            flex: 2,
            child: SoftPrimaryButton(
              label: 'Annuler',
              icon: Icons.undo_rounded,
              color: const Color(0xFF64748B),
              loading: _updatingStatus,
              onPressed: _updatingStatus ? null : _restore,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 3, child: scheduleButton),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SoftPrimaryButton(
                  label: 'Rejeter',
                  icon: Icons.close_rounded,
                  color: _rejectColor,
                  loading: _updatingStatus,
                  onPressed: _updatingStatus ? null : _confirmReject,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SoftPrimaryButton(
                  label: 'Accepter',
                  icon: Icons.check_rounded,
                  color: _acceptColor,
                  loading: _updatingStatus,
                  onPressed: _updatingStatus ? null : _confirmAccept,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          scheduleButton,
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.safeAreaHorizontal,
        AppSpacing.md,
        AppSpacing.safeAreaHorizontal,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: SoftUi.pageBackground(_colors),
        border: Border(top: BorderSide(color: _colors.divider)),
      ),
      child: SmoothSwitcher(
        alignment: Alignment.bottomCenter,
        child: KeyedSubtree(key: ValueKey('$_status-$hasInterview'), child: content),
      ),
    );
  }

  /// Encadré teinté "Candidature acceptée/rejetée le …" : date de la
  /// décision et message laissé au candidat, le cas échéant.
  Widget _buildDecisionSummary() {
    final decidedAt = _decidedAt;
    final message = _decisionMessage?.trim() ?? '';
    final color = _isAccepted ? _acceptColor : _rejectColor;
    final verb = _isAccepted ? 'acceptée' : 'rejetée';
    final ink = SoftUi.accentInk(_colors, color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftUi.tint(_colors, color),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isAccepted ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                size: 18,
                color: ink,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  decidedAt != null
                      ? 'Candidature $verb le ${decidedAt.day.toString().padLeft(2, '0')}/'
                          '${decidedAt.month.toString().padLeft(2, '0')}/${decidedAt.year}'
                      : 'Candidature $verb',
                  style: AppTypography.interSemiBold.copyWith(fontSize: 14, color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.isNotEmpty
                ? 'Message envoyé au candidat : « $message »'
                : 'Le candidat a été informé, sans message.',
            style: AppTypography.interRegular.copyWith(
              fontSize: 13,
              height: 1.4,
              color: _colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewSummary(Interview interview) {
    const amber = Color(0xFFC2780E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _buildInfoChip(Icons.calendar_today_rounded, interview.dateLabel, accent: amber),
            if (!interview.isDateToBeDefined)
              _buildInfoChip(Icons.access_time_rounded, interview.timeLabel, accent: amber),
            _buildInfoChip(
              interview.isVisio ? Icons.videocam_outlined : Icons.location_on_outlined,
              interview.locationLabel,
              accent: amber,
            ),
          ],
        ),
        if ((interview.notes ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            interview.notes!.trim(),
            style: AppTypography.interRegular.copyWith(fontSize: 13, color: _colors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildCandidateHeader() {
    final photo = _profile?.photo;
    final position = notification.candidatePosition?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SoftAvatar(
          name: _displayName,
          size: 60,
          photo: photo != null ? MemoryImage(photo) : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: AppTypography.frauncesBold.copyWith(
                  fontSize: 21,
                  color: _colors.textPrimary,
                  height: 1.15,
                ),
              ),
              if (position != null && position.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(position, style: _colors.companyName),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  SoftDotBadge(
                    label: 'A postulé ${notification.timeLabel.toLowerCase()}',
                    color: const Color(0xFF0F8A6E),
                  ),
                  if (_isRejected) const SoftDotBadge(label: 'Rejetée', color: _rejectColor),
                  if (_isAccepted) const SoftDotBadge(label: 'Acceptée', color: _acceptColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferSummary(JobOffer offer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          offer.title,
          style: AppTypography.interSemiBold.copyWith(fontSize: 15, color: _colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (offer.location.isNotEmpty)
              _buildInfoChip(Icons.location_on_outlined, offer.location),
            if (offer.salary.isNotEmpty)
              _buildInfoChip(Icons.attach_money_rounded, offer.salary),
            if (offer.contractType.isNotEmpty)
              _buildInfoChip(Icons.work_outline_rounded, offer.contractType),
          ],
        ),
      ],
    );
  }

  Widget _buildCvRow(String fileName) {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SoftUi.tint(_colors, DashboardColors.accent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            color: SoftUi.brandInk(_colors),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            fileName,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.interMedium.copyWith(fontSize: 13, color: _colors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _loadingCv
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: SoftUi.brandInk(_colors)),
                ),
              )
            : SoftPillButton(
                label: 'Voir',
                icon: Icons.arrow_forward_rounded,
                compact: true,
                onPressed: _viewCv,
              ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {VoidCallback? onTap, Color? accent}) {
    if (label.isEmpty) return const SizedBox.shrink();
    final tappable = onTap != null;
    final chipAccent = accent ?? DashboardColors.accent;
    final ink = accent == null ? SoftUi.brandInk(_colors) : SoftUi.accentInk(_colors, chipAccent);

    // Borne la largeur pour qu'un long libellé (email surtout) tronque avec
    // "…" au lieu de déborder de l'écran dans le `Wrap`.
    final maxTextWidth = MediaQuery.of(context).size.width -
        AppSpacing.safeAreaHorizontal * 2 -
        (tappable ? 110 : 92);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ink),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTextWidth < 60 ? 60 : maxTextWidth),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.interMedium.copyWith(
              fontSize: 12.5,
              color: _colors.textPrimary,
            ),
          ),
        ),
        // Petit indice d'action (l'aspect de la puce, lui, ne change pas).
        if (tappable) ...[
          const SizedBox(width: 4),
          Icon(
            icon == Icons.phone_outlined ? Icons.call_rounded : Icons.open_in_new_rounded,
            size: 13,
            color: ink,
          ),
        ],
      ],
    );

    final decoration = BoxDecoration(
      color: SoftUi.tint(_colors, chipAccent),
      borderRadius: BorderRadius.circular(999),
    );
    const chipPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    );

    if (!tappable) {
      return Container(padding: chipPadding, decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: decoration,
          child: Padding(padding: chipPadding, child: content),
        ),
      ),
    );
  }
}

/// Confirmation d'une décision (acceptation ou rejet), avec un message
/// facultatif au candidat. Possède son propre `TextEditingController`,
/// libéré dans [State.dispose] une fois le dialogue réellement retiré de
/// l'arbre : le libérer depuis l'appelant juste après `showDialog` le
/// détruisait pendant l'animation de fermeture, alors que le `TextField`
/// l'utilisait encore (assertion `'_dependents.isEmpty'`). Renvoie le
/// message saisi (`''` si vide) via `Navigator.pop`, ou `null` si le
/// recruteur annule.
class _ApplicationDecisionDialog extends StatefulWidget {
  const _ApplicationDecisionDialog({
    required this.title,
    required this.description,
    required this.messageHint,
    required this.confirmLabel,
    required this.confirmColor,
  });

  final String title;
  final String description;
  final String messageHint;
  final String confirmLabel;
  final Color confirmColor;

  @override
  State<_ApplicationDecisionDialog> createState() => _ApplicationDecisionDialogState();
}

class _ApplicationDecisionDialogState extends State<_ApplicationDecisionDialog> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _messageController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Message au candidat (facultatif)',
                hintText: widget.messageHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _messageController.text.trim()),
          child: Text(widget.confirmLabel, style: TextStyle(color: widget.confirmColor)),
        ),
      ],
    );
  }
}

/// Plein écran, fond noir, façon visionneuse — affiche le CV du candidat
/// quand c'est une image (zoomable), avec un bouton de fermeture en haut
/// à gauche. Même identité visuelle que la visionneuse de photo de profil
/// (`JobProfileScreen._ProfilePhotoViewerScreen`).
class _CvImageViewerScreen extends StatelessWidget {
  const _CvImageViewerScreen({required this.cv});

  final JobSeekerCvFile cv;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(cv.bytes),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
