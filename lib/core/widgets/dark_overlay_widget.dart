import 'package:flutter/material.dart';

/// Widget d'overlay sombre avec dégradé
/// Améliore la lisibilité du texte sur l'image de fond
class DarkOverlayWidget extends StatelessWidget {
  final double topOpacity;
  final double centerOpacity;
  final double bottomOpacity;

  const DarkOverlayWidget({
    super.key,
    this.topOpacity = 0.45,
    this.centerOpacity = 0.20,
    this.bottomOpacity = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: topOpacity),
              Colors.black.withValues(alpha: centerOpacity),
              Colors.black.withValues(alpha: bottomOpacity),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}