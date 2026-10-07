import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_durations.dart';
import 'package:joem/core/utils/cv_storage.dart';
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
import 'package:joem/core/widgets/animated_entrance.dart';

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

  /// Sens de la dernière navigation entre étapes (1 = suivante, -1 =
  /// précédente) — oriente le glissement de la transition.
  int _stepDirection = 1;

  // Étape 1 — Compte
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _googleAccountCreated = false;

  /// Jeton Google transmis au serveur à l'inscription (voir
  /// `googleIdToken` des données d'inscription).
  String? _googleIdToken;

  /// E-mail du compte Google choisi. Le serveur crée le compte avec l'e-mail
  /// du jeton Google, pas avec celui du champ : dès que l'utilisateur
  /// modifie le champ e-mail, l'inscription redevient classique (mot de
  /// passe obligatoire) au lieu de renvoyer indéfiniment l'e-mail Google.
  String? _googleEmail;

  bool get _usesGoogleAccount =>
      _googleAccountCreated &&
      _googleEmail != null &&
      _emailController.text.trim().toLowerCase() == _googleEmail;

  void _forgetGoogleAccount() {
    _googleAccountCreated = false;
    _googleIdToken = null;
    _googleEmail = null;
  }

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
  String? _cvPath;
  String? _cvFileName;

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

  Future<void> _pickCv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    final path = await saveCvFile(file.bytes!, file.name);
    if (!mounted) return;
    setState(() {
      _cvPath = path;
      _cvFileName = file.name;
    });
  }

  /// L'étape 1 est valide si le compte a été créé via Google, ou si les 3
  /// champs (email, mot de passe, confirmation) sont tous remplis, que
  /// l'email a un format plausible, que le mot de passe fait au moins
  /// `kMinPasswordLength` caractères, et que les deux mots de passe
  /// correspondent.
  bool get _isStepOneValid =>
      _usesGoogleAccount ||
      (_emailController.text.trim().isNotEmpty &&
          isPlausibleEmail(_emailController.text) &&
          isPasswordLongEnough(_passwordController.text) &&
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
    setState(() {
      _stepDirection = -1;
      _currentStep -= 1;
    });
  }

  void _goToNextStep() {
    if (_currentStep == _totalSteps - 1) {
      _submitRegistration();
      return;
    }
    setState(() {
      _stepDirection = 1;
      _currentStep += 1;
    });
  }

  /// Persiste les données saisies dans les 4 étapes précédentes (voir
  /// `JobSeekerRepository`/`AppDatabase`), puis ouvre directement une
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
        : 'candidat.$uniqueSuffix@google.joem';
    final usesGoogle = _usesGoogleAccount;
    final password = !usesGoogle || _passwordController.text.isNotEmpty
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
          googleIdToken: usesGoogle ? _googleIdToken : null,
          nom: nom,
          prenom: prenom,
          telephone: _telephoneController.text.trim(),
          localisation: _localisationController.text.trim(),
          titreProfessionnel: _titreProfessionnelController.text.trim(),
          presentation: _presentationController.text.trim(),
          photoBytes: _photoBytes,
          skills: skills,
          cvPath: _cvPath,
          cvFileName: _cvFileName,
          tarifJournalier: _rateController.text.trim(),
          disponibilite: _availability,
          workModes: _workModes.map((mode) => mode.name).toList(),
        ),
      );

      if (!mounted) return;

      await AuthService().setSession(
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
          cvPath: _cvPath,
          cvFileName: _cvFileName,
          tarifJournalier: _rateController.text.trim(),
          disponibilite: _availability,
          skills: skills.map((skill) => skill.name).toList(),
          workModes: _workModes.map((mode) => mode.name).toList(),
        ),
      );

      if (!mounted) return;

      // Le dashboard devient la racine : un retour depuis "Accueil" quitte
      // l'application au lieu de revenir à Welcome.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const JobSeekerDashboard()),
        (route) => false,
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
    } on ApiException catch (error) {
      // Refus du serveur JOEM (e-mail déjà pris, mot de passe trop court…)
      // ou serveur injoignable : son message est déjà rédigé pour
      // l'utilisateur. Une erreur sur l'e-mail ou le mot de passe renvoie
      // à l'étape "Compte" pour la corriger.
      if (!mounted) return;
      final isGoogleError = error.errors.containsKey('google_id_token');
      final isAccountError =
          isGoogleError || error.errors.containsKey('email') || error.errors.containsKey('password');
      setState(() {
        if (isAccountError) _currentStep = 0;
        // Jeton Google expiré ou refusé : il faut repasser par Google (ou
        // choisir un mot de passe).
        // Jeton refusé, ou e-mail Google déjà inscrit : l'utilisateur doit
        // pouvoir saisir un autre e-mail et un mot de passe.
        if (isGoogleError || (usesGoogle && error.errors.containsKey('email'))) {
          _forgetGoogleAccount();
        }
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.displayMessage),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } catch (error, stackTrace) {
      // La cause réelle était avalée silencieusement (`catch (_)`), ce qui
      // rendait ce message générique impossible à diagnostiquer — voir
      // stdout/les logs de l'appareil en cas de nouvelle occurrence.
      debugPrint('JobSeekerRegistrationScreen._submitRegistration failed: $error\n$stackTrace');
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
            _googleIdToken = account.authentication.idToken;
            _googleEmail = account.email.trim().toLowerCase();
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
          cvFileName: _cvFileName,
          onCvTap: _pickCv,
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
          cvFileName: _cvFileName,
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
                  children: staggered([
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
                          // Étape suivante : arrive par la droite ; étape
                          // précédente : par la gauche. La hauteur de la carte
                          // s'ajuste en douceur d'une étape à l'autre.
                          AnimatedSize(
                            duration: Motion.of(AppDurations.stepTransition),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: Motion.of(AppDurations.stepTransition),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topLeft,
                                children: [...previous, if (current != null) current],
                              ),
                              transitionBuilder: (child, animation) {
                                final isIncoming = child.key == ValueKey(_currentStep);
                                final dx = (isIncoming ? 0.08 : -0.08) * _stepDirection;
                                final slide = Tween<Offset>(
                                  begin: Offset(dx, 0),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(position: slide, child: child),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(_currentStep),
                                child: _buildStepContent(_currentStep),
                              ),
                            ),
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
                  ]),
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
