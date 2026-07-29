import 'package:flutter/material.dart';

/// Widget d'image de fond en plein écran
/// Utilise BoxFit.cover pour éviter toute déformation
class BackgroundImageWidget extends StatelessWidget {
  final String imagePath;
  final Alignment alignment;
  /// Facteur de zoom (> 1.0) permettant de recadrer l'image, par ex.
  /// pour ne garder que la tête visible au lieu du corps entier.
  final double zoom;

  const BackgroundImageWidget({
    super.key,
    required this.imagePath,
    this.alignment = Alignment.center,
    this.zoom = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: Align(
          alignment: alignment,
          // Agrandit l'image avant de la recadrer, pour que l'alignement
          // ait réellement un effet (sinon l'image remplit déjà toute
          // la zone et l'alignement n'a rien à décaler).
          child: FractionallySizedBox(
            heightFactor: zoom,
            child: ColorFiltered(
              // Léger contraste noir sur l'image pour améliorer la lisibilité du texte
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.12),
                BlendMode.darken,
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                // Optimisation du cache et de la performance
                cacheWidth: MediaQuery.of(context).size.width.toInt() * 2,
                cacheHeight: MediaQuery.of(context).size.height.toInt() * 2,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}