import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:joem/core/widgets/form_surface.dart';
import 'package:joem/core/widgets/glass_button.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/step_one_account.dart' show isPasswordLongEnough, isPlausibleEmail, kMinPasswordLength;
import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// "Mot de passe oublié".
///
/// Avec le serveur JOEM (`API_BASE_URL`) : deux temps. L'utilisateur
/// demande un code à 6 chiffres envoyé par e-mail
/// (`AuthService.requestPasswordResetCode`), puis le saisit avec son
/// nouveau mot de passe (`AuthService.resetPasswordWithCode`).
///
/// Sans serveur (mode 100% local) : réinitialisation directe
/// (`AuthService.resetPassword`), sans e-mail. Ne concerne pas les comptes
/// de démo.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isSubmitting = false;

  /// Mode serveur : le code a été demandé, on attend sa saisie.
  bool _codeSent = false;
  String? _emailError;
  String? _codeError;
  String? _passwordError;

  bool get _isServerMode => ApiClient.shared != null;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Renseignez votre adresse email';
    if (!isPlausibleEmail(email)) return 'Adresse email invalide';
    return null;
  }

  String? _validatePasswords() {
    final newPassword = _newPasswordController.text;
    if (!isPasswordLongEnough(newPassword)) {
      return 'Le mot de passe doit contenir au moins $kMinPasswordLength caractères';
    }
    if (newPassword != _confirmPasswordController.text) {
      return 'Les deux mots de passe ne correspondent pas';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Mode serveur, étape 1 (et "Renvoyer le code").
  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    setState(() => _emailError = _validateEmail(email));
    if (_emailError != null) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.requestPasswordResetCode(email);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _emailError = error.firstErrorFor('email');
      });
      if (_emailError == null) _showMessage(error.displayMessage);
      return;
    }
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _codeSent = true;
      _codeError = null;
    });
    _showMessage('Si un compte existe avec cet email, un code à 6 chiffres vient de lui être envoyé.');
  }

  /// Mode serveur, étape 2.
  Future<void> _resetWithCode() async {
    final code = _codeController.text.trim();
    setState(() {
      _codeError = RegExp(r'^\d{6}$').hasMatch(code) ? null : 'Saisissez le code à 6 chiffres reçu par email';
      _passwordError = _validatePasswords();
    });
    if (_codeError != null || _passwordError != null) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.resetPasswordWithCode(
        email: _emailController.text,
        code: code,
        newPassword: _newPasswordController.text,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _codeError = error.firstErrorFor('code');
        _passwordError = error.firstErrorFor('password');
      });
      if (_codeError == null && _passwordError == null) _showMessage(error.displayMessage);
      return;
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showMessage('Mot de passe réinitialisé. Vous pouvez vous reconnecter.');
    Navigator.pop(context);
  }

  /// Mode local : réinitialisation directe en base.
  Future<void> _resetLocally() async {
    final email = _emailController.text.trim();
    setState(() {
      _emailError = _validateEmail(email);
      _passwordError = _validatePasswords();
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isSubmitting = true);
    final success = await _authService.resetPassword(
      email: email,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showMessage('Mot de passe réinitialisé. Vous pouvez vous reconnecter.');
      Navigator.pop(context);
    } else {
      setState(() => _emailError = 'Aucun compte trouvé avec cet email');
    }
  }

  void _changeEmail() {
    setState(() {
      _codeSent = false;
      _codeController.clear();
      _codeError = null;
      _passwordError = null;
    });
  }

  String get _introText {
    if (!_isServerMode) {
      return 'Renseignez l\'email de votre compte et choisissez un nouveau mot de passe.';
    }
    if (!_codeSent) {
      return 'Renseignez l\'email de votre compte : nous vous enverrons un code à 6 chiffres.';
    }
    return 'Saisissez le code reçu à ${_emailController.text.trim()} (pensez à vérifier les spams), '
        'puis choisissez un nouveau mot de passe.';
  }

  List<Widget> _formFields() {
    final showEmail = !_isServerMode || !_codeSent;
    final showPasswords = !_isServerMode || _codeSent;

    return [
      if (showEmail) ...[
        LightTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          icon: Icons.mail_outline_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
        const SizedBox(height: 18),
      ],
      if (_isServerMode && _codeSent) ...[
        LightTextField(
          label: 'Code reçu par email',
          hint: '123456',
          icon: Icons.pin_outlined,
          controller: _codeController,
          keyboardType: TextInputType.number,
          errorText: _codeError,
        ),
        const SizedBox(height: 18),
      ],
      if (showPasswords) ...[
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
        const SizedBox(height: 18),
      ],
    ];
  }

  Widget _primaryButton() {
    final String label;
    final Future<void> Function() action;
    if (!_isServerMode) {
      label = _isSubmitting ? 'Réinitialisation...' : 'Réinitialiser le mot de passe';
      action = _resetLocally;
    } else if (!_codeSent) {
      label = _isSubmitting ? 'Envoi...' : 'Recevoir un code';
      action = _requestCode;
    } else {
      label = _isSubmitting ? 'Réinitialisation...' : 'Réinitialiser le mot de passe';
      action = _resetWithCode;
    }

    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        label: label,
        onTap: _isSubmitting ? null : action,
        color: OnboardingColors.accent,
      ),
    );
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
                          children: staggered([
                            const JoemGradientLogo(),
                            const SizedBox(height: 36),
                            FormSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mot de passe oublié',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      color: OnboardingColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _introText,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B7D), height: 1.4),
                                  ),
                                  const SizedBox(height: 20),
                                  // Change entre "demander le code" et "saisir le
                                  // code" : ajustement de hauteur + fondu.
                                  SmoothSwitcher(
                                    child: Column(
                                      key: ValueKey(_codeSent),
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _formFields(),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _primaryButton(),
                                  if (_isServerMode && _codeSent) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      children: [
                                        TextButton(
                                          onPressed: _isSubmitting ? null : _requestCode,
                                          child: const Text('Renvoyer le code'),
                                        ),
                                        TextButton(
                                          onPressed: _isSubmitting ? null : _changeEmail,
                                          child: const Text('Changer d\'email'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
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
            ],
          ),
        ),
      ),
    );
  }
}
