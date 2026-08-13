import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/welcome/presentation/welcome_palette.dart';
import '../../data/job_offer_repository.dart';

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

  JobSeekerProfileSummary? _profile;
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
    final about = _profile?.presentation?.trim();
    final skills = _profile?.skills ?? const [];

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
                          if (phone != null && phone.isNotEmpty ||
                              location != null && location.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                if (phone != null && phone.isNotEmpty)
                                  _buildInfoChip(Icons.phone_outlined, phone),
                                if (location != null && location.isNotEmpty)
                                  _buildInfoChip(Icons.location_on_outlined, location),
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
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
            ),
          ],
        ),
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

  Widget _buildInfoChip(IconData icon, String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OnboardingColors.violet.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: OnboardingColors.violet),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.jobInfo.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
