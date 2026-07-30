import 'dart:async';

import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_text_styles.dart';
import 'package:joem/features/welcome/presentation/welcome_screen.dart';

/// Écran de démarrage : reproduit le logo JOEM en texte animé (lettres
/// qui apparaissent une à une, puis le slogan complet), sans dépendre de
/// l'image `joem_logo.png`. Redirige automatiquement vers [WelcomeScreen]
/// une fois l'animation terminée.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _letters = ['J', 'O', 'E', 'M'];

  late final AnimationController _controller;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _redirectTimer = Timer(const Duration(milliseconds: 2900), _goToWelcome);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goToWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(opacity: animation, child: const WelcomeScreen()),
      ),
    );
  }

  Animation<double> _letterProgress(int index) {
    final start = 0.05 * index;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, start + 0.4, curve: Curves.easeOutBack),
    );
  }

  late final Animation<double> _glowProgress = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );

  late final Animation<double> _lineProgress = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _taglineProgress = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 0.9, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGlowingLetters(),
            const SizedBox(height: 16),
            _buildGrowingLine(),
            const SizedBox(height: 22),
            _buildTagline(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingLetters() {
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: _glowProgress,
          child: ScaleTransition(
            scale: Tween(begin: 0.6, end: 1.0).animate(_glowProgress),
            child: Container(
              width: 240,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryLightest, Colors.white.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_letters.length, (index) {
            final progress = _letterProgress(index);
            return FadeTransition(
              opacity: progress,
              child: ScaleTransition(
                scale: Tween(begin: 0.4, end: 1.0).animate(progress),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(progress),
                  child: _buildLetterGlyph(index),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Reproduit le style "moitié pleine, moitié contour" du logo : les deux
  /// premières lettres en mauve plein, les deux dernières en contour mauve
  /// (intérieur transparent, la page blanche fait office de remplissage).
  Widget _buildLetterGlyph(int index) {
    final baseStyle = AppTextStyles.poppinsExtraBold.copyWith(
      fontSize: 72,
      height: 1,
      letterSpacing: 2,
    );
    final isFilled = index < _letters.length / 2;

    return Text(
      _letters[index],
      style: isFilled
          ? baseStyle.copyWith(color: AppColors.primary)
          : baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.2
                ..color = AppColors.primary,
            ),
    );
  }

  Widget _buildGrowingLine() {
    return AnimatedBuilder(
      animation: _lineProgress,
      builder: (context, _) {
        return Container(
          height: 3,
          width: 150 * _lineProgress.value,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineProgress,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(_taglineProgress),
        child: const _TaglineText(),
      ),
    );
  }
}

/// Reproduit "Job Offer & Employment Madagascar" avec les initiales
/// J-O-E-M mises en avant, comme sur le logo image.
class _TaglineText extends StatelessWidget {
  const _TaglineText();

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.interRegular.copyWith(
      fontSize: 13,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
    );
    final accent = AppTextStyles.poppinsSemiBold.copyWith(
      fontSize: 13,
      color: AppColors.primary,
      letterSpacing: 0.4,
    );
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'J', style: accent),
          TextSpan(text: 'ob ', style: muted),
          TextSpan(text: 'O', style: accent),
          TextSpan(text: 'ffer & ', style: muted),
          TextSpan(text: 'E', style: accent),
          TextSpan(text: 'mployment ', style: muted),
          TextSpan(text: 'M', style: accent),
          TextSpan(text: 'adagascar', style: muted),
        ],
      ),
    );
  }
}