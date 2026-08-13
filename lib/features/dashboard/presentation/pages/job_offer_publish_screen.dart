import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/light_dropdown.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';
import 'package:joem/features/welcome/presentation/welcome_palette.dart';

const List<String> _contractTypes = ['CDI', 'CDD', 'Stage', 'Freelance'];

/// Création d'une vraie offre d'emploi — PAS un composeur de post social
/// (voir `JobPublishScreen`, côté candidat) : un formulaire recruteur avec
/// les champs qu'une offre requiert réellement (titre, description,
/// localisation, salaire, type de contrat). À la soumission, renvoie les
/// données à l'appelant via `Navigator.pop` pour qu'elles rejoignent "Mes
/// offres" sur `EmployerDashboard`.
class JobOfferPublishScreen extends StatefulWidget {
  const JobOfferPublishScreen({super.key});

  @override
  State<JobOfferPublishScreen> createState() => _JobOfferPublishScreenState();
}

class _JobOfferPublishScreenState extends State<JobOfferPublishScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  String? _contractType;

  final _imagePicker = ImagePicker();
  Uint8List? _posterBytes;

  Future<void> _pickPoster() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _posterBytes = bytes);
  }

  void _removePoster() => setState(() => _posterBytes = null);

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _titleController,
      _descriptionController,
      _locationController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      _contractType != null;

  /// Renvoie les champs bruts du formulaire à l'appelant (`EmployerDashboard`),
  /// qui se charge de la persistance réelle via `JobOfferRepository` — l'id
  /// et l'heure de publication sont attribués par le dépôt, pas ici.
  void _publish() {
    if (!_canPublish) return;

    Navigator.pop(context, {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'salary': _salaryController.text.trim().isNotEmpty
          ? _salaryController.text.trim()
          : 'À négocier',
      'contractType': _contractType,
      'posterImage': _posterBytes,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
        title: Text('Publier une offre', style: AppTypography.sectionTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: TextButton(
                onPressed: _canPublish ? _publish : null,
                style: TextButton.styleFrom(
                  backgroundColor: _canPublish
                      ? OnboardingColors.violet
                      : const Color(0xFFE5E7EB),
                  foregroundColor: _canPublish ? Colors.white : const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Publier',
                  style: AppTypography.primaryButton.copyWith(fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.safeAreaHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LightTextField(
                label: 'Titre du poste',
                hint: 'Ex : Développeur Flutter',
                icon: Icons.work_outline_rounded,
                controller: _titleController,
              ),
              const SizedBox(height: AppSpacing.lg),
              LightTextField(
                label: 'Description',
                hint: 'Décrivez les missions, le profil recherché...',
                icon: Icons.notes_rounded,
                controller: _descriptionController,
                maxLines: 5,
              ),
              const SizedBox(height: AppSpacing.lg),
              LocationAutocompleteField(
                hint: 'Ex : Antananarivo',
                controller: _locationController,
                options: kMalagasyCities,
              ),
              const SizedBox(height: AppSpacing.lg),
              LightTextField(
                label: 'Salaire (optionnel)',
                hint: 'Ex : 2 500 000 Ar',
                icon: Icons.payments_outlined,
                controller: _salaryController,
              ),
              const SizedBox(height: AppSpacing.lg),
              LightDropdown(
                label: 'Type de contrat',
                hint: 'Sélectionnez un type de contrat',
                icon: Icons.description_outlined,
                options: _contractTypes,
                value: _contractType,
                onChanged: (value) => setState(() => _contractType = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Affiche de l\'offre (optionnel)',
                style: AppTypography.interMedium.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPosterPicker(),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canPublish ? _publish : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnboardingColors.violet,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Publier l\'offre',
                    style: AppTypography.primaryButton,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  /// Aperçu/sélecteur de l'affiche jointe à l'offre — image affichée sous la
  /// description sur la carte façon post du dashboard candidat (voir
  /// `JobOfferPostCard`), reste `null` si le recruteur n'en ajoute pas.
  Widget _buildPosterPicker() {
    if (_posterBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Image.memory(
              _posterBytes!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removePoster,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickPoster,
      child: Container(
        width: double.infinity,
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8D8E2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: OnboardingColors.violet,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              'Ajouter une affiche',
              style: AppTypography.jobInfo.copyWith(color: const Color(0xFFA6A6B4)),
            ),
          ],
        ),
      ),
    );
  }
}
