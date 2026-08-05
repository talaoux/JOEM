import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_durations.dart';
import 'package:joem/core/widgets/form_surface.dart';
import 'package:joem/core/widgets/joem_gradient_logo.dart';
import 'package:joem/core/widgets/registration_stepper.dart';
import 'package:joem/core/widgets/step_one_account.dart';
import 'package:joem/core/widgets/wizard_navigation.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

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

  // Étape 2 — Info personnelle
  bool _photoPicked = false;
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  String? _localisation;
  final _titreProfessionnelController = TextEditingController();
  final _presentationController = TextEditingController();

  // Étape 3 — Profil professionnel
  final List<SkillEntry> _skills = [SkillEntry()];
  bool _cvPicked = false;

  // Étape 4 — Tarif journalier
  final _rateController = TextEditingController();
  String? _availability;
  final Set<WorkMode> _workModes = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _titreProfessionnelController.dispose();
    _presentationController.dispose();
    for (final skill in _skills) {
      skill.dispose();
    }
    _rateController.dispose();
    super.dispose();
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
      // TODO: Soumission finale de l'inscription chercheur d'emploi
      debugPrint('Création du compte chercheur d\'emploi');
      return;
    }
    setState(() => _currentStep += 1);
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return StepOneAccount(
          key: const ValueKey('step-1'),
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
        );
      case 1:
        return StepTwoPersonalInfo(
          key: const ValueKey('step-2'),
          photoPicked: _photoPicked,
          onPhotoTap: () => setState(() => _photoPicked = !_photoPicked),
          nomController: _nomController,
          prenomController: _prenomController,
          telephoneController: _telephoneController,
          localisation: _localisation,
          onLocalisationChanged: (value) => setState(() => _localisation = value),
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
          photoPicked: _photoPicked,
          nom: _nomController.text,
          prenom: _prenomController.text,
          telephone: _telephoneController.text,
          localisation: _localisation,
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
                            onNext: _goToNextStep,
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
