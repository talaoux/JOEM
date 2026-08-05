import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:joem/features/job_seeker_registration/presentation/job_seeker_registration_screen.dart';
import 'package:joem/features/login/presentation/login_screen.dart';
import 'package:joem/features/recruiter_registration/presentation/recruiter_registration_screen.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Écran d'accueil / onboarding de JOEM.
///
/// Tient entièrement dans un seul viewport (aucun scroll) : chaque bloc est
/// dimensionné en fraction de la hauteur disponible via [LayoutBuilder], le
/// pied de page absorbant l'espace restant pour rester pixel-perfect quelle
/// que soit la taille d'écran.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _mainAnimation;

  @override
  void initState() {
    super.initState();

    // Image hero en edge-to-edge : la barre de statut passe par-dessus.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _mainAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    // Rétablit une barre de statut sombre pour les écrans suivants
    // (inscription/connexion, fond blanc) afin de ne pas leur imposer le
    // style clair pensé pour cet écran.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _animationController.dispose();
    super.dispose();
  }

  void _onRecruiterTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecruiterRegistrationScreen()),
    );
  }

  void _onJobSeekerTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JobSeekerRegistrationScreen()),
    );
  }

  void _onLoginTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Neutralise les réglages d'accessibilité extrêmes pour préserver la
    // mise en page à hauteur fixe.
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.1,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: OnboardingColors.bgTop,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [OnboardingColors.bgTop, OnboardingColors.bgBottom],
            ),
          ),
          child: Stack(
            children: [
              // Vagues mauves décoratives, tout en bas de la pile.
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _BottomWavesPainter()),
                ),
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final topInset = mediaQuery.padding.top;
                  final bottomInset = mediaQuery.padding.bottom;

                  // Facteur d'échelle typographique, basé sur la hauteur
                  // utile réellement disponible (hors barres système).
                  final scale = ((height - topInset - bottomInset) / 700)
                      .clamp(0.82, 1.12);

                  return Column(
                    children: [
                      SizedBox(
                        height: height * OnboardingLayout.hero,
                        child: _HeroSection(topInset: topInset),
                      ),
                      SizedBox(
                        height: height * OnboardingLayout.heroToBrandGap,
                      ),
                      SizedBox(
                        height: height * OnboardingLayout.brand,
                        child: _BrandBlock(
                          animation: _mainAnimation,
                          scale: scale,
                        ),
                      ),
                      SizedBox(
                        height: height * OnboardingLayout.brandToTitleGap,
                      ),
                      SizedBox(
                        height: height * OnboardingLayout.title,
                        child: _TitleBlock(
                          animation: _mainAnimation,
                          scale: scale,
                        ),
                      ),
                      SizedBox(
                        height: height * OnboardingLayout.divider,
                        child: const _Divider(),
                      ),
                      SizedBox(
                        height: height * OnboardingLayout.description,
                        child: _DescriptionBlock(scale: scale),
                      ),
                      SizedBox(height: height * OnboardingLayout.spacerSm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          height: height * OnboardingLayout.card,
                          child: _ActionCard(
                            icon: Icons.work,
                            title: 'Je suis recruteur',
                            subtitleLines: const [
                              'Publier des offres et trouvez',
                              'les meilleur talent',
                            ],
                            onTap: _onRecruiterTap,
                            animation: _mainAnimation,
                            scale: scale,
                            delayIndex: 0,
                          ),
                        ),
                      ),
                      SizedBox(height: height * OnboardingLayout.spacerXs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          height: height * OnboardingLayout.card,
                          child: _ActionCard(
                            icon: Icons.person,
                            title: 'Je cherche un emploi',
                            subtitleLines: const [
                              "Trouvez l'opportunité qui correspond",
                              'à votre profil',
                            ],
                            onTap: _onJobSeekerTap,
                            animation: _mainAnimation,
                            scale: scale,
                            delayIndex: 1,
                          ),
                        ),
                      ),
                      // Le pied de page absorbe l'espace restant : garantit
                      // une hauteur totale toujours exacte, sans overflow.
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: height * OnboardingLayout.spacerXs,
                            bottom: math.max(16.0, bottomInset),
                          ),
                          child: _LoginFooter(
                            onTap: _onLoginTap,
                            animation: _mainAnimation,
                            scale: scale,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Section hero : photo + vague de transition + sélecteur de langue.
// ============================================================================

class _HeroSection extends StatelessWidget {
  final double topInset;

  const _HeroSection({required this.topInset});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/pexels-tima-miroshnichenko-5439467.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.3),
          ),

          // Dégradé blanc discret pour adoucir la transition vers la vague.
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.25,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      OnboardingColors.bgTop,
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Positioned.fill(
            child: CustomPaint(painter: _WavePainter()),
          ),

          Positioned(
            top: topInset + 12,
            right: 16,
            child: const _LanguagePill(),
          ),
        ],
      ),
    );
  }
}

/// Vague de séparation asymétrique à un seul creux, avec un liseré violet
/// fin (dégradé transparent -> violet) et une seconde vague translucide qui
/// déborde sur la photo pour donner de la profondeur.
class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Seconde vague mauve translucide, décalée vers le haut à gauche.
    final softPath = Path()
      ..moveTo(0, h * 0.52)
      ..cubicTo(
        w * 0.22,
        h * 0.34,
        w * 0.48,
        h * 0.86,
        w * 0.82,
        h * 0.46,
      )
      ..cubicTo(
        w * 0.92,
        h * 0.36,
        w * 0.97,
        h * 0.40,
        w,
        h * 0.44,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      softPath,
      Paint()..color = OnboardingColors.violetLight.withValues(alpha: 0.12),
    );

    // Vague principale.
    final mainPath = Path()
      ..moveTo(0, h * 0.85)
      ..cubicTo(w * 0.30, h * 0.74, w * 0.55, h * 1.00, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mainPath, Paint()..color = OnboardingColors.bgTop);

    // Liseré fin, visible surtout côté droit.
    final strokePath = Path()
      ..moveTo(0, h * 0.85)
      ..cubicTo(w * 0.30, h * 0.74, w * 0.55, h * 1.00, w, h * 0.80);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [
          OnboardingColors.violet.withValues(alpha: 0.0),
          OnboardingColors.violet,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pilule "Français" superposée en haut à droite de l'image hero.
class _LanguagePill extends StatelessWidget {
  const _LanguagePill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {}, // TODO: sélection de langue
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                size: 18,
                color: OnboardingColors.baseline,
              ),
              const SizedBox(width: 6),
              Text(
                'Français',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: OnboardingColors.baseline,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: OnboardingColors.baseline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Bloc marque : wordmark JOEM + baseline, entouré des grilles de points.
// ============================================================================

class _BrandBlock extends StatelessWidget {
  final Animation<double> animation;
  final double scale;

  const _BrandBlock({required this.animation, required this.scale});

  @override
  Widget build(BuildContext context) {
    final showDots =
        MediaQuery.of(context).size.width >= OnboardingLayout.dotGridMinWidth;

    return FadeTransition(
      opacity: animation,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showDots)
              const Positioned(left: 8, child: _DotGrid()),
            if (showDots)
              const Positioned(right: 8, child: _DotGrid()),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [
                        Color(0xFF12143A),
                        Color(0xFF2D1B69),
                        Color(0xFF5B21B6),
                        Color(0xFF8B5CF6),
                      ],
                      stops: [0.0, 0.38, 0.65, 1.0],
                    ).createShader(rect),
                    child: Text(
                      'JOEM',
                      style: GoogleFonts.poppins(
                        fontSize: 56 * scale,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  _BaselineText(scale: scale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grille décorative de points violets (6 colonnes x 8 lignes).
class _DotGrid extends StatelessWidget {
  const _DotGrid();

  static const int _columns = 6;
  static const int _rows = 8;
  static const double _spacing = 12;
  static const double _dotDiameter = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (_columns - 1) * _spacing + _dotDiameter,
      height: (_rows - 1) * _spacing + _dotDiameter,
      child: const CustomPaint(painter: _DotGridPainter()),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OnboardingColors.violetLight.withValues(alpha: 0.15);

    for (var col = 0; col < _DotGrid._columns; col++) {
      for (var row = 0; row < _DotGrid._rows; row++) {
        canvas.drawCircle(
          Offset(
            _DotGrid._dotDiameter / 2 + col * _DotGrid._spacing,
            _DotGrid._dotDiameter / 2 + row * _DotGrid._spacing,
          ),
          _DotGrid._dotDiameter / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// « Job • Offres • Emploi Madagascar », avec les puces colorées.
class _BaselineText extends StatelessWidget {
  final double scale;

  const _BaselineText({required this.scale});

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      fontSize: 15 * scale,
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

// ============================================================================
// Titre principal + trait séparateur + description.
// ============================================================================

class _TitleBlock extends StatelessWidget {
  final Animation<double> animation;
  final double scale;

  const _TitleBlock({required this.animation, required this.scale});

  @override
  Widget build(BuildContext context) {
    final slide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: slide,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, slide.value),
          child: child,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trouvez. Postulez.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32 * scale,
                    fontWeight: FontWeight.w800,
                    color: OnboardingColors.navy,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Réussissez.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32 * scale,
                    fontWeight: FontWeight.w800,
                    color: OnboardingColors.violet,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 4,
        decoration: BoxDecoration(
          color: OnboardingColors.violet,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  final double scale;

  const _DescriptionBlock({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.85,
        child: _AutoFitText(
          text:
              "JOEM est la plateforme qui connecte tout le marché de l'emploi "
              'à Madagascar. Découvrez des opportunités, recrutez les '
              'meilleurs talents et bâtissez votre avenir.',
          maxLines: 4,
          style: GoogleFonts.poppins(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w400,
            color: OnboardingColors.textMuted,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Cartes d'action.
// ============================================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> subtitleLines;
  final VoidCallback onTap;
  final Animation<double> animation;
  final double scale;
  final int delayIndex;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitleLines,
    required this.onTap,
    required this.animation,
    required this.scale,
    this.delayIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final delayedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.15 * delayIndex,
        (0.7 + 0.15 * delayIndex).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: delayedAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: OnboardingColors.violet.withValues(alpha: 0.10),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: OnboardingColors.lavender,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 26, color: OnboardingColors.violet),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et sous-titre reçoivent chacun une part fixe
                      // (Expanded) de la hauteur de la carte : la somme des
                      // deux ne peut jamais dépasser l'espace disponible,
                      // quelle que soit la taille d'écran.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          // _AutoFitText (plutôt que FittedBox) : le titre
                          // peut se répartir sur 2 lignes si besoin, ce qui
                          // permet une police bien plus grande qu'en le
                          // forçant sur une seule ligne à côté de l'icône.
                          child: _AutoFitText(
                            text: title,
                            maxLines: 2,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.poppins(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w700,
                              color: OnboardingColors.navy,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _RotatingSubtitle(
                            lines: subtitleLines,
                            initialDelay: Duration(
                              milliseconds: 600 * delayIndex,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w400,
                              color: OnboardingColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: OnboardingColors.violet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sous-titre de carte à plusieurs lignes qui défilent en boucle : chaque
/// ligne s'affiche quelques secondes, puis disparaît vers le haut pendant
/// que la suivante entre en glissant depuis le bas (effet "ticker").
class _RotatingSubtitle extends StatefulWidget {
  static const Duration _interval = Duration(milliseconds: 2400);

  final List<String> lines;
  final TextStyle style;
  final Duration initialDelay;

  const _RotatingSubtitle({
    required this.lines,
    required this.style,
    this.initialDelay = Duration.zero,
  });

  @override
  State<_RotatingSubtitle> createState() => _RotatingSubtitleState();
}

class _RotatingSubtitleState extends State<_RotatingSubtitle> {
  Timer? _delayTimer;
  Timer? _periodicTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.lines.length > 1) {
      _delayTimer = Timer(widget.initialDelay, _startTicking);
    }
  }

  void _startTicking() {
    _periodicTimer = Timer.periodic(_RotatingSubtitle._interval, (_) {
      setState(() => _index = (_index + 1) % widget.lines.length);
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) {
          final isOutgoing = anim.status == AnimationStatus.reverse;
          final offset = Tween<Offset>(
            begin: isOutgoing ? const Offset(0, -0.5) : const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(anim);
          return SlideTransition(
            position: offset,
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        child: _AutoFitText(
          key: ValueKey<int>(_index),
          text: widget.lines[_index],
          maxLines: 1,
          textAlign: TextAlign.left,
          style: widget.style,
        ),
      ),
    );
  }
}

// ============================================================================
// Pied de page.
// ============================================================================

class _LoginFooter extends StatelessWidget {
  final VoidCallback onTap;
  final Animation<double> animation;
  final double scale;

  const _LoginFooter({
    required this.onTap,
    required this.animation,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Déjà inscrit ? ',
              style: GoogleFonts.poppins(
                fontSize: 14.5 * scale,
                color: OnboardingColors.textMuted,
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Text(
                'Se connecter',
                style: GoogleFonts.poppins(
                  fontSize: 14.5 * scale,
                  fontWeight: FontWeight.w600,
                  color: OnboardingColors.violet,
                  decoration: TextDecoration.underline,
                  decorationColor: OnboardingColors.violet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Vagues mauves décoratives, en fond d'écran.
// ============================================================================

class _BottomWavesPainter extends CustomPainter {
  const _BottomWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wave1 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.80)
      ..cubicTo(w * 0.18, h * 0.72, w * 0.30, h * 0.92, w * 0.48, h * 0.86)
      ..lineTo(w * 0.40, h)
      ..close();
    canvas.drawPath(
      wave1,
      Paint()..color = OnboardingColors.violetLight.withValues(alpha: 0.08),
    );

    final wave2 = Path()
      ..moveTo(w, h)
      ..lineTo(w, h * 0.82)
      ..cubicTo(w * 0.86, h * 0.74, w * 0.74, h * 0.95, w * 0.55, h * 0.90)
      ..lineTo(w * 0.62, h)
      ..close();
    canvas.drawPath(
      wave2,
      Paint()..color = const Color(0xFFA78BFA).withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// Texte auto-adaptatif : réduit la taille de police par petits paliers
// jusqu'à tenir dans l'espace alloué, pour bannir tout overflow/troncature.
// ============================================================================

class _AutoFitText extends StatelessWidget {
  static const double _minFontScale = 0.65;

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;

  const _AutoFitText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 3,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseFontSize = style.fontSize ?? 14;
        final minFontSize = baseFontSize * _minFontScale;
        var fontSize = baseFontSize;

        TextPainter measure(double size) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
            maxLines: maxLines,
            textDirection: TextDirection.ltr,
            textAlign: textAlign,
          )..layout(maxWidth: constraints.maxWidth);
          return painter;
        }

        var painter = measure(fontSize);
        while ((painter.didExceedMaxLines ||
                painter.height > constraints.maxHeight) &&
            fontSize > minFontSize) {
          fontSize -= 0.5;
          painter = measure(fontSize);
        }

        // Filet de sécurité : le Text ne respecte pas forcément la hauteur
        // maximale qu'on lui donne (sa taille dépend de son contenu). On
        // force donc la taille réellement remontée au parent via
        // SizedOverflowBox, puis on coupe le rendu avec ClipRect — même si
        // l'espace alloué est trop exigu pour la taille de police plancher,
        // aucun RenderFlex overflow ne peut plus remonter.
        final reportedHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : painter.height;

        return ClipRect(
          child: SizedOverflowBox(
            size: Size(constraints.maxWidth, reportedHeight),
            alignment: Alignment.topLeft,
            child: Text(
              text,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(fontSize: fontSize),
            ),
          ),
        );
      },
    );
  }
}