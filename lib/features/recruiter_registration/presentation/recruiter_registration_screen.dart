import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_durations.dart';
import 'package:joem/core/widgets/form_surface.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/core/widgets/registration_stepper.dart';
import 'package:joem/core/widgets/step_one_account.dart';
import 'package:joem/core/widgets/wizard_navigation.dart';
import 'package:joem/features/dashboard/presentation/pages/employer_dashboard.dart';
import 'package:joem/features/job_seeker_registration/data/job_seeker_repository.dart'
    show EmailAlreadyUsedException;
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

import '../data/recruiter_repository.dart';
import 'widgets/step_three_validation.dart';
import 'widgets/step_two_personal_info.dart';

/// Écran "Inscription Recruteur" : un wizard à 3 étapes (Compte, Info,
/// Validation) sur fond dégradé façon onboarding, qui reste sur une seule page — les
/// étapes changent uniquement le contenu du formulaire, jamais l'écran.
class RecruiterRegistrationScreen extends StatefulWidget {
  const RecruiterRegistrationScreen({super.key});

  @override
  State<RecruiterRegistrationScreen> createState() =>
      _RecruiterRegistrationScreenState();
}

class _RecruiterRegistrationScreenState
    extends State<RecruiterRegistrationScreen> {
  static const int _totalSteps = 3;

  int _currentStep = 0;

  // Étape 1 — Compte
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _googleAccountCreated = false;

  // Étape 2 — Info personnelle
  final _imagePicker = ImagePicker();
  Uint8List? _logoBytes;
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _localisationController = TextEditingController();
  final _nomEntrepriseController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _categorieEntreprise;

  final _repository = const RecruiterRepository();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _nomController.addListener(_onFieldChanged);
    _prenomController.addListener(_onFieldChanged);
    _localisationController.addListener(_onFieldChanged);
    _nomEntrepriseController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _localisationController.dispose();
    _nomEntrepriseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _pickLogo() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _logoBytes = bytes);
  }

  /// L'étape 1 est valide si le compte a été créé via Google, ou si les 3
  /// champs (email, mot de passe, confirmation) sont tous remplis, que
  /// l'email a un format plausible, et que les deux mots de passe
  /// correspondent.
  bool get _isStepOneValid =>
      _googleAccountCreated ||
      (_emailController.text.trim().isNotEmpty &&
          isPlausibleEmail(_emailController.text) &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text);

  /// L'étape 2 est valide si nom, prénom, localisation, nom de
  /// l'entreprise et catégorie d'entreprise sont tous remplis (téléphone
  /// et description restent optionnels).
  bool get _isStepTwoValid =>
      _nomController.text.trim().isNotEmpty &&
      _prenomController.text.trim().isNotEmpty &&
      _localisationController.text.trim().isNotEmpty &&
      _nomEntrepriseController.text.trim().isNotEmpty &&
      _categorieEntreprise != null;

  bool get _canProceedFromCurrentStep {
    switch (_currentStep) {
      case 0:
        return _isStepOneValid;
      case 1:
        return _isStepTwoValid;
      default:
        return true;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentStep -= 1);
  }

  void _goToNextStep() {
    if (_currentStep == _totalSteps - 1) {
      _submitRegistration();
      return;
    }
    setState(() => _currentStep += 1);
  }

  /// Persiste les données saisies dans les 2 étapes précédentes (voir
  /// `RecruiterRepository`/`AppDatabase`), puis ouvre directement une
  /// session pour envoyer l'utilisateur sur son dashboard.
  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // "Continuer avec Google" remplit `_emailController` avec le vrai
    // email du compte Google authentifié (voir `StepOneAccount`) mais ne
    // collecte jamais de mot de passe — ce compte JOEM ne se reconnecte
    // qu'via Google (`AuthService.loginWithGoogle`) ou "Mot de passe
    // oublié" (`AuthService.resetPassword`) s'il veut un accès classique.
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : 'recruteur.$uniqueSuffix@google.joem';
    final password = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : 'google-oauth-$uniqueSuffix';

    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final nomEntreprise = _nomEntrepriseController.text.trim();

    try {
      final result = await _repository.register(
        RecruiterRegistrationData(
          email: email,
          password: password,
          nom: nom,
          prenom: prenom,
          telephone: _telephoneController.text.trim(),
          localisation: _localisationController.text.trim(),
          nomEntreprise: nomEntreprise,
          description: _descriptionController.text.trim(),
          logoBytes: _logoBytes,
          categorieEntreprise: _categorieEntreprise!,
        ),
      );

      if (!mounted) return;

      await AuthService().setSession(
        User(
          id: result.userId.toString(),
          email: result.email,
          firstName: prenom,
          lastName: nom,
          role: 'employer',
          companyName: nomEntreprise,
          categorieEntreprise: _categorieEntreprise,
          photoBytes: _logoBytes,
          telephone: _telephoneController.text.trim(),
          localisation: _localisationController.text.trim(),
          presentation: _descriptionController.text.trim(),
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EmployerDashboard()),
      );
    } on EmailAlreadyUsedException {
      if (!mounted) return;
      setState(() {
        _currentStep = 0;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cet email est déjà utilisé, veuillez en choisir un autre.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue, veuillez réessayer.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    }
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return StepOneAccount(
          key: const ValueKey('step-1'),
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          onGoogleSignIn: (account) => setState(() {
            _googleAccountCreated = true;
            final nameParts = (account.displayName ?? '').trim().split(RegExp(r'\s+'));
            if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
              _prenomController.text = nameParts.first;
              _nomController.text = nameParts.skip(1).join(' ');
            }
          }),
        );
      case 1:
        return StepTwoPersonalInfo(
          key: const ValueKey('step-2'),
          logoBytes: _logoBytes,
          onPickLogo: _pickLogo,
          nomController: _nomController,
          prenomController: _prenomController,
          telephoneController: _telephoneController,
          localisationController: _localisationController,
          nomEntrepriseController: _nomEntrepriseController,
          descriptionController: _descriptionController,
          categorieEntreprise: _categorieEntreprise,
          onCategorieChanged: (value) => setState(() => _categorieEntreprise = value),
        );
      default:
        return StepThreeValidation(
          key: const ValueKey('step-3'),
          email: _emailController.text,
          logoPicked: _logoBytes != null,
          nom: _nomController.text,
          prenom: _prenomController.text,
          telephone: _telephoneController.text,
          localisation: _localisationController.text,
          nomEntreprise: _nomEntrepriseController.text,
          categorieEntreprise: _categorieEntreprise,
          description: _descriptionController.text,
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
                    const SizedBox(height: 32),
                    const JoemGradientLogo(),
                    const SizedBox(height: 36),

                    RegistrationStepper(
                      currentStep: _currentStep,
                      labels: const ['Compte', 'Info', 'Validation'],
                    ),
                    const SizedBox(height: 32),

                    FormSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: AppDurations.stepTransition,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0.06, 0),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildStepContent(_currentStep),
                          ),
                          const SizedBox(height: 28),
                          WizardNavigation(
                            isLastStep: _currentStep == _totalSteps - 1,
                            onBack: _goToPreviousStep,
                            onNext: (!_isSubmitting && _canProceedFromCurrentStep)
                                ? _goToNextStep
                                : null,
                            nextLabel: _isSubmitting ? 'Création...' : null,
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
      ),
    );
  }
}
