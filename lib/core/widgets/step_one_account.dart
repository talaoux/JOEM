import 'package:flutter/material.dart';

import 'google_sign_in_button.dart';
import 'light_text_field.dart';
import 'or_divider.dart';

/// Étape 1 — "Compte" : connexion rapide via Google, ou création d'un
/// compte par email + mot de passe.
class StepOneAccount extends StatelessWidget {
  const StepOneAccount({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  void _onGoogleSignIn() {
    debugPrint('Connexion via Google');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créer votre compte',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C26),
          ),
        ),
        const SizedBox(height: 20),

        GoogleSignInButton(onTap: _onGoogleSignIn),
        const SizedBox(height: 20),

        const OrDivider(),
        const SizedBox(height: 20),

        LightTextField(
          label: 'Email',
          hint: 'votre@email.com',
          icon: Icons.mail_outline_rounded,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
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
        ),
      ],
    );
  }
}
