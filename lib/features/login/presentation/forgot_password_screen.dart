import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:joem/core/widgets/form_surface.dart';
import 'package:joem/core/widgets/glass_button.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Réinitialisation locale du mot de passe (`AuthService.resetPassword`) —
/// aucun serveur mail : pas d'envoi de lien, l'utilisateur saisit
/// directement son nouveau mot de passe une fois son email retrouvé en
/// base. Ne concerne pas les comptes de démo (voir doc de
/// `AuthService.resetPassword`).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isSubmitting = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Renseignez votre adresse email' : null;
      _passwordError = newPassword.length < 6
          ? 'Le mot de passe doit contenir au moins 6 caractères'
          : (newPassword != confirmPassword
              ? 'Les deux mots de passe ne correspondent pas'
              : null);
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isSubmitting = true);
    final success = await _authService.resetPassword(
      email: email,
      newPassword: newPassword,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé. Vous pouvez vous reconnecter.')),
      );
      Navigator.pop(context);
    } else {
      setState(() => _emailError = 'Aucun compte trouvé avec cet email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final horizontalPadding = isTablet ? 48.0 : (size.width > 600 ? 40.0 : 24.0);

    return Scaffold(
      backgroundColor: OnboardingColors.bgTop,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OnboardingColors.bgTop, OnboardingColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: OnboardingColors.navy),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          children: [
                            const JoemGradientLogo(),
                            const SizedBox(height: 36),
                            FormSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mot de passe oublié',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: OnboardingColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Renseignez l\'email de votre compte et choisissez un nouveau mot de passe.',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF6B6B7D), height: 1.4),
                                  ),
                                  const SizedBox(height: 20),

                                  LightTextField(
                                    label: 'Adresse email',
                                    hint: 'votre@email.com',
                                    icon: Icons.mail_outline_rounded,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    errorText: _emailError,
                                  ),
                                  const SizedBox(height: 18),

                                  LightTextField(
                                    label: 'Nouveau mot de passe',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    controller: _newPasswordController,
                                    obscurable: true,
                                    errorText: _passwordError,
                                  ),
                                  const SizedBox(height: 18),

                                  LightTextField(
                                    label: 'Confirmer le mot de passe',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    controller: _confirmPasswordController,
                                    obscurable: true,
                                  ),
                                  const SizedBox(height: 24),

                                  SizedBox(
                                    width: double.infinity,
                                    child: GlassButton(
                                      label: _isSubmitting
                                          ? 'Réinitialisation...'
                                          : 'Réinitialiser le mot de passe',
                                      onTap: _isSubmitting ? null : _onSubmit,
                                      color: OnboardingColors.violet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}