import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Carte "Recommandées pour vous" façon publication de réseau social (voir
/// `pub2.png`) : compte recruteur + heure de publication en en-tête, menu
/// "..." (Enregistrer publication) et "X" (masquer cette offre de son
/// propre fil, `JobOfferRepository.deleteNotification` sous le capot),
/// description dépliable ("Voir plus"/"Voir moins"), affiche optionnelle,
/// puis le bouton "Postuler" existant — tout est réellement persisté, rien
/// n'est simulé ici.
class JobOfferPostCard extends StatefulWidget {
  const JobOfferPostCard({
    super.key,
    required this.companyName,
    this.companyLogo,
    required this.publishedLabel,
    required this.jobTitle,
    required this.location,
    required this.salary,
    required this.contractType,
    required this.description,
    this.posterImage,
    required this.isSaved,
    required this.hasApplied,
    required this.onToggleSave,
    required this.onDismiss,
    required this.onApply,
    required this.onWithdraw,
    this.onTap,
  });

  final String companyName;
  final Uint8List? companyLogo;
  final String publishedLabel;
  final String jobTitle;
  final String location;
  final String salary;
  final String contractType;
  final String description;

  /// Affiche jointe par le recruteur à la publication — `null` si aucune.
  final Uint8List? posterImage;

  /// `true` si le candidat connecté a déjà enregistré cette publication
  /// (`job_offer_saves`) — bascule le libellé du menu "...".
  final bool isSaved;

  /// `true` si le candidat connecté a déjà postulé — le bouton devient
  /// "Candidature envoyée", désactivé (même logique que `JobCard`).
  final bool hasApplied;

  final VoidCallback onToggleSave;

  /// Masque cette offre du fil du candidat connecté — n'affecte pas les
  /// autres candidats ni "Mes offres" côté recruteur.
  final VoidCallback onDismiss;

  final VoidCallback onApply;

  /// Annule une candidature déjà envoyée — appelé après confirmation
  /// (bouton "Candidature envoyée" tapé une seconde fois), pour rattraper
  /// un "Postuler" cliqué par erreur.
  final VoidCallback onWithdraw;

  /// Ouvre le détail complet de l'offre — `null` désactive l'interaction.
  final VoidCallback? onTap;

  @override
  State<JobOfferPostCard> createState() => _JobOfferPostCardState();
}

class _JobOfferPostCardState extends State<JobOfferPostCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.jobTitle,
              style: AppTypography.jobTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow(),
            const SizedBox(height: AppSpacing.md),
            _ExpandableDescription(text: widget.description),
            if (widget.posterImage != null) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  widget.posterImage!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: OnboardingColors.violet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            image: widget.companyLogo != null
                ? DecorationImage(
                    image: MemoryImage(widget.companyLogo!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.companyLogo == null
              ? const Icon(
                  Icons.business_rounded,
                  color: OnboardingColors.violet,
                  size: 22,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.companyName,
                style: AppTypography.companyName.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    widget.publishedLabel,
                    style: AppTypography.jobInfo.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.public_rounded, size: 11, color: Color(0xFF9CA3AF)),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF9CA3AF)),
          onSelected: (_) => widget.onToggleSave(),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'save',
              child: Row(
                children: [
                  Icon(
                    widget.isSaved ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
                    size: 18,
                    color: OnboardingColors.violet,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.isSaved ? 'Retirer des enregistrements' : 'Enregistrer publication',
                  ),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: widget.onDismiss,
          icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        if (widget.location.isNotEmpty) _buildInfoItem(Icons.location_on_outlined, widget.location),
        if (widget.salary.isNotEmpty) _buildInfoItem(Icons.attach_money_rounded, widget.salary),
        if (widget.contractType.isNotEmpty)
          _buildInfoItem(Icons.work_outline_rounded, widget.contractType),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.jobInfo),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.hasApplied ? () => _confirmWithdraw(context) : widget.onApply,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.hasApplied ? const Color(0xFFE5E7EB) : OnboardingColors.violet,
          foregroundColor: widget.hasApplied ? const Color(0xFF6B7280) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.hasApplied) ...[
              const Icon(Icons.check_circle_rounded, size: 18),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              widget.hasApplied ? 'Candidature envoyée' : 'Postuler',
              style: AppTypography.primaryButton.copyWith(
                fontSize: 14,
                color: widget.hasApplied ? const Color(0xFF6B7280) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler la candidature ?'),
        content: Text(
          'Votre candidature pour "${widget.jobTitle}" sera retirée. '
          'Vous pourrez postuler à nouveau plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Annuler la candidature',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onWithdraw();
  }
}

/// Description tronquée à 3 lignes avec un lien "Voir plus"/"Voir moins" —
/// le lien n'apparaît que si le texte dépasse réellement 3 lignes
/// (`TextPainter.didExceedMaxLines`), pas une simple coupure par longueur.
class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});

  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.cardDescription;
    final text = widget.text.isNotEmpty
        ? widget.text
        : 'Aucune description fournie pour cette offre.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? 'Voir moins' : 'Voir plus',
                    style: const TextStyle(
                      color: OnboardingColors.violet,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}