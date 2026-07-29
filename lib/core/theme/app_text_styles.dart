import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Styles de texte de l'application JOEM
/// Hiérarchie typographique professionnelle
class AppTextStyles {
  // Poppins ExtraBold - Titre principal
  static TextStyle get poppinsExtraBold => GoogleFonts.poppins(
    fontWeight: FontWeight.w800,
  );

  // Poppins SemiBold - Sous-titres
  static TextStyle get poppinsSemiBold => GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
  );

  // Inter Regular - Texte courant
  static TextStyle get interRegular => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
  );

  // Inter Medium
  static TextStyle get interMedium => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
  );

  // Inter SemiBold
  static TextStyle get interSemiBold => GoogleFonts.inter(
    fontWeight: FontWeight.w600,
  );

  // ===== STYLES PRÉDÉFINIS =====

  // Slogan principal - Hero text
  static TextStyle get heroTitle => poppinsExtraBold.copyWith(
    fontSize: 38,
    color: Colors.white,
    height: 1.3,
    letterSpacing: -0.5,
  );

  // Description sous le titre
  static TextStyle get description => interRegular.copyWith(
    fontSize: 15,
    color: AppColors.textSecondary,
    height: 1.6,
    letterSpacing: 0.2,
  );

  // Phrase colorée "Trouvez. Postulez. Réussissez."
  static TextStyle get tagline => poppinsSemiBold.copyWith(
    fontSize: 18,
    color: AppColors.primary,
    height: 1.5,
    letterSpacing: 0.5,
  );

  // Titre des cartes
  static TextStyle get cardTitle => poppinsSemiBold.copyWith(
    fontSize: 20,
    color: Colors.white,
    height: 1.3,
  );

  // Description des cartes
  static TextStyle get cardDescription => interRegular.copyWith(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Texte responsive
  static TextStyle get heroTitleResponsive => poppinsExtraBold.copyWith(
    color: Colors.white,
    height: 1.3,
    letterSpacing: -0.5,
  );

  static TextStyle get descriptionResponsive => interRegular.copyWith(
    color: AppColors.textSecondary,
    height: 1.6,
    letterSpacing: 0.2,
  );

  // ===== FORMULAIRES / WIZARD D'INSCRIPTION =====

  // Libellé sous un cercle du stepper
  static TextStyle get stepperLabel => interMedium.copyWith(
    fontSize: 13,
    color: AppColors.textTertiary,
  );

  static TextStyle get stepperLabelActive => interSemiBold.copyWith(
    fontSize: 13,
    color: AppColors.primaryLight,
  );

  // Numéro à l'intérieur d'un cercle du stepper
  static TextStyle get stepperNumber => poppinsSemiBold.copyWith(
    fontSize: 16,
    color: Colors.white,
  );

  // Texte des boutons (Retour / Suivant / Créer mon compte)
  static TextStyle get buttonLabel => interSemiBold.copyWith(
    fontSize: 16,
    color: Colors.white,
  );
}