import 'package:flutter/material.dart';

/// The white card that always sits at the bottom of the registration
/// screen and hosts the current step's content plus the wizard's
/// Retour/Suivant navigation.
class FormSurface extends StatelessWidget {
  const FormSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Nouveau design : grands coins, fine bordure, ombre bleutée légère.
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
