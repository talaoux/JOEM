import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:joem/core/services/google_auth_service.dart';
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
class StepOneAccount extends StatefulWidget {
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

  /// Appelé avec le compte Google réellement authentifié — permet à
  /// l'écran parent de préremplir nom/prénom et de considérer le compte
  /// comme créé sans exiger les champs email/mot de passe/confirmation.
  final ValueChanged<GoogleSignInAccount>? onGoogleSignIn;

  @override
  State<StepOneAccount> createState() => _StepOneAccountState();
}

class _StepOneAccountState extends State<StepOneAccount> {
  bool _isSigningIn = false;
  String? _googleError;

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _googleError = null;
    });

    try {
      final account = await GoogleAuthService.instance.signIn();
      if (!mounted) return;
      if (account == null) {
        // Annulé par l'utilisateur — pas une erreur à afficher.
        setState(() => _isSigningIn = false);
        return;
      }
      widget.emailController.text = account.email;
      setState(() => _isSigningIn = false);
      widget.onGoogleSignIn?.call(account);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _googleError = 'Connexion Google impossible. Vérifiez votre connexion et réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsMismatch = widget.confirmPasswordController.text.isNotEmpty &&
        widget.confirmPasswordController.text != widget.passwordController.text;
    final emailInvalid = widget.emailController.text.isNotEmpty &&
        !isPlausibleEmail(widget.emailController.text);

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

        GoogleSignInButton(
          onTap: _handleGoogleSignIn,
          label: _isSigningIn ? 'Connexion...' : 'Continuer avec Google',
        ),
        if (_googleError != null) ...[
          const SizedBox(height: 8),
          Text(
            _googleError!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
          ),
        ],
        const SizedBox(height: 20),

        const OrDivider(),
        const SizedBox(height: 20),

        LightTextField(
          label: 'Email',
          hint: 'votre@email.com',
          icon: Icons.mail_outline_rounded,
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: emailInvalid ? 'Adresse email invalide' : null,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          controller: widget.passwordController,
          obscurable: true,
        ),
        const SizedBox(height: 18),

        LightTextField(
          label: 'Confirmer le mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          controller: widget.confirmPasswordController,
          obscurable: true,
          errorText: passwordsMismatch
              ? 'Les mots de passe ne correspondent pas'
              : null,
        ),
      ],
    );
  }
}