import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joem/core/constants/job_categories.dart';
import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';

/// Étape 2 — "Info personnelle" : logo de l'entreprise, identité du
/// recruteur et présentation de l'entreprise.
class StepTwoPersonalInfo extends StatelessWidget {
  const StepTwoPersonalInfo({
    super.key,
    required this.logoBytes,
    required this.onPickLogo,
    required this.nomController,
    required this.prenomController,
    required this.telephoneController,
    required this.localisationController,
    required this.nomEntrepriseController,
    required this.descriptionController,
    required this.categorieEntreprise,
    required this.onCategorieChanged,
  });

  final Uint8List? logoBytes;
  final VoidCallback onPickLogo;
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController telephoneController;
  final TextEditingController localisationController;
  final TextEditingController nomEntrepriseController;
  final TextEditingController descriptionController;

  /// Catégorie d'entreprise choisie (parmi `kJobCategories`) — champ
  /// obligatoire, réutilisé côté candidat pour filtrer les offres par
  /// secteur (voir `JobCategoriesScreen`).
  final String? categorieEntreprise;
  final ValueChanged<String> onCategorieChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations personnelles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C26),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Logo de l\'entreprise',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A38),
          ),
        ),
        const SizedBox(height: 8),
        _LogoPicker(logoBytes: logoBytes, onTap: onPickLogo),
        const SizedBox(height: 18),

        _TwoColumnRow(
          left: LightTextField(
            label: 'Nom',
            hint: 'Rakoto',
            icon: Icons.person_outline_rounded,
            controller: nomController,
          ),
          right: LightTextField(
            label: 'Prénom',
            hint: 'Hery',
            icon: Icons.person_outline_rounded,
            controller: prenomController,
          ),
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Téléphone',
          hint: '+261 XX XX XXX XX',
          icon: Icons.call_rounded,
          controller: telephoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 18),

        LocationAutocompleteField(
          hint: 'Ex : Antananarivo',
          controller: localisationController,
          options: kMalagasyCities,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Nom de l\'entreprise',
          hint: 'Ex: Tech Mada SARL',
          icon: Icons.business_rounded,
          controller: nomEntrepriseController,
        ),
        const SizedBox(height: 18),

        LightDropdown(
          label: 'Catégorie d\'entreprise',
          hint: 'Sélectionnez un secteur d\'activité',
          icon: Icons.category_outlined,
          options: kJobCategories,
          value: categorieEntreprise,
          onChanged: onCategorieChanged,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Description de vos besoins principaux',
          hint: 'Ex: Nous recrutons régulièrement des profils techniques...',
          icon: Icons.notes_rounded,
          controller: descriptionController,
          maxLines: 4,
        ),
      ],
    );
  }
}

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  static const double _breakpoint = 340;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 18),
            right,
          ],
        );
      },
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.logoBytes, required this.onTap});

  final Uint8List? logoBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoBytes != null;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(color: Color(0xFFD8D8E2)),
        child: Container(
          width: double.infinity,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasLogo
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(logoBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: OnboardingColors.violet,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: OnboardingColors.violet,
                        size: 26,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ajouter le logo de l\'entreprise',
                        style: TextStyle(fontSize: 13, color: Color(0xFFA6A6B4)),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );

    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashGap = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
