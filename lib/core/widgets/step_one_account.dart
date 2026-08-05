import 'package:flutter/material.dart';

import 'package:joem/features/welcome/presentation/welcome_palette.dart';

import 'google_sign_in_button.dart';
import 'light_text_field.dart';
import 'or_divider.dart';

final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Vrai si [value] ressemble à un email valide (`quelquechose@domaine.tld`).
/// Une chaîne vide est considérée valide ici — le caractère obligatoire du
/// champ est géré séparément (voir `_isStepOneValid`).
bool isPlausibleEmail(String value) =>
    value.trim().isEmpty || _emailFormat.hasMatch(value.trim());

/// Étape 1 — "Compte" : connexion rapide via Google, ou création d'un
/// compte par email + mot de passe.
class StepOneAccount extends StatelessWidget {
  const StepOneAccount({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    this.onGoogleSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  /// Appelé quand l'utilisateur choisit "Continuer avec Google" — permet à
  /// l'écran parent de considérer le compte comme créé sans exiger les
  /// champs email/mot de passe/confirmation.
  final VoidCallback? onGoogleSignIn;

  void _handleGoogleSignIn() {
    debugPrint('Connexion via Google');
    onGoogleSignIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final passwordsMismatch = confirmPasswordController.text.isNotEmpty &&
        confirmPasswordController.text != passwordController.text;
    final emailInvalid = emailController.text.isNotEmpty &&
        !isPlausibleEmail(emailController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créer votre compte',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: OnboardingColors.navy,
          ),
        ),
        const SizedBox(height: 20),

        GoogleSignInButton(onTap: _handleGoogleSignIn),
        const SizedBox(height: 20),

        const OrDivider(),
        const SizedBox(height: 20),

        LightTextField(
          label: 'Email',
          hint: 'votre@email.com',
          icon: Icons.mail_outline_rounded,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: emailInvalid ? 'Adresse email invalide' : null,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          controller: passwordController,
          obscurable: true,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Confirmer le mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          controller: confirmPasswordController,
          obscurable: true,
          errorText: passwordsMismatch
              ? 'Les mots de passe ne correspondent pas'
              : null,
        ),
      ],
    );
  }
}
