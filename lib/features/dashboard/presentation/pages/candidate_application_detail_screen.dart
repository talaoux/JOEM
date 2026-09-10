import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/interview_repository.dart';
import '../../data/job_offer_repository.dart';
import 'schedule_interview_screen.dart';

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

  JobSeekerProfileSummary? _profile;
  Interview? _interview;
  bool _loadingProfile = true;
  bool _loadingCv = false;

  JobApplicationNotification get notification => widget.notification;

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
      backgroundColor: AppColors.background,
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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Candidature reçue',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingProfile
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.safeAreaHorizontal,
                      ),
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
                          if (about != null && about.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text('À propos', style: AppTypography.cardTitle),
                            const SizedBox(height: AppSpacing.sm),
                            Text(about, style: AppTypography.cardDescription),
                          ],
                          if (skills.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text('Compétences', style: AppTypography.cardTitle),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: skills
                                  .map((skill) => _buildInfoChip(Icons.star_outline_rounded, skill))
                                  .toList(),
                            ),
                          ],
                          if (_profile?.cvFileName != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text('CV', style: AppTypography.cardTitle),
                            const SizedBox(height: AppSpacing.sm),
                            _buildCvRow(_profile!.cvFileName!),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Offre concernée', style: AppTypography.cardTitle),
                          const SizedBox(height: AppSpacing.sm),
                          _buildOfferSummary(offer),
                          if (_interview != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text('Entretien planifié', style: AppTypography.cardTitle),
                            const SizedBox(height: AppSpacing.sm),
                            _buildInterviewSummary(_interview!),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
            ),
            if (!_loadingProfile) _buildScheduleBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleBar() {
    final hasInterview = _interview != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.safeAreaHorizontal,
        AppSpacing.md,
        AppSpacing.safeAreaHorizontal,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openScheduleInterview,
          icon: Icon(hasInterview ? Icons.edit_calendar_rounded : Icons.event_available_rounded, size: 18),
          label: Text(
            hasInterview ? 'Modifier l\'entretien' : 'Planifier un entretien',
            style: AppTypography.primaryButton.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: OnboardingColors.violet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewSummary(Interview interview) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildInfoChip(Icons.calendar_today_rounded, interview.dateLabel),
              _buildInfoChip(Icons.access_time_rounded, interview.time),
              _buildInfoChip(
                interview.isVisio ? Icons.videocam_outlined : Icons.location_on_outlined,
                interview.locationLabel,
              ),
            ],
          ),
          if ((interview.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(interview.notes!.trim(), style: AppTypography.cardDescription),
          ],
        ],
      ),
    );
  }

  Widget _buildCandidateHeader() {
    final photo = _profile?.photo;
    final position = notification.candidatePosition?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: OnboardingColors.violet.withOpacity(0.1),
            shape: BoxShape.circle,
            image: photo != null
                ? DecorationImage(image: MemoryImage(photo), fit: BoxFit.cover)
                : null,
          ),
          child: photo == null
              ? const Icon(
                  Icons.person_rounded,
                  color: OnboardingColors.violet,
                  size: 28,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_displayName, style: AppTypography.dashboardSubtitle),
              if (position != null && position.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(position, style: AppTypography.companyName),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'A postulé ${notification.timeLabel.toLowerCase()}',
                    style: AppTypography.jobInfo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferSummary(JobOffer offer) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer.title, style: AppTypography.dashboardSubtitle),
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
      ),
    );
  }

  Widget _buildCvRow(String fileName) {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            color: OnboardingColors.violet,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.jobInfo.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadingCv ? null : _viewCv,
            child: _loadingCv
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Voir', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {VoidCallback? onTap}) {
    if (label.isEmpty) return const SizedBox.shrink();
    final tappable = onTap != null;

    // Borne la largeur pour qu'un long libellé (email surtout) tronque avec
    // "…" au lieu de déborder de l'écran dans le `Wrap`.
    final maxTextWidth = MediaQuery.of(context).size.width -
        AppSpacing.safeAreaHorizontal * 2 -
        (tappable ? 74 : 56);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: OnboardingColors.violet),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTextWidth < 60 ? 60 : maxTextWidth),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.jobInfo.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Petit indice d'action (l'aspect de la puce, lui, ne change pas).
        if (tappable) ...[
          const SizedBox(width: 4),
          Icon(
            icon == Icons.phone_outlined ? Icons.call_rounded : Icons.open_in_new_rounded,
            size: 13,
            color: OnboardingColors.violet,
          ),
        ],
      ],
    );

    final decoration = BoxDecoration(
      color: OnboardingColors.violet.withOpacity(0.08),
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
