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
import 'package:joem/features/login/presentation/forgot_password_screen.dart';
import 'package:joem/features/dashboard/presentation/pages/employer_dashboard.dart';
import 'package:joem/features/dashboard/presentation/pages/job_seeker_dashboard.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/features/welcome/presentation/welcome_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';
import 'package:joem/core/constants/google_config.dart';

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
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _onGoogleSignIn() async {
    setState(() => _isLoading = true);

    bool? result;
    String? errorMessage;
    try {
      result = await _authService.loginWithGoogle();
    } catch (_) {
      errorMessage = 'Connexion Google impossible, veuillez réessayer.';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
      );
      return;
    }
    if (result == null) {
      // L'utilisateur a annulé la sélection de compte Google — pas une
      // erreur, on ne montre rien.
      return;
    }
    if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun compte JOEM lié à ce compte Google. Inscrivez-vous d\'abord.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_authService.isEmployer()) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const EmployerDashboard()),
        (route) => false,
      );
    } else if (_authService.isJobSeeker()) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const JobSeekerDashboard()),
        (route) => false,
      );
    }
  }

  void _onForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
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

    bool success = false;
    Object? error;
    try {
      success = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue lors de la connexion, veuillez réessayer.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (success && mounted) {
      // Rediriger vers le dashboard approprié et vider la pile de
      // navigation (Welcome + Login) : le dashboard devient la racine, un
      // retour depuis "Accueil" doit quitter l'application, pas revenir
      // à Welcome/Login.
      if (_authService.isEmployer()) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const EmployerDashboard(),
          ),
          (route) => false,
        );
      } else if (_authService.isJobSeeker()) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const JobSeekerDashboard(),
          ),
          (route) => false,
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

    return PopScope(
      // Après une déconnexion, Login est la racine de la pile (Welcome en
      // a été retiré) : `canPop` est alors false et le retour matériel
      // doit renvoyer vers Welcome plutôt que quitter l'application.
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      },
      child: Scaffold(
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
                  children: staggered([
                    const SizedBox(height: 48),
                    const JoemGradientLogo(),
                    const SizedBox(height: 36),

                    FormSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: staggered([
                          Text(
                            'Connexion',
                            style: GoogleFonts.fraunces(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: OnboardingColors.navy,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Masqué tant que Google Sign-In n'est pas configuré
                          // (voir `isGoogleSignInConfigured`).
                          if (isGoogleSignInConfigured) ...[
                            GoogleSignInButton(onTap: _onGoogleSignIn),
                            const SizedBox(height: 20),

                            const OrDivider(),
                            const SizedBox(height: 20),
                          ],

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

                          // `Wrap` plutôt qu'une `Row` + `Spacer` : sur un écran
                          // étroit (ou avec "Texte agrandi"), "Mot de passe
                          // oublié ?" passe à la ligne au lieu de déborder.
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: Motion.of(const Duration(milliseconds: 180)),
                                      curve: Curves.easeOut,
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberMe
                                            ? OnboardingColors.accent
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberMe
                                              ? OnboardingColors.accent
                                              : const Color(0xFFD8D8E2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: AnimatedScale(
                                        scale: _rememberMe ? 1 : 0,
                                        duration: Motion.of(const Duration(milliseconds: 200)),
                                        curve: Curves.easeOutBack,
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Se souvenir de moi',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF2A2A38)),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _onForgotPassword,
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: OnboardingColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            child: GlassButton(
                              label: _isLoading ? 'Connexion...' : 'Se connecter',
                              onTap: _isLoading || _emailController.text.isEmpty || _passwordController.text.isEmpty
                                  ? null
                                  : _onSubmit,
                              color: _emailController.text.isEmpty || _passwordController.text.isEmpty
                                  ? OnboardingColors.accent.withOpacity(0.4)
                                  : OnboardingColors.accent,
                            ),
                          ),

                        ]),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
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
