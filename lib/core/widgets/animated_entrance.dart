import 'package:flutter/material.dart';

import '../services/display_preferences_controller.dart';

/// Boîte à outils d'animation de l'app : apparitions en cascade, effet
/// d'enfoncement au toucher, chiffres qui défilent, transitions de blocs.
/// Tout respecte le réglage "Animations réduites" (Paramètres → Affichage,
/// [DisplayPreferencesController.reducedAnimations]) : les éléments
/// s'affichent alors directement, sans mouvement.
abstract final class Motion {
  /// `true` si l'utilisateur a demandé des animations réduites.
  static bool get reduced =>
      DisplayPreferencesController.instance.reducedAnimations;

  /// Courbe par défaut des apparitions : départ vif, arrivée douce.
  static const Curve curve = Curves.easeOutCubic;

  /// Durée des transitions de bloc (apparition, changement de contenu).
  static const Duration switchDuration = Duration(milliseconds: 320);

  /// [duration], ou zéro si les animations sont réduites.
  static Duration of(Duration duration) => reduced ? Duration.zero : duration;
}

/// Fait apparaître [child] en fondu + léger glissement vers le haut, avec un
/// délai optionnel — utilisé pour faire apparaître les éléments d'une liste
/// (offres, notifications, résultats de recherche...) les uns après les
/// autres ("stagger") dès que les vraies données sont chargées, plutôt que
/// de les afficher d'un coup. Rejoue l'animation à chaque fois que la clé du
/// widget change (ex. `ValueKey(offer.id)`), donc pas de replay superflu si
/// le parent se reconstruit sans changer la liste. Affiché directement si
/// les animations sont réduites.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // Le délai fait partie de l'animation (début de l'[Interval]) plutôt
  // qu'un `Future.delayed` : aucune minuterie ne reste en attente si
  // l'écran est quitté avant la fin de la cascade.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final double _start = _controller.duration!.inMicroseconds == 0
      ? 0
      : widget.delay.inMicroseconds / _controller.duration!.inMicroseconds;
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Interval(_start, 1, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Interval(_start, 1, curve: Motion.curve),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (Motion.reduced) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Délai de stagger pour l'élément [index] d'une liste — plafonné pour que
/// les listes longues ne mettent pas une éternité à finir d'apparaître.
Duration staggerDelayFor(
  int index, {
  int maxSteps = 8,
  Duration step = const Duration(milliseconds: 55),
}) {
  return step * index.clamp(0, maxSteps);
}

/// Enveloppe chaque élément de [children] dans un [FadeSlideIn] décalé
/// (apparition en cascade des sections d'un écran). Les espaceurs
/// ([SizedBox] sans enfant) ne sont ni animés ni comptés dans le décalage.
/// Usage : `Column(children: staggered([...]))`.
List<Widget> staggered(
  List<Widget> children, {
  Duration step = const Duration(milliseconds: 60),
  int maxSteps = 8,
}) {
  var index = 0;
  return [
    for (final child in children)
      if (child is SizedBox && child.child == null)
        child
      else
        FadeSlideIn(
          delay: staggerDelayFor(index++, maxSteps: maxSteps, step: step),
          child: child,
        ),
  ];
}

/// Effet d'enfoncement au toucher : [child] rétrécit légèrement (×[scale])
/// tant que le doigt est posé, puis revient en souplesse — retour tactile
/// des cartes et boutons. N'intercepte aucun geste (simple [Listener]) :
/// les `onTap`/`InkWell` du [child] fonctionnent comme avant.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || Motion.reduced) return widget.child;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: Duration(milliseconds: _pressed ? 90 : 220),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Texte d'un chiffre clé qui défile jusqu'à sa valeur (0 → 12) à
/// l'apparition, puis de l'ancienne à la nouvelle valeur quand elle change.
/// Si [value] n'est pas un entier ("—", "12 %"...), il est affiché tel quel.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText(
    this.value, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final String value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final target = int.tryParse(value.trim());
    if (target == null || Motion.reduced) return Text(value, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: duration,
      curve: Motion.curve,
      builder: (context, current, _) =>
          Text(current.round().toString(), style: style),
    );
  }
}

/// Zoom arrière lent à l'apparition (effet "Ken Burns") : [child] démarre
/// légèrement agrandi puis revient à sa taille — pour une photo plein cadre
/// (image hero de l'accueil). À placer dans un parent qui rogne (`ClipRect`).
class SlowZoomIn extends StatelessWidget {
  const SlowZoomIn({
    super.key,
    required this.child,
    this.from = 1.08,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final double from;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
    );
  }
}

/// Transition douce quand un bloc apparaît, disparaît ou change de contenu :
/// la hauteur s'ajuste en souplesse ([AnimatedSize]) pendant que l'ancien
/// contenu s'efface et que le nouveau apparaît en glissant légèrement.
/// Donner une `key` différente à [child] pour chaque état (ex.
/// `ValueKey(status)`) ; `null` = rien à afficher.
class SmoothSwitcher extends StatelessWidget {
  const SmoothSwitcher({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget? child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(Motion.switchDuration);
    return AnimatedSize(
      duration: duration,
      curve: Motion.curve,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Motion.curve,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: alignment,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child:
            child ??
            const SizedBox(width: double.infinity, key: ValueKey('empty')),
      ),
    );
  }
}
