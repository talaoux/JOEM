import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Étape 2 — "Info personnelle" : photo de profil, identité et
/// présentation du candidat.
class StepTwoPersonalInfo extends StatelessWidget {
  const StepTwoPersonalInfo({
    super.key,
    required this.photoBytes,
    required this.onPickPhoto,
    required this.nomController,
    required this.prenomController,
    required this.telephoneController,
    required this.localisationController,
    required this.titreProfessionnelController,
    required this.presentationController,
  });

  final Uint8List? photoBytes;
  final VoidCallback onPickPhoto;
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController telephoneController;
  final TextEditingController localisationController;
  final TextEditingController titreProfessionnelController;
  final TextEditingController presentationController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: staggered([
        Text(
          'Informations personnelles',
          style: GoogleFonts.fraunces(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: OnboardingColors.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Center(child: _ProfilePhotoPicker(photoBytes: photoBytes, onTap: onPickPhoto)),
        const SizedBox(height: 20),

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
          label: 'Titre professionnel',
          hint: 'Ex: Développeur Web, Électricien...',
          icon: Icons.badge_outlined,
          controller: titreProfessionnelController,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Présentation',
          hint: 'Présentez-vous en quelques mots',
          icon: Icons.notes_rounded,
          controller: presentationController,
          maxLines: 4,
        ),
      ]),
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

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({required this.photoBytes, required this.onTap});

  final Uint8List? photoBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoBytes != null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F5F8),
                border: Border.all(color: const Color(0xFFE3E3EC), width: 1.5),
              ),
              child: hasPhoto
                  ? Image.memory(photoBytes!, fit: BoxFit.cover)
                  : Icon(
                      Icons.person_outline_rounded,
                      color: OnboardingColors.accent,
                      size: 36,
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: OnboardingColors.accent,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
