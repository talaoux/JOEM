import 'package:flutter/material.dart';

import 'package:joem/core/constants/job_categories.dart';
import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_radius.dart';
import 'package:joem/core/theme/app_shadows.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Modifier le profil', style: AppTypography.dashboardTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.safeAreaHorizontal),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: 'Identité',
                children: [
                  _TwoColumnRow(
                    left: LightTextField(
                      label: 'Prénom',
                      hint: 'Jean',
                      icon: Icons.person_outline_rounded,
                      controller: _prenomController,
                    ),
                    right: LightTextField(
                      label: 'Nom',
                      hint: 'Dupont',
                      icon: Icons.person_outline_rounded,
                      controller: _nomController,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LightTextField(
                    label: 'Nom de l\'entreprise',
                    hint: 'Ex: Tech Solutions',
                    icon: Icons.business_rounded,
                    controller: _entrepriseController,
                  ),
                  const SizedBox(height: 18),
                  LightDropdown(
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
                    label: 'Téléphone',
                    hint: '+261 XX XX XXX XX',
                    icon: Icons.call_rounded,
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  LocationAutocompleteField(
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
                    label: 'Description',
                    hint: 'Décrivez votre entreprise et vos besoins',
                    icon: Icons.notes_rounded,
                    controller: _presentationController,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isValid && !_isSaving) ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnboardingColors.violet,
                    disabledBackgroundColor: OnboardingColors.violet.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
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
