import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Palette "bleu océan" des espaces candidat et recruteur — mêmes valeurs
/// que le thème "Bleu océan" du Portfolio (`PortfolioHeroTheme.ocean`).
/// Remplace le violet de l'onboarding (`OnboardingColors`), qui reste celui
/// de l'accueil, de la connexion et des wizards d'inscription.
class DashboardColors {
  DashboardColors._();

  /// Accent principal (icônes, bordures actives, barres de progression).
  static const Color accent = Color(0xFF3B82F6);

  /// Bleu plus soutenu — chiffre/point "offres" et "vues" de la palette de
  /// sens (ancien violet `0xFF6D28D9`).
  static const Color accentStrong = Color(0xFF2563EB);

  /// Texte des éléments teintés (pilules, badges) en mode clair.
  static const Color ink = Color(0xFF1D4ED8);

  /// Bleu nuit (ancien `OnboardingColors.accentDeep`).
  static const Color accentDeep = Color(0xFF1E3A8A);

  /// Bleu clair (ancien `OnboardingColors.accentLight`).
  static const Color accentLight = Color(0xFF60A5FA);

  /// Teinte très pâle (ancien `OnboardingColors.tint`).
  static const Color tint = Color(0xFFDBEAFE);

  /// Fond de page (ancien lavande `0xFFF8F5FE`).
  static const Color page = Color(0xFFF4F7FD);

  /// Fond neutre des options non choisies d'un sélecteur segmenté.
  static const Color segment = Color(0xFFEEF2F8);
}

/// Petit kit de composants du "nouveau design" (maquette
/// `nouveau_design.jpeg`) appliqué à l'accueil recruteur : fond de page
/// teinté, cartes blanches à fine bordure, titres serif, boutons pilules à
/// teinte pâle plutôt qu'en couleur pleine, badges "point + texte".
class SoftUi {
  SoftUi._();

  /// `true` en mode nuit — déduit de la luminance de la surface plutôt que
  /// de `Theme.brightness` (toujours `dark` dans `main.dart`).
  static bool isDark(AppSurfaceColors colors) =>
      colors.background.computeLuminance() < 0.2;

  /// Fond de page : lavande très pâle en clair (les cartes blanches
  /// ressortent dessus), fond sombre habituel en mode nuit.
  static Color pageBackground(AppSurfaceColors colors) =>
      isDark(colors) ? colors.surface : DashboardColors.page;

  /// Texte/icône bleu des éléments teintés, lisible dans les deux modes.
  static Color brandInk(AppSurfaceColors colors) =>
      isDark(colors) ? const Color(0xFF93C5FD) : DashboardColors.ink;

  /// Fond teinté d'une couleur d'accent (pilules, badges, pastilles).
  static Color tint(AppSurfaceColors colors, Color accent) =>
      accent.withValues(alpha: isDark(colors) ? 0.22 : 0.10);

  /// Éclaircit une couleur d'accent foncée en mode nuit.
  static Color accentInk(AppSurfaceColors colors, Color accent) =>
      isDark(colors) ? Color.lerp(accent, Colors.white, 0.35)! : accent;
}

/// Titre de section en serif (Fraunces), comme "Qu'est-ce qui ne va pas
/// chez Sucré ?" dans la maquette.
class SerifSectionTitle extends StatelessWidget {
  const SerifSectionTitle(this.text, {super.key, this.fontSize = 21});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Text(
      text,
      style: AppTypography.frauncesBold.copyWith(
        fontSize: fontSize,
        color: colors.textPrimary,
        height: 1.2,
      ),
    );
  }
}

/// Barre de titre des écrans recruteur : fond = fond de page teinté (pas de
/// bandeau séparé), titre serif, aucune ombre ni teinte au défilement.
class SoftAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SoftAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return AppBar(
      backgroundColor: SoftUi.pageBackground(colors),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      foregroundColor: colors.textPrimary,
      iconTheme: IconThemeData(color: colors.textPrimary),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: AppTypography.frauncesBold.copyWith(
          fontSize: 20,
          color: colors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions,
    );
  }
}

/// Pastille ronde teintée avec l'initiale en serif (ou la photo si fournie).
class SoftAvatar extends StatelessWidget {
  const SoftAvatar({
    super.key,
    required this.name,
    this.photo,
    this.size = 46,
    this.icon,
  });

  final String name;
  final ImageProvider? photo;
  final double size;

  /// Icône affichée à la place de l'initiale (ex. logo d'entreprise absent).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final ink = SoftUi.brandInk(colors);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SoftUi.tint(colors, DashboardColors.accent),
        shape: BoxShape.circle,
        image: photo != null
            ? DecorationImage(image: photo!, fit: BoxFit.cover)
            : null,
      ),
      child: photo != null
          ? null
          : Center(
              child: icon != null
                  ? Icon(icon, color: ink, size: size * 0.45)
                  : Text(
                      name.trim().isNotEmpty
                          ? name.trim()[0].toUpperCase()
                          : '?',
                      style: AppTypography.frauncesBold.copyWith(
                        color: ink,
                        fontSize: size * 0.42,
                      ),
                    ),
            ),
    );
  }
}

/// Bouton d'action principal pleine largeur (valider un formulaire...) —
/// même esprit que le bouton "Envoyer" de la maquette : pilule à teinte
/// pâle + texte bleu, grisé (gris neutre) quand désactivé.
class SoftPrimaryButton extends StatelessWidget {
  const SoftPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  /// Couleur d'accent (bleu océan par défaut ; rouge pour une action
  /// destructive par ex.).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final accent = color ?? DashboardColors.accent;
    final ink = color == null
        ? SoftUi.brandInk(colors)
        : SoftUi.accentInk(colors, accent);
    return PressableScale(
      enabled: onPressed != null && !loading,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: SoftUi.tint(colors, accent),
            foregroundColor: ink,
            disabledBackgroundColor: colors.divider,
            disabledForegroundColor: colors.textTertiary,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: ink,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Réduit le libellé plutôt que de déborder quand plusieurs
                    // boutons partagent une ligne (ex. "Annuler" + "Modifier
                    // l'entretien" sur un téléphone étroit).
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: AppTypography.interSemiBold.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Bloc de contenu blanc avec titre serif interne (sections d'un profil,
/// d'un formulaire...).
class SoftSection extends StatelessWidget {
  const SoftSection({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(child: SerifSectionTitle(title!, fontSize: 18)),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Carte blanche à grands coins arrondis, fine bordure et ombre bleutée
/// très légère (aucune ombre en mode nuit).
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: colors.divider),
    );
    return PressableScale(
      enabled: onTap != null,
      scale: 0.985,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: SoftUi.isDark(colors)
              ? null
              : [
                  BoxShadow(
                    color: DashboardColors.accent.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: colors.background,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Bouton pilule à teinte pâle + texte bleu (le bouton "Envoyer" de la
/// maquette) — jamais en couleur pleine. [compact] pour les liens de
/// section ("Voir tout").
class SoftPillButton extends StatelessWidget {
  const SoftPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  /// Couleur d'accent (bleu océan par défaut) — ex. le thème choisi par
  /// le candidat pour son Portfolio (`PortfolioHeroTheme.accent`).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final accent = color ?? DashboardColors.accent;
    final ink = color == null
        ? SoftUi.brandInk(colors)
        : SoftUi.accentInk(colors, accent);
    return PressableScale(
      enabled: onPressed != null,
      scale: 0.95,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: SoftUi.tint(colors, accent),
          foregroundColor: ink,
          // Désactivé : gris neutre lisible (comme le bouton "Envoyer" grisé
          // de la maquette) plutôt qu'une teinte quasi invisible.
          disabledBackgroundColor: colors.divider,
          disabledForegroundColor: colors.textTertiary,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: compact ? const Size(0, 32) : null,
          tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.interSemiBold.copyWith(
                fontSize: compact ? 12.5 : 14,
              ),
            ),
            if (icon != null) ...[
              SizedBox(width: compact ? 4 : 8),
              Icon(icon, size: compact ? 14 : 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge "point de couleur + texte" sur fond teinté (statuts, compteurs).
class SoftDotBadge extends StatelessWidget {
  const SoftDotBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final ink = SoftUi.accentInk(colors, color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SoftUi.tint(colors, color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.interSemiBold.copyWith(
              fontSize: 11.5,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// État vide : boîte teintée à fine bordure (comme la zone de saisie de
/// la maquette) plutôt qu'une simple ligne de texte en italique.
class SoftEmptyState extends StatelessWidget {
  const SoftEmptyState({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: SoftUi.isDark(colors)
            ? colors.background
            : DashboardColors.accent.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: colors.textTertiary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTypography.interRegular.copyWith(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
