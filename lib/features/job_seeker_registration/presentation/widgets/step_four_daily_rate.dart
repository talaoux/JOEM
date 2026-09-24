import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

const List<String> kAvailabilityOptions = [
  'Disponible immédiatement',
  'Disponible sous 1 semaine',
  'Disponible sous 1 mois',
  'Non disponible',
];

enum WorkMode { teletravail, presentiel, hybride }

extension WorkModeLabel on WorkMode {
  String get label {
    switch (this) {
      case WorkMode.teletravail:
        return 'Télétravail';
      case WorkMode.presentiel:
        return 'Présentiel';
      case WorkMode.hybride:
        return 'Hybride';
    }
  }
}

/// Étape 4 — "Tarif journalier" : rémunération souhaitée, disponibilité
/// et modes de travail acceptés.
class StepFourDailyRate extends StatelessWidget {
  const StepFourDailyRate({
    super.key,
    required this.rateController,
    required this.availability,
    required this.onAvailabilityChanged,
    required this.selectedWorkModes,
    required this.onWorkModeToggled,
  });

  final TextEditingController rateController;
  final String? availability;
  final ValueChanged<String> onAvailabilityChanged;
  final Set<WorkMode> selectedWorkModes;
  final ValueChanged<WorkMode> onWorkModeToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: staggered([
        Text(
          'Tarif journalier',
          style: GoogleFonts.fraunces(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: OnboardingColors.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        LightTextField(
          label: 'Tarif journalier souhaité',
          hint: 'Ex: 50000',
          icon: Icons.payments_outlined,
          controller: rateController,
          keyboardType: TextInputType.number,
          suffixText: 'Ar',
        ),
        const SizedBox(height: 18),

        LightDropdown(
          label: 'Disponibilité',
          hint: 'Sélectionnez votre disponibilité',
          icon: Icons.event_available_outlined,
          options: kAvailabilityOptions,
          value: availability,
          onChanged: onAvailabilityChanged,
        ),
        const SizedBox(height: 18),

        const Text(
          'Mode de travail',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A38),
          ),
        ),
        const SizedBox(height: 8),
        for (final mode in WorkMode.values)
          _WorkModeCheckbox(
            mode: mode,
            checked: selectedWorkModes.contains(mode),
            onTap: () => onWorkModeToggled(mode),
          ),
      ]),
    );
  }
}

class _WorkModeCheckbox extends StatelessWidget {
  const _WorkModeCheckbox({
    required this.mode,
    required this.checked,
    required this.onTap,
  });

  final WorkMode mode;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? OnboardingColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? OnboardingColors.accent : const Color(0xFFD8D8E2),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              mode.label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C26)),
            ),
          ],
        ),
      ),
    );
  }
}
