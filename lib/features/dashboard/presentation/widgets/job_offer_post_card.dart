import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Carte "Recommandées pour vous" façon publication de réseau social (voir
/// `pub2.png`) : compte recruteur + heure de publication en en-tête, cœur
/// "favori" (vide/gris → plein/rouge, `job_offer_saves` via `onToggleSave`)
/// et "X" (masquer cette offre de son propre fil,
/// `JobOfferRepository.deleteNotification` sous le capot), description
/// dépliable ("Voir plus"/"Voir moins"), affiche optionnelle, puis le
/// bouton "Postuler" existant — tout est réellement persisté, rien n'est
/// simulé ici.
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
  /// Rouge du cœur "favori" une fois l'offre enregistrée.
  static const Color _favoriteColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return InkWell(
      onTap: widget.onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.jobTitle,
              style: colors.jobTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow(colors),
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
            _buildApplyButton(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppSurfaceColors colors) {
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
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    widget.publishedLabel,
                    style: colors.jobInfo.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.public_rounded, size: 11, color: colors.textTertiary),
                ],
              ),
            ],
          ),
        ),
        // Cœur "favori" : vide/gris tant que l'offre n'est pas enregistrée,
        // plein et rouge dès qu'elle l'est (`job_offer_saves` via
        // `onToggleSave`). Remplace l'ancien menu "..." qui ne servait qu'à
        // ça.
        IconButton(
          onPressed: widget.onToggleSave,
          icon: Icon(
            widget.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: widget.isSaved ? _favoriteColor : colors.textTertiary,
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: widget.isSaved ? 'Retirer des favoris' : 'Ajouter aux favoris',
        ),
        IconButton(
          onPressed: widget.onDismiss,
          icon: Icon(Icons.close_rounded, color: colors.textTertiary, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildInfoRow(AppSurfaceColors colors) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        if (widget.location.isNotEmpty)
          _buildInfoItem(colors, Icons.location_on_outlined, widget.location),
        if (widget.salary.isNotEmpty)
          _buildInfoItem(colors, Icons.attach_money_rounded, widget.salary),
        if (widget.contractType.isNotEmpty)
          _buildInfoItem(colors, Icons.work_outline_rounded, widget.contractType),
      ],
    );
  }

  Widget _buildInfoItem(AppSurfaceColors colors, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: colors.jobInfo),
      ],
    );
  }

  Widget _buildApplyButton(AppSurfaceColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.hasApplied ? () => _confirmWithdraw(context) : widget.onApply,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.hasApplied ? colors.divider : OnboardingColors.violet,
          foregroundColor: widget.hasApplied ? colors.textSecondary : Colors.white,
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
                color: widget.hasApplied ? colors.textSecondary : Colors.white,
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
    final style = AppSurfaceColors.of(context).cardDescription;
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