import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Wordmark "JOEM" au dégradé bleu nuit → bleu océan, même identité que le bloc
/// de marque du [WelcomeScreen], réutilisé en en-tête des écrans de
/// connexion et d'inscription (sans la grille de points ni la baseline,
/// trop chargées pour l'en-tête d'un formulaire).
class JoemGradientLogo extends StatelessWidget {
  const JoemGradientLogo({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [
          OnboardingColors.navy,
          Color(0xFF172554),
          OnboardingColors.accentDeep,
          OnboardingColors.accentLight,
        ],
        stops: [0.0, 0.38, 0.65, 1.0],
      ).createShader(rect),
      child: Text(
        'JOEM',
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
