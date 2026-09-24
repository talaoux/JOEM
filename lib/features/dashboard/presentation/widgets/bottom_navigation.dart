import 'package:flutter/material.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/notification_badge.dart';
import 'soft_ui.dart';

/// Barre de navigation basse personnalisée : une capsule blanche flottante
/// (marge de tous côtés, coins très arrondis, légère ombre) dont le bord du
/// haut se creuse en une arche douce au centre pour épouser le bouton
/// "Accueil", qui dépasse légèrement au-dessus — le bouton n'est pas
/// simplement posé par-dessus une barre rectangulaire, la barre est
/// "sculptée" autour de lui (voir `_BumpedBarGeometry`).
///
/// Volontairement pas une `BottomNavigationBar` Material : la forme du bord
/// supérieur n'est pas exprimable avec un `ShapeBorder` standard, d'où le
/// `CustomClipper`/`CustomPainter` dédiés plus bas.
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int notificationCount;

  /// Surcharge la couleur d'accent par défaut (`DashboardColors.accent`,
  /// bleu océan) — les deux dashboards la passent explicitement.
  /// Toujours une teinte déjà présente dans le thème JOEM, jamais une
  /// couleur introduite pour cette barre.
  final Color? accentColor;

  /// Surcharge l'icône/le libellé de l'item en position 1 (par défaut
  /// "Catégorie", pertinent côté candidat) — le dashboard recruteur y
  /// passe une icône de recherche et "Recherche" (recherche de candidats).
  final IconData secondItemIcon;
  final String secondItemLabel;

  /// Surcharge l'icône/le libellé de l'item en position 2 (par défaut
  /// "Publier", pertinent côté recruteur qui publie de vraies offres) — le
  /// dashboard candidat y passe une icône de portfolio et "Portfolio"
  /// (`PortfolioScreen`, plus de composeur de post social mocké).
  final IconData thirdItemIcon;
  final String thirdItemLabel;

  /// Bouton "Accueil" à teinte pâle + icône colorée plutôt qu'en couleur
  /// pleine ("nouveau design", accueil recruteur). `false` = rendu
  /// d'origine (dashboard candidat).
  final bool softHomeButton;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
    this.accentColor,
    this.secondItemIcon = Icons.grid_view_rounded,
    this.secondItemLabel = 'Catégorie',
    this.thirdItemIcon = Icons.add_box_outlined,
    this.thirdItemLabel = 'Publier',
    this.softHomeButton = false,
  });

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  bool _isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 390;
  }

  /// Taille d'icône responsive (items secondaires)
  double _getIconSize(BuildContext context) {
    if (_isSmallScreen(context)) return 20;
    if (_isMediumScreen(context)) return 22;
    return 24;
  }

  /// Taille de police des labels, responsive
  double _getLabelFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 10;
    if (_isMediumScreen(context)) return 11;
    return 12;
  }

  /// Diamètre du bouton "Accueil" flottant — ~56px sur un écran standard,
  /// légèrement réduit sur petit écran pour garder les 5 items équilibrés.
  double _getHomeButtonSize(BuildContext context) {
    if (_isSmallScreen(context)) return 50;
    if (_isMediumScreen(context)) return 54;
    return 56;
  }

  /// Dépassement du bouton "Accueil" au-dessus de la barre — nul : le
  /// bouton est désormais centré verticalement dans la barre, comme les
  /// autres icônes, plutôt que de déborder par-dessus (plus d'arche à
  /// creuser pour lui, voir `_BumpedBarGeometry`).
  double _getPopOut(BuildContext context) => 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    final accent = accentColor ?? DashboardColors.accent;
    final iconSize = _getIconSize(context);
    final labelFontSize = _getLabelFontSize(context);
    final homeButtonSize = _getHomeButtonSize(context);
    final popOut = _getPopOut(context);
    final isHomeActive = currentIndex == 0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    const barHeight = 74.0;
    const sideMargin = AppSpacing.lg; // 16px — marges horizontales
    const bottomMargin = AppSpacing.md; // 12px — espace avec le bas d'écran
    const cornerRadius = AppRadius.xl; // 24px

    // Le rond central est opaque et posé PAR-DESSUS la bosse : si la bosse
    // est trop étroite/basse, tout son relief se retrouve caché derrière le
    // bouton et la ligne du haut paraît plate (bug constaté en vrai). Il
    // faut donc que la bosse déborde nettement du bouton sur les côtés
    // ("épaules" visibles) — largeur nettement supérieure au rayon du
    // bouton, hauteur proche du dépassement pour un relief net.
    final bumpHalfWidth = homeButtonSize;
    final bumpHeight = popOut * 0.75;

    final geometry = _BumpedBarGeometry(
      cornerRadius: cornerRadius,
      bumpHalfWidth: bumpHalfWidth,
      bumpHeight: bumpHeight,
    );

    return SizedBox(
      height: bottomInset + bottomMargin + barHeight + popOut,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: sideMargin,
            right: sideMargin,
            bottom: bottomInset + bottomMargin,
            child: SizedBox(
              height: barHeight + bumpHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ombre douce, dessinée séparément (et non via une
                  // élévation Material) pour maîtriser précisément son flou
                  // et son opacité, et pour qu'elle épouse la même forme
                  // (coins + arche centrale) que la barre elle-même.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BumpedBarShadowPainter(geometry),
                    ),
                  ),
                  ClipPath(
                    clipper: _BumpedBarClipper(geometry),
                    child: Container(
                      color: colors.background,
                      width: double.infinity,
                      height: barHeight + bumpHeight,
                    ),
                  ),
                  // `top: bumpHeight` réserve la place de la bosse ; le
                  // contenu est ensuite centré dans le reste de la barre
                  // (`barHeight`), pour un espace égal au-dessus des icônes
                  // et en dessous des libellés — pas juste collé en haut.
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: bumpHeight,
                    ),
                    child: SizedBox(
                      height: barHeight,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              colors,
                              accent: accent,
                              icon: secondItemIcon,
                              label: secondItemLabel,
                              index: 1,
                              isActive: currentIndex == 1,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                            ),
                            _buildNavItem(
                              colors,
                              accent: accent,
                              icon: thirdItemIcon,
                              label: thirdItemLabel,
                              index: 2,
                              isActive: currentIndex == 2,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                            ),
                            _buildHomeLabel(
                              colors,
                              accent: accent,
                              isActive: isHomeActive,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                              homeButtonSize: homeButtonSize,
                            ),
                            _buildNavItem(
                              colors,
                              accent: accent,
                              icon: Icons.notifications_outlined,
                              label: 'Notification',
                              index: 3,
                              isActive: currentIndex == 3,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                              badgeCount: notificationCount,
                            ),
                            _buildNavItem(
                              colors,
                              accent: accent,
                              icon: Icons.person_outline,
                              label: 'Profil',
                              index: 4,
                              isActive: currentIndex == 4,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ni `left`/`right` : sur cet axe, Positioned retombe sur
          // l'`alignment` du Stack (bottomCenter) — le bouton reste donc
          // toujours exactement centré, quelle que soit la largeur d'écran,
          // sans jamais calculer de position en pixels absolus.
          //
          // `bottom` centre le bouton dans la même zone (hauteur `barHeight`)
          // que celle où les autres icônes sont elles-mêmes centrées — même
          // axe vertical pour toute la rangée.
          Positioned(
            bottom: bottomInset + bottomMargin + (barHeight - homeButtonSize) / 2,
            child: _HomeButton(
              size: homeButtonSize,
              iconSize: 24,
              accent: accent,
              isActive: isHomeActive,
              soft: softHomeButton,
              onTap: () => onTap(0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    AppSurfaceColors colors, {
    required Color accent,
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required double iconSize,
    required double labelFontSize,
    int badgeCount = 0,
  }) {
    final targetColor = isActive ? accent : colors.textTertiary;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NotificationBadge(
            count: badgeCount,
            child: TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 220),
              tween: ColorTween(end: targetColor),
              builder: (context, color, _) => AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                scale: isActive ? 1.08 : 1.0,
                child: Icon(icon, color: color, size: iconSize),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: isActive
                // Nouveau design (recruteur) : libellé actif de la même
                // couleur que son icône ; rendu d'origine sinon.
                ? AppTypography.navLabelActive.copyWith(
                    fontSize: labelFontSize,
                    color: softHomeButton ? accent : null,
                  )
                : colors.navLabel.copyWith(fontSize: labelFontSize),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  /// Emplacement de "Accueil" dans la rangée : pas d'icône ici (le rond
  /// flottant posé par-dessus en tient lieu) et plus de libellé non plus —
  /// juste un espace réservé, aligné avec les autres items et tapable, pour
  /// un point de contact plus large que le seul rond. Largeur = celle du
  /// bouton flottant : sans ça, `spaceEvenly` traite cet item comme large
  /// de 0px et les items voisins se retrouvent deux fois plus espacés
  /// entre eux qu'avec leurs propres voisins — l'alignement des 5 items
  /// n'est égal que si ce "trou" occupe bien la largeur du bouton.
  Widget _buildHomeLabel(
    AppSurfaceColors colors, {
    required Color accent,
    required bool isActive,
    required double iconSize,
    required double labelFontSize,
    required double homeButtonSize,
  }) {
    return GestureDetector(
      onTap: () => onTap(0),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: homeButtonSize,
        height: iconSize + 8 + AppSpacing.xs + labelFontSize,
      ),
    );
  }
}

/// Bouton "Accueil" flottant, au centre de la barre — le point de mise en
/// valeur principal de la navigation (carré très arrondi couleur JOEM —
/// presque un cercle, mais pas tout à fait — icône blanche, ombre douce).
/// Légère animation de scale à l'activation.
class _HomeButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final Color accent;
  final bool isActive;
  final bool soft;
  final VoidCallback onTap;

  const _HomeButton({
    required this.size,
    required this.iconSize,
    required this.accent,
    required this.isActive,
    required this.onTap,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        scale: isActive ? 1.0 : 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isActive ? -2 : 0, 0),
          width: size,
          height: size,
          decoration: BoxDecoration(
            // Volontairement pas `BoxShape.circle` : un carré très arrondi
            // (~30% du côté) lit comme "presque un cercle" sans en être un.
            borderRadius: BorderRadius.circular(size * 0.3),
            color: soft ? accent.withValues(alpha: 0.12) : accent,
            boxShadow: soft
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: isActive ? 0.35 : 0.22),
                      blurRadius: isActive ? 18 : 12,
                      spreadRadius: -1,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Icon(Icons.home_rounded, color: soft ? accent : Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

/// Calcule la forme complète de la capsule de navigation : un rectangle à
/// coins très arrondis dont le bord du haut se soulève en une arche douce
/// et symétrique au centre (tangente horizontale à la base ET au sommet —
/// donc pas de cassure, juste un léger plateau plat sous le bouton
/// "Accueil"). Construite par union du rectangle arrondi et de la bosse
/// (plutôt que des arcs manuels raccordés à la main) : Skia garantit une
/// jonction propre, y compris entre la bosse et les coins.
class _BumpedBarGeometry {
  final double cornerRadius;
  final double bumpHalfWidth;
  final double bumpHeight;

  const _BumpedBarGeometry({
    required this.cornerRadius,
    required this.bumpHalfWidth,
    required this.bumpHeight,
  });

  Path build(Size size) {
    final centerX = size.width / 2;

    final base = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, bumpHeight, size.width, size.height - bumpHeight),
          Radius.circular(cornerRadius),
        ),
      );

    if (bumpHeight <= 0) return base;

    // k1 : longueur de la tangente horizontale à la base de la bosse — plus
    // c'est petit, plus la courbe quitte vite la ligne plate (le relief est
    // donc déjà bien visible avant même d'atteindre le bord du bouton, qui
    // sinon le cacherait entièrement puisqu'il est posé par-dessus).
    // k2 : longueur de la tangente horizontale à son sommet (plateau) — sans
    // importance visuelle, cette zone est de toute façon sous le bouton.
    final k1 = bumpHalfWidth * 0.32;
    final k2 = bumpHalfWidth * 0.2;
    final hill = Path()
      ..moveTo(centerX - bumpHalfWidth, bumpHeight)
      ..cubicTo(
        centerX - bumpHalfWidth + k1,
        bumpHeight,
        centerX - k2,
        0,
        centerX,
        0,
      )
      ..cubicTo(
        centerX + k2,
        0,
        centerX + bumpHalfWidth - k1,
        bumpHeight,
        centerX + bumpHalfWidth,
        bumpHeight,
      )
      ..lineTo(centerX + bumpHalfWidth, size.height)
      ..lineTo(centerX - bumpHalfWidth, size.height)
      ..close();

    return Path.combine(PathOperation.union, base, hill);
  }

  bool sameAs(_BumpedBarGeometry other) {
    return cornerRadius == other.cornerRadius &&
        bumpHalfWidth == other.bumpHalfWidth &&
        bumpHeight == other.bumpHeight;
  }
}

class _BumpedBarClipper extends CustomClipper<Path> {
  final _BumpedBarGeometry geometry;

  const _BumpedBarClipper(this.geometry);

  @override
  Path getClip(Size size) => geometry.build(size);

  @override
  bool shouldReclip(covariant _BumpedBarClipper oldClipper) {
    return !oldClipper.geometry.sameAs(geometry);
  }
}

/// Ombre de la capsule, peinte à la main (chemin flouté, légèrement
/// décalé vers le bas) plutôt que via une élévation Material — pour un
/// flou et une opacité précisément réglés, très discrets : offset ~4px,
/// flou équivalent ~20px, opacité ~10%.
class _BumpedBarShadowPainter extends CustomPainter {
  final _BumpedBarGeometry geometry;

  const _BumpedBarShadowPainter(this.geometry);

  @override
  void paint(Canvas canvas, Size size) {
    final path = geometry.build(size);
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.save();
    canvas.translate(0, 5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BumpedBarShadowPainter oldDelegate) {
    return !oldDelegate.geometry.sameAs(geometry);
  }
}
