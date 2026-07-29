import 'package:flutter/material.dart';

import 'package:joem/core/widgets/glass_button.dart';

/// The "Retour" / "Suivant" (→ "Créer mon compte" on the last step) button
/// pair shown at the bottom of the form card.
class WizardNavigation extends StatelessWidget {
  const WizardNavigation({
    super.key,
    required this.isLastStep,
    required this.onBack,
    required this.onNext,
  });

  final bool isLastStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            label: 'Retour',
            leadingIcon: Icons.arrow_back_rounded,
            variant: GlassButtonVariant.outline,
            onTap: onBack,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassButton(
            label: isLastStep ? 'Créer mon compte' : 'Suivant',
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}
