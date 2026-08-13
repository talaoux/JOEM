import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/features/dashboard/presentation/pages/employer_dashboard.dart';
import 'package:joem/features/dashboard/presentation/pages/job_seeker_dashboard.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/features/welcome/presentation/welcome_screen.dart';

/// Écran de démarrage : reprend exactement le bloc marque du
/// [WelcomeScreen] — wordmark "JOEM" en dégradé ([JoemGradientLogo]),
/// grilles de points de part et d'autre, baseline "Job • Offres • Emploi
/// Madagascar" — dans une simple animation d'apparition (fondu + zoom).
/// Redirige automatiquement, une fois affiché, vers le dashboard d'une
/// session déjà ouverte (retour matériel accidentel ayant quitté l'app,
/// par ex.) — voir `AuthService.restoreSession` — ou vers [WelcomeScreen]
/// à défaut.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  Timer? _redirectTimer;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(milliseconds: 1800), _redirect);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _controller.dispose();
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
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(_scale),
            child: const _SplashBrand(),
          ),
        ),
      ),
    );
  }
}

/// Reproduit le bloc marque du welcome screen : deux grilles de points
/// encadrant le wordmark "JOEM", puis la baseline en dessous.
class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    final showDots =
        MediaQuery.of(context).size.width >= OnboardingLayout.dotGridMinWidth;

    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showDots) const Positioned(left: 8, child: _SplashDotGrid()),
          if (showDots) const Positioned(right: 8, child: _SplashDotGrid()),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              JoemGradientLogo(fontSize: 56),
              SizedBox(height: 10),
              _SplashBaselineText(),
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
      ..color = OnboardingColors.violetLight.withValues(alpha: 0.15);

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
      color: OnboardingColors.violetLight,
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
