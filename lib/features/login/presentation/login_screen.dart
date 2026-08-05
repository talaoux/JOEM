import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:joem/core/database/app_database.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/widgets/form_surface.dart';
import 'package:joem/core/widgets/glass_button.dart';
import 'package:joem/core/widgets/google_sign_in_button.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/or_divider.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/dashboard/presentation/pages/employer_dashboard.dart';
import 'package:joem/features/dashboard/presentation/pages/job_seeker_dashboard.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

/// Écran "Connexion" : pas de wizard, un simple formulaire email + mot
/// de passe (ou Google) sur fond dégradé façon onboarding, même identité visuelle que les
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
  bool _isLoading = false;
  bool _isResettingTestAccounts = false;
  final AuthService _authService = AuthService();

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

  /// Debug uniquement : supprime tous les comptes créés localement via
  /// les wizards d'inscription (base SQLite, voir `AppDatabase`), pour
  /// pouvoir retester une inscription sans "email déjà utilisé".
  Future<void> _onResetTestAccounts() async {
    setState(() => _isResettingTestAccounts = true);

    await AppDatabase.instance.resetDatabase();
    await _authService.logout();

    if (!mounted) return;
    setState(() => _isResettingTestAccounts = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comptes de test réinitialisés.')),
    );
  }

  Future<void> _onSubmit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      // Rediriger vers le dashboard approprié
      if (_authService.isEmployer()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EmployerDashboard(),
          ),
        );
      } else if (_authService.isJobSeeker()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const JobSeekerDashboard(),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email ou mot de passe incorrect'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final isLargeScreen = size.width > 600;
    final horizontalPadding = isTablet ? 48.0 : (isLargeScreen ? 40.0 : 24.0);

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
                    const JoemGradientLogo(),
                    const SizedBox(height: 36),

                    FormSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connexion',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: OnboardingColors.navy,
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
                                        color: _rememberMe
                                            ? OnboardingColors.violet
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberMe
                                              ? OnboardingColors.violet
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
                                    color: OnboardingColors.violet,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: GlassButton(
                              label: _isLoading ? 'Connexion...' : 'Se connecter',
                              onTap: _isLoading ? null : _onSubmit,
                              color: OnboardingColors.violet,
                            ),
                          ),

                          if (kDebugMode) ...[
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton.icon(
                                onPressed: _isResettingTestAccounts
                                    ? null
                                    : _onResetTestAccounts,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                label: Text(
                                  _isResettingTestAccounts
                                      ? 'Réinitialisation...'
                                      : 'Réinitialiser les comptes de test (debug)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
      ),
    );
  }
}
