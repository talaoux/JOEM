import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';

import 'soft_ui.dart';

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
    this.otherSector,
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

  /// Secteur précisé par le recruteur pour une offre rangée dans "Autres"
  /// (`JobOffer.otherSector`) — affiché en puce, `null` sinon.
  final String? otherSector;
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
    return SoftCard(
      onTap: widget.onTap,
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.jobTitle,
            style: AppTypography.frauncesBold.copyWith(
              fontSize: 19,
              color: colors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(colors),
          const SizedBox(height: AppSpacing.md),
          _ExpandableDescription(text: widget.description),
          if (widget.posterImage != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
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
    );
  }

  Widget _buildHeader(AppSurfaceColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftAvatar(
          name: widget.companyName,
          size: 44,
          icon: Icons.business_rounded,
          photo: widget.companyLogo != null ? MemoryImage(widget.companyLogo!) : null,
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
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              child: child,
            ),
            child: Icon(
              widget.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(widget.isSaved),
              color: widget.isSaved ? _favoriteColor : colors.textTertiary,
              size: 22,
            ),
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
      spacing: 6,
      runSpacing: 6,
      children: [
        if (widget.location.isNotEmpty)
          _buildInfoItem(colors, Icons.location_on_outlined, widget.location),
        if (widget.salary.isNotEmpty)
          _buildInfoItem(colors, Icons.attach_money_rounded, widget.salary),
        if (widget.contractType.isNotEmpty)
          _buildInfoItem(colors, Icons.work_outline_rounded, widget.contractType),
        if ((widget.otherSector ?? '').trim().isNotEmpty)
          _buildInfoItem(colors, Icons.category_outlined, widget.otherSector!.trim()),
      ],
    );
  }

  /// Puce pâle neutre (lieu, salaire, contrat).
  Widget _buildInfoItem(AppSurfaceColors colors, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SoftUi.tint(colors, DashboardColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SoftUi.brandInk(colors)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.interMedium.copyWith(fontSize: 12, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  /// "Postuler" : pilule à teinte pâle violette (jamais en violet plein) ;
  /// une fois postulé, pilule verte "Candidature envoyée" (tap = annuler).
  Widget _buildApplyButton(AppSurfaceColors colors) {
    if (!widget.hasApplied) {
      return SoftPrimaryButton(
        label: 'Postuler',
        icon: Icons.send_rounded,
        onPressed: widget.onApply,
      );
    }
    return SoftPrimaryButton(
      label: 'Candidature envoyée',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF0F8A6E),
      onPressed: () => _confirmWithdraw(context),
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
                    style: AppTypography.interSemiBold.copyWith(
                      color: SoftUi.brandInk(AppSurfaceColors.of(context)),
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