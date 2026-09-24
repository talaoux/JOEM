import 'package:flutter/material.dart';

/// Petit badge rouge de notification (style Facebook) affiché
/// en haut à droite d'un widget (icône, avatar...).
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    final label = count > 9 ? '9+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          // Rejoue un petit "pop" élastique à chaque fois que le compteur
          // change (`ValueKey(count)`), pour que la pastille se fasse
          // remarquer plutôt que de simplement changer de chiffre.
          child: TweenAnimationBuilder<double>(
            key: ValueKey(count),
            tween: Tween(begin: 0.3, end: 1.0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
