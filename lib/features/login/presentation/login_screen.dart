import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/widgets/centered_logo.dart';
import 'package:joem/core/widgets/form_surface.dart';
import 'package:joem/core/widgets/glass_button.dart';
import 'package:joem/core/widgets/google_sign_in_button.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/or_divider.dart';

/// Écran "Connexion" : pas de wizard, un simple formulaire email + mot
/// de passe (ou Google) sur fond blanc, même identité visuelle que les
/// écrans d'inscription.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onGoogleSignIn() {
    debugPrint('Connexion via Google');
  }

  void _onForgotPassword() {
    debugPrint('Navigation vers mot de passe oublié');
  }

  void _onSubmit() {
    // TODO: Authentification email + mot de passe
    debugPrint('Connexion avec ${_emailController.text}, se souvenir: $_rememberMe');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final isLargeScreen = size.width > 600;
    final horizontalPadding = isTablet ? 48.0 : (isLargeScreen ? 40.0 : 24.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 600 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    const CenteredLogo(),
                    const SizedBox(height: 36),

                    FormSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connexion',
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
                            label: 'Adresse email',
                            hint: 'votre@email.com',
                            icon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),

                          LightTextField(
                            label: 'Mot de passe',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscurable: true,
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberMe ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberMe
                                              ? AppColors.primary
                                              : const Color(0xFFD8D8E2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Se souvenir de moi',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF2A2A38)),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _onForgotPassword,
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: GlassButton(
                              label: 'Se connecter',
                              onTap: _onSubmit,
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
    );
  }
}
