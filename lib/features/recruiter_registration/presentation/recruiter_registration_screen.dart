import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_durations.dart';
import 'package:joem/core/widgets/centered_logo.dart';
import 'package:joem/core/widgets/form_surface.dart';
import 'package:joem/core/widgets/registration_stepper.dart';
import 'package:joem/core/widgets/step_one_account.dart';
import 'package:joem/core/widgets/wizard_navigation.dart';

import 'widgets/step_three_validation.dart';
import 'widgets/step_two_personal_info.dart';

/// Écran "Inscription Recruteur" : un wizard à 3 étapes (Compte, Info,
/// Validation) sur fond blanc, qui reste sur une seule page — les
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

  // Étape 2 — Info personnelle
  bool _logoPicked = false;
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  String? _localisation;
  final _nomEntrepriseController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _nomEntrepriseController.dispose();
    _descriptionController.dispose();
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
      // TODO: Soumission finale de l'inscription recruteur
      debugPrint('Création du compte recruteur');
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
          logoPicked: _logoPicked,
          onLogoTap: () => setState(() => _logoPicked = !_logoPicked),
          nomController: _nomController,
          prenomController: _prenomController,
          telephoneController: _telephoneController,
          localisation: _localisation,
          onLocalisationChanged: (value) => setState(() => _localisation = value),
          nomEntrepriseController: _nomEntrepriseController,
          descriptionController: _descriptionController,
        );
      default:
        return StepThreeValidation(
          key: const ValueKey('step-3'),
          email: _emailController.text,
          logoPicked: _logoPicked,
          nom: _nomController.text,
          prenom: _prenomController.text,
          telephone: _telephoneController.text,
          localisation: _localisation,
          nomEntreprise: _nomEntrepriseController.text,
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
                    const SizedBox(height: 32),
                    const CenteredLogo(),
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
    );
  }
}
