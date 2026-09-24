import 'package:flutter/material.dart';

import 'package:joem/core/widgets/glass_button.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// The "Retour" / "Suivant" (→ "Créer mon compte" on the last step) button
/// pair shown at the bottom of the form card.
class WizardNavigation extends StatelessWidget {
  const WizardNavigation({
    super.key,
    required this.isLastStep,
    required this.onBack,
    required this.onNext,
    this.nextLabel,
  });

  final bool isLastStep;
  final VoidCallback onBack;

  /// `null` désactive visuellement et fonctionnellement le bouton (ex. :
  /// étape 1 du wizard tant que le compte n'est pas valide).
  final VoidCallback? onNext;

  /// Surcharge le libellé par défaut ("Suivant" / "Créer mon compte"),
  /// ex. "Création..." pendant la soumission finale.
  final String? nextLabel;

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
            color: OnboardingColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassButton(
            label: nextLabel ?? (isLastStep ? 'Créer mon compte' : 'Suivant'),
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: onNext,
            color: OnboardingColors.accent,
          ),
        ),
      ],
    );
  }
}
