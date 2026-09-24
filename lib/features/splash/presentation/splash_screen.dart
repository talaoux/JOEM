import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/features/dashboard/presentation/pages/employer_dashboard.dart';
import 'package:joem/features/dashboard/presentation/pages/job_seeker_dashboard.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/features/welcome/presentation/welcome_screen.dart';

/// Écran de démarrage : reprend le bloc marque du [WelcomeScreen] — wordmark
/// "JOEM" en dégradé ([JoemGradientLogo]), grilles de points de part et
/// d'autre, baseline "Job • Offres • Emploi Madagascar" — avec une entrée
/// séquencée (logo → grilles de points → baseline → indicateur de
/// chargement) plutôt qu'un simple fondu global, pour une sensation de
/// démarrage plus proche d'une vraie application. Redirige automatiquement,
/// une fois la séquence jouée, vers le dashboard d'une session déjà ouverte
/// (retour matériel accidentel ayant quitté l'app, par ex.) — voir
/// `AuthService.restoreSession` — ou vers [WelcomeScreen] à défaut.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Pilote toute la séquence d'entrée : logo (0 → 62%), grilles de points
  /// (35% → 75%), baseline (60% → 100%) — des segments qui se chevauchent
  /// légèrement plutôt qu'un enchaînement strict, pour un mouvement continu
  /// au lieu d'à-coups.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  /// Boucle indépendante pour les trois points de chargement en bas de
  /// l'écran, une fois le bloc marque en place — un repère de progression
  /// discret pendant le court instant où l'app restaure la session.
  late final AnimationController _loadingController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.6,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack),
    ),
  );

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
  );

  late final Animation<double> _dotsOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
  );

  late final Animation<double> _baselineOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
  );

  late final Animation<Offset> _baselineSlide =
      Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
        ),
      );

  late final Animation<double> _loadingOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
  );

  Timer? _redirectTimer;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Laisse la séquence d'entrée se jouer entièrement (≈1.1s) puis les
    // points de chargement pulser un court instant avant de rediriger —
    // sinon la redirection coupe l'animation en plein milieu.
    _redirectTimer = Timer(const Duration(milliseconds: 2300), _redirect);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _controller.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    // Défensif : si la restauration échoue (première ouverture, base
    // indisponible, etc.), on retombe simplement sur Welcome plutôt que
    // de bloquer l'app sur l'écran de démarrage.
    bool hasSession = false;
    try {
      hasSession = await _authService.restoreSession();
    } catch (_) {
      hasSession = false;
    }
    if (!mounted) return;

    if (hasSession && _authService.isEmployer()) {
      _goTo(const EmployerDashboard());
    } else if (hasSession && _authService.isJobSeeker()) {
      _goTo(const JobSeekerDashboard());
    } else {
      _goTo(const WelcomeScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(opacity: animation, child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SplashBrand(
              logoScale: _logoScale,
              logoOpacity: _logoOpacity,
              dotsOpacity: _dotsOpacity,
              baselineOpacity: _baselineOpacity,
              baselineSlide: _baselineSlide,
            ),
            const SizedBox(height: 88),
            FadeTransition(
              opacity: _loadingOpacity,
              child: _LoadingDots(
                repeat: _loadingController,
                color: OnboardingColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reproduit le bloc marque du welcome screen : deux grilles de points
/// encadrant le wordmark "JOEM", puis la baseline en dessous — chaque
/// partie anime son entrée séparément (voir les `Animation` reçues).
class _SplashBrand extends StatelessWidget {
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;
  final Animation<double> dotsOpacity;
  final Animation<double> baselineOpacity;
  final Animation<Offset> baselineSlide;

  const _SplashBrand({
    required this.logoScale,
    required this.logoOpacity,
    required this.dotsOpacity,
    required this.baselineOpacity,
    required this.baselineSlide,
  });

  @override
  Widget build(BuildContext context) {
    final showDots =
        MediaQuery.of(context).size.width >= OnboardingLayout.dotGridMinWidth;

    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showDots)
            Positioned(
              left: 8,
              child: FadeTransition(
                opacity: dotsOpacity,
                child: const _SplashDotGrid(),
              ),
            ),
          if (showDots)
            Positioned(
              right: 8,
              child: FadeTransition(
                opacity: dotsOpacity,
                child: const _SplashDotGrid(),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: logoScale,
                child: FadeTransition(
                  opacity: logoOpacity,
                  child: const JoemGradientLogo(fontSize: 56),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: baselineOpacity,
                child: SlideTransition(
                  position: baselineSlide,
                  child: const _SplashBaselineText(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grille décorative de points violets (6 colonnes x 8 lignes) — même
/// forme que celle du welcome screen, de part et d'autre du wordmark.
class _SplashDotGrid extends StatelessWidget {
  const _SplashDotGrid();

  static const int _columns = 6;
  static const int _rows = 8;
  static const double _spacing = 12;
  static const double _dotDiameter = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (_columns - 1) * _spacing + _dotDiameter,
      height: (_rows - 1) * _spacing + _dotDiameter,
      child: const CustomPaint(painter: _SplashDotGridPainter()),
    );
  }
}

class _SplashDotGridPainter extends CustomPainter {
  const _SplashDotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OnboardingColors.accentLight.withValues(alpha: 0.15);

    for (var col = 0; col < _SplashDotGrid._columns; col++) {
      for (var row = 0; row < _SplashDotGrid._rows; row++) {
        canvas.drawCircle(
          Offset(
            _SplashDotGrid._dotDiameter / 2 + col * _SplashDotGrid._spacing,
            _SplashDotGrid._dotDiameter / 2 + row * _SplashDotGrid._spacing,
          ),
          _SplashDotGrid._dotDiameter / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// « Job • Offres • Emploi Madagascar », avec les puces colorées — même
/// texte que la baseline du welcome screen.
class _SplashBaselineText extends StatelessWidget {
  const _SplashBaselineText();

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: OnboardingColors.baseline,
    );
    final bulletStyle = textStyle.copyWith(
      color: OnboardingColors.accentLight,
      fontWeight: FontWeight.w600,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textStyle,
        children: [
          const TextSpan(text: 'Job '),
          TextSpan(text: '•', style: bulletStyle),
          const TextSpan(text: ' Offres '),
          TextSpan(text: '•', style: bulletStyle),
          const TextSpan(text: ' Emploi Madagascar'),
        ],
      ),
    );
  }
}

/// Trois points qui pulsent en boucle, décalés dans le temps — l'indicateur
/// de chargement discret affiché sous le bloc marque pendant que l'app
/// restaure une éventuelle session (`AuthService.restoreSession`). Piloté
/// à la main (`sin` sur la valeur du controller, déphasée par point) plutôt
/// qu'avec trois `AnimationController` séparés : un seul ticker à gérer.
class _LoadingDots extends StatelessWidget {
  final Animation<double> repeat;
  final Color color;

  const _LoadingDots({required this.repeat, required this.color});

  static const int _dotCount = 3;
  static const double _dotDiameter = 8;
  static const double _staggerFraction = 0.22;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repeat,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_dotCount, (index) {
            final phase = (repeat.value + index * _staggerFraction) % 1.0;
            // sin(0) = sin(π) = 0, sin(π/2) = 1 : chaque point grandit puis
            // rétrécit sur son propre cycle, jamais un simple clignotement.
            final pulse = math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: 0.35 + 0.65 * pulse,
                child: Transform.scale(
                  scale: 0.55 + 0.45 * pulse,
                  child: Container(
                    width: _dotDiameter,
                    height: _dotDiameter,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
