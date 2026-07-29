import 'package:flutter/material.dart';

import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';

/// Étape 2 — "Info personnelle" : logo de l'entreprise, identité du
/// recruteur et présentation de l'entreprise.
class StepTwoPersonalInfo extends StatelessWidget {
  const StepTwoPersonalInfo({
    super.key,
    required this.logoPicked,
    required this.onLogoTap,
    required this.nomController,
    required this.prenomController,
    required this.telephoneController,
    required this.localisation,
    required this.onLocalisationChanged,
    required this.nomEntrepriseController,
    required this.descriptionController,
  });

  final bool logoPicked;
  final VoidCallback onLogoTap;
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController telephoneController;
  final String? localisation;
  final ValueChanged<String> onLocalisationChanged;
  final TextEditingController nomEntrepriseController;
  final TextEditingController descriptionController;

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
        _LogoPicker(selected: logoPicked, onTap: onLogoTap),
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

        LightDropdown(
          label: 'Localisation',
          hint: 'Sélectionnez votre ville',
          icon: Icons.location_on_outlined,
          options: kMalagasyCities,
          value: localisation,
          onChanged: onLocalisationChanged,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Nom de l\'entreprise',
          hint: 'Ex: Tech Mada SARL',
          icon: Icons.business_rounded,
          controller: nomEntrepriseController,
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
  const _LogoPicker({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(color: Color(0xFFD8D8E2)),
        child: Container(
          width: double.infinity,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  selected ? 'Logo sélectionné' : 'Ajouter le logo de l\'entreprise',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFA6A6B4)),
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
