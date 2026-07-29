import 'package:flutter/material.dart';

/// Section logo en haut de l'écran (Welcome Screen)
/// Animation: Fade au lancement
class LogoSectionWidget extends StatelessWidget {
  final Animation<double> animation;

  const LogoSectionWidget({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final fadeValue = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ).drive(Tween(begin: 0.0, end: 1.0));

        return FadeTransition(
          opacity: fadeValue,
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/joem_logo.png',
        width: 230,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
