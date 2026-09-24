import 'package:flutter/material.dart';

/// Transition de page globale de l'app — remplace le "slide depuis la
/// droite" par défaut de Material par un fondu + léger glissement vers le
/// haut (nouvel écran) pendant que l'ancien s'efface légèrement en
/// s'assombrissant. Posée une seule fois sur `ThemeData.pageTransitionsTheme`
/// (voir `main.dart`), elle s'applique automatiquement à tous les
/// `Navigator.push`/`pushReplacement` existants (`MaterialPageRoute`) sans
/// modifier chacun des appels dans les écrans.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final outgoingCurved = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.85).animate(outgoingCurved),
          child: child,
        ),
      ),
    );
  }
}
