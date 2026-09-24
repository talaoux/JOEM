import 'package:flutter/material.dart';

import 'package:joem/core/constants/job_categories.dart';
import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';
import 'package:joem/features/dashboard/presentation/widgets/soft_ui.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// Écran "Modifier le profil" — ouvert depuis l'icône stylo de
/// `EmployerProfileScreen`, équivalent recruteur de
/// `EditJobSeekerProfileScreen`. Champs réels (ceux collectés à
/// l'inscription, plus modifiables ici) : identité du recruteur, nom de
/// l'entreprise, coordonnées, description. Aucune donnée simulée : toute
/// modification est persistée via `AuthService.updateEmployerProfile` et se
/// reflète immédiatement dans la carte "Profil complété".
class EditEmployerProfileScreen extends StatefulWidget {
  const EditEmployerProfileScreen({super.key});

  @override
  State<EditEmployerProfileScreen> createState() => _EditEmployerProfileScreenState();
}

class _EditEmployerProfileScreenState extends State<EditEmployerProfileScreen> {
  final AuthService _authService = AuthService();

  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _entrepriseController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _localisationController;
  late final TextEditingController _presentationController;
  String? _categorieEntreprise;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _prenomController = TextEditingController(text: user?.firstName ?? '');
    _nomController = TextEditingController(text: user?.lastName ?? '');
    _entrepriseController = TextEditingController(text: user?.companyName ?? '');
    _telephoneController = TextEditingController(text: user?.telephone ?? '');
    _localisationController = TextEditingController(text: user?.localisation ?? '');
    _presentationController = TextEditingController(text: user?.presentation ?? '');
    _categorieEntreprise = user?.categorieEntreprise;

    _prenomController.addListener(_onFieldChanged);
    _nomController.addListener(_onFieldChanged);
    _entrepriseController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _entrepriseController.dispose();
    _telephoneController.dispose();
    _localisationController.dispose();
    _presentationController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _prenomController.text.trim().isNotEmpty &&
      _nomController.text.trim().isNotEmpty &&
      _entrepriseController.text.trim().isNotEmpty &&
      _categorieEntreprise != null;

  Future<void> _save() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);

    await _authService.updateEmployerProfile(
      firstName: _prenomController.text.trim(),
      lastName: _nomController.text.trim(),
      companyName: _entrepriseController.text.trim(),
      categorieEntreprise: _categorieEntreprise,
      telephone: _telephoneController.text.trim(),
      localisation: _localisationController.text.trim(),
      presentation: _presentationController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(AppSurfaceColors.of(context)),
      appBar: const SoftAppBar(title: 'Modifier le profil'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              _buildCard(
                title: 'Identité',
                children: [
                  _TwoColumnRow(
                    left: LightTextField(
                      accentColor: DashboardColors.accent,
                      label: 'Prénom',
                      hint: 'Jean',
                      icon: Icons.person_outline_rounded,
                      controller: _prenomController,
                    ),
                    right: LightTextField(
                      accentColor: DashboardColors.accent,
                      label: 'Nom',
                      hint: 'Dupont',
                      icon: Icons.person_outline_rounded,
                      controller: _nomController,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Nom de l\'entreprise',
                    hint: 'Ex: Tech Solutions',
                    icon: Icons.business_rounded,
                    controller: _entrepriseController,
                  ),
                  const SizedBox(height: 18),
                  LightDropdown(
                    accentColor: DashboardColors.accent,
                    label: 'Catégorie d\'entreprise',
                    hint: 'Sélectionnez un secteur d\'activité',
                    icon: Icons.category_outlined,
                    options: kJobCategories,
                    value: _categorieEntreprise,
                    onChanged: (value) => setState(() => _categorieEntreprise = value),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildCard(
                title: 'Coordonnées',
                children: [
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Téléphone',
                    hint: '+261 XX XX XXX XX',
                    icon: Icons.call_rounded,
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  LocationAutocompleteField(
                    accentColor: DashboardColors.accent,
                    controller: _localisationController,
                    options: kMalagasyCities,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildCard(
                title: 'À propos de l\'entreprise',
                children: [
                  LightTextField(
                    accentColor: DashboardColors.accent,
                    label: 'Description',
                    hint: 'Décrivez votre entreprise et vos besoins',
                    icon: Icons.notes_rounded,
                    controller: _presentationController,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              SoftPrimaryButton(
                label: 'Enregistrer',
                icon: Icons.check_rounded,
                loading: _isSaving,
                onPressed: _isValid ? _save : null,
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return SizedBox(
      width: double.infinity,
      child: SoftSection(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  static const double _breakpoint = 340;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 18),
            right,
          ],
        );
      },
    );
  }
}
