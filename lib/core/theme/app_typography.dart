import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:joem/core/theme/app_colors.dart';

/// Typographie de l'application JOEM
/// Hiérarchie typographique professionnelle
class AppTypography {
  // ===== FONTS =====
  // Poppins ExtraBold - Titre principal
  static TextStyle get poppinsExtraBold => GoogleFonts.poppins(
    fontWeight: FontWeight.w800,
  );

  // Poppins SemiBold - Sous-titres
  static TextStyle get poppinsSemiBold => GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
  );

  // Poppins Medium
  static TextStyle get poppinsMedium => GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
  );

  // Poppins Regular
  static TextStyle get poppinsRegular => GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
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

  // Inter Bold
  static TextStyle get interBold => GoogleFonts.inter(
    fontWeight: FontWeight.w700,
  );

  // Fraunces Bold - Serif d'affichage (gros chiffres, titres de cartes du
  // dashboard recruteur, d'après la maquette `nouveau_design.jpeg`)
  static TextStyle get frauncesBold => GoogleFonts.fraunces(
    fontWeight: FontWeight.w700,
  );

  // ===== STYLES DU DASHBOARD =====

  // Titre principal du dashboard
  static TextStyle get dashboardTitle => poppinsExtraBold.copyWith(
    fontSize: 28,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
    letterSpacing: -0.5,
  );

  // Sous-titre du dashboard
  static TextStyle get dashboardSubtitle => poppinsSemiBold.copyWith(
    fontSize: 18,
    color: const Color(0xFF2D2D44),
    height: 1.4,
  );

  // Texte de salutation
  static TextStyle get greeting => poppinsSemiBold.copyWith(
    fontSize: 22,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
  );

  // Texte de message de bienvenue
  static TextStyle get welcomeMessage => interRegular.copyWith(
    fontSize: 15,
    color: const Color(0xFF6B7280),
    height: 1.5,
  );

  // Titre de section
  static TextStyle get sectionTitle => poppinsSemiBold.copyWith(
    fontSize: 20,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
  );

  // Titre de carte
  static TextStyle get cardTitle => poppinsSemiBold.copyWith(
    fontSize: 16,
    color: const Color(0xFF1A1A2E),
    height: 1.4,
  );

  // Description de carte
  static TextStyle get cardDescription => interRegular.copyWith(
    fontSize: 14,
    color: const Color(0xFF6B7280),
    height: 1.5,
  );

  // Texte de statistique (nombre)
  static TextStyle get statNumber => poppinsExtraBold.copyWith(
    fontSize: 32,
    color: const Color(0xFF1A1A2E),
    height: 1.2,
  );

  // Label de statistique
  static TextStyle get statLabel => interMedium.copyWith(
    fontSize: 13,
    color: const Color(0xFF6B7280),
    height: 1.4,
  );

  // Titre d'offre d'emploi
  static TextStyle get jobTitle => poppinsSemiBold.copyWith(
    fontSize: 15,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
  );

  // Nom de l'entreprise
  static TextStyle get companyName => interMedium.copyWith(
    fontSize: 13,
    color: const Color(0xFF6B7280),
    height: 1.4,
  );

  // Informations d'offre (ville, salaire, contrat)
  static TextStyle get jobInfo => interRegular.copyWith(
    fontSize: 12,
    color: const Color(0xFF9CA3AF),
    height: 1.4,
  );

  // Badge
  static TextStyle get badge => interSemiBold.copyWith(
    fontSize: 11,
    color: Colors.white,
    height: 1.2,
  );

  // Bouton principal
  static TextStyle get primaryButton => interSemiBold.copyWith(
    fontSize: 15,
    color: Colors.white,
    height: 1.3,
  );

  // Bouton secondaire
  static TextStyle get secondaryButton => interSemiBold.copyWith(
    fontSize: 14,
    color: const Color(0xFF1D4ED8),
    height: 1.3,
  );

  // Texte de catégorie
  static TextStyle get categoryTitle => interMedium.copyWith(
    fontSize: 14,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
  );

  // Texte d'entretien
  static TextStyle get interviewCompany => poppinsMedium.copyWith(
    fontSize: 15,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
  );

  static TextStyle get interviewDetail => interRegular.copyWith(
    fontSize: 13,
    color: const Color(0xFF6B7280),
    height: 1.4,
  );

  // Conseil du jour
  static TextStyle get adviceTitle => poppinsSemiBold.copyWith(
    fontSize: 16,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
  );

  static TextStyle get adviceText => interRegular.copyWith(
    fontSize: 14,
    color: const Color(0xFF6B7280),
    height: 1.5,
  );

  // Bottom navigation
  static TextStyle get navLabel => interMedium.copyWith(
    fontSize: 12,
    color: const Color(0xFF9CA3AF),
    height: 1.3,
  );

  static TextStyle get navLabelActive => interSemiBold.copyWith(
    fontSize: 12,
    color: const Color(0xFF3B82F6),
    height: 1.3,
  );

  // ===== FORMULAIRES / WIZARD D'INSCRIPTION =====

  // Libellé sous un cercle du stepper
  static TextStyle get stepperLabel => interMedium.copyWith(
    fontSize: 13,
    color: AppColors.textTertiary,
  );

  static TextStyle get stepperLabelActive => interSemiBold.copyWith(
    fontSize: 13,
    color: const Color(0xFF1D4ED8),
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