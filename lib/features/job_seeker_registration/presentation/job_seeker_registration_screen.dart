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
import 'package:joem/features/dashboard/presentation/pages/job_seeker_dashboard.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

import '../data/job_seeker_repository.dart';
import 'widgets/step_five_validation.dart';
import 'widgets/step_four_daily_rate.dart';
import 'widgets/step_three_professional_profile.dart';
import 'widgets/step_two_personal_info.dart';

/// Écran "Inscription Chercheur d'emploi" : un wizard à 5 étapes
/// (Compte, Info, Profil, Tarif, Validation) sur fond dégradé façon onboarding, qui reste
/// sur une seule page — les étapes changent uniquement le contenu du
/// formulaire, jamais l'écran.
class JobSeekerRegistrationScreen extends StatefulWidget {
  const JobSeekerRegistrationScreen({super.key});

  @override
  State<JobSeekerRegistrationScreen> createState() =>
      _JobSeekerRegistrationScreenState();
}

class _JobSeekerRegistrationScreenState
    extends State<JobSeekerRegistrationScreen> {
  static const int _totalSteps = 5;
  static const _stepLabels = ['Compte', 'Info', 'Profil', 'Tarif', 'Validation'];

  int _currentStep = 0;

  // Étape 1 — Compte
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _googleAccountCreated = false;

  // Étape 2 — Info personnelle
  final _imagePicker = ImagePicker();
  Uint8List? _photoBytes;
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _localisationController = TextEditingController();
  final _titreProfessionnelController = TextEditingController();
  final _presentationController = TextEditingController();

  // Étape 3 — Profil professionnel
  final List<SkillEntry> _skills = [SkillEntry()];
  bool _cvPicked = false;

  // Étape 4 — Tarif journalier
  final _rateController = TextEditingController();
  String? _availability;
  final Set<WorkMode> _workModes = {};

  final _repository = const JobSeekerRepository();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _nomController.addListener(_onFieldChanged);
    _prenomController.addListener(_onFieldChanged);
    _titreProfessionnelController.addListener(_onFieldChanged);
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
    _titreProfessionnelController.dispose();
    _presentationController.dispose();
    for (final skill in _skills) {
      skill.dispose();
    }
    _rateController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _pickPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBytes = bytes);
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

  /// L'étape 2 est valide si nom, prénom et titre professionnel sont
  /// remplis (téléphone, localisation et présentation restent optionnels).
  bool get _isStepTwoValid =>
      _nomController.text.trim().isNotEmpty &&
      _prenomController.text.trim().isNotEmpty &&
      _titreProfessionnelController.text.trim().isNotEmpty;

  /// L'étape 4 est valide si disponibilité et au moins un mode de travail
  /// sont renseignés (tarif reste optionnel).
  bool get _isStepFourValid => _availability != null && _workModes.isNotEmpty;

  bool get _canProceedFromCurrentStep {
    switch (_currentStep) {
      case 0:
        return _isStepOneValid;
      case 1:
        return _isStepTwoValid;
      case 3:
        return _isStepFourValid;
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

  /// Persiste les données saisies dans les 4 étapes précédentes (voir
  /// `JobSeekerRepository`/`AppDatabase`), puis ouvre directement une
  /// session pour envoyer l'utilisateur sur son dashboard.
  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // "Continuer avec Google" ne collecte pas de vrai email/mot de passe
    // (bouton non branché à une vraie auth) : on génère des identifiants
    // uniques pour que le compte reste créable et reconnectable.
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : 'candidat.$uniqueSuffix@google.joem';
    final password = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : 'google-oauth-$uniqueSuffix';

    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();

    final skills = _skills
        .where((skill) => skill.nameController.text.trim().isNotEmpty)
        .map((skill) => (name: skill.nameController.text.trim(), rating: skill.rating))
        .toList();

    try {
      final result = await _repository.register(
        JobSeekerRegistrationData(
          email: email,
          password: password,
          nom: nom,
          prenom: prenom,
          telephone: _telephoneController.text.trim(),
          localisation: _localisationController.text.trim(),
          titreProfessionnel: _titreProfessionnelController.text.trim(),
          presentation: _presentationController.text.trim(),
          photoBytes: _photoBytes,
          skills: skills,
          cvPicked: _cvPicked,
          tarifJournalier: _rateController.text.trim(),
          disponibilite: _availability,
          workModes: _workModes.map((mode) => mode.name).toList(),
        ),
      );

      if (!mounted) return;

      AuthService().setSession(
        User(
          id: result.userId.toString(),
          email: result.email,
          firstName: prenom,
          lastName: nom,
          role: 'job_seeker',
          position: _titreProfessionnelController.text.trim(),
          photoBytes: _photoBytes,
          telephone: _telephoneController.text.trim(),
          localisation: _localisationController.text.trim(),
          presentation: _presentationController.text.trim(),
          cvPicked: _cvPicked,
          tarifJournalier: _rateController.text.trim(),
          disponibilite: _availability,
          skills: skills.map((skill) => skill.name).toList(),
          workModes: _workModes.map((mode) => mode.name).toList(),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const JobSeekerDashboard()),
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
          onGoogleSignIn: () => setState(() => _googleAccountCreated = true),
        );
      case 1:
        return StepTwoPersonalInfo(
          key: const ValueKey('step-2'),
          photoBytes: _photoBytes,
          onPickPhoto: _pickPhoto,
          nomController: _nomController,
          prenomController: _prenomController,
          telephoneController: _telephoneController,
          localisationController: _localisationController,
          titreProfessionnelController: _titreProfessionnelController,
          presentationController: _presentationController,
        );
      case 2:
        return StepThreeProfessionalProfile(
          key: const ValueKey('step-3'),
          skills: _skills,
          onAddSkill: () => setState(() => _skills.add(SkillEntry())),
          onRemoveSkill: (index) => setState(() {
            _skills[index].dispose();
            _skills.removeAt(index);
          }),
          onRatingChanged: (index, rating) => setState(() => _skills[index].rating = rating),
          cvPicked: _cvPicked,
          onCvTap: () => setState(() => _cvPicked = !_cvPicked),
        );
      case 3:
        return StepFourDailyRate(
          key: const ValueKey('step-4'),
          rateController: _rateController,
          availability: _availability,
          onAvailabilityChanged: (value) => setState(() => _availability = value),
          selectedWorkModes: _workModes,
          onWorkModeToggled: (mode) => setState(() {
            if (_workModes.contains(mode)) {
              _workModes.remove(mode);
            } else {
              _workModes.add(mode);
            }
          }),
        );
      default:
        return StepFiveValidation(
          key: const ValueKey('step-5'),
          email: _emailController.text,
          photoPicked: _photoBytes != null,
          nom: _nomController.text,
          prenom: _prenomController.text,
          telephone: _telephoneController.text,
          localisation: _localisationController.text,
          titreProfessionnel: _titreProfessionnelController.text,
          presentation: _presentationController.text,
          skills: _skills,
          cvPicked: _cvPicked,
          rate: _rateController.text,
          availability: _availability,
          workModes: _workModes,
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
                      labels: _stepLabels,
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
