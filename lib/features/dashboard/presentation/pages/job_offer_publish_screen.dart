import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joem/core/constants/job_categories.dart';
import 'package:joem/core/constants/malagasy_cities.dart';
import 'package:joem/core/services/auth_service.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/core/theme/app_spacing.dart';
import 'package:joem/core/theme/app_typography.dart';
import 'package:joem/core/widgets/light_text_field.dart';
import 'package:joem/core/widgets/location_autocomplete_field.dart';

import '../../data/job_offer_repository.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/offer_category_selector.dart';
import '../widgets/soft_ui.dart';
import 'candidate_search_screen.dart';
import 'employer_notifications_screen.dart';
import 'employer_profile_screen.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

const List<String> _contractTypes = ['CDI', 'CDD', 'Stage', 'Freelance'];

/// Création d'une vraie offre d'emploi — PAS un composeur de post social
/// (le candidat n'a plus de composeur de post social, voir `PortfolioScreen`) :
/// un formulaire recruteur avec
/// les champs qu'une offre requiert réellement (titre, description,
/// localisation, salaire, type de contrat). Persiste elle-même l'offre
/// (`JobOfferRepository.publish`) avant de se fermer, plutôt que de
/// renvoyer les champs bruts à l'appelant pour qu'il les enregistre : cet
/// écran est atteignable depuis la nav basse de plusieurs sous-écrans
/// (voir `BottomNavigation`), pas seulement depuis `EmployerDashboard`, qui
/// ne serait alors pas forcément l'écran qui récupère le résultat du
/// `Navigator.pop`.
///
/// Avec [offer], l'écran sert à modifier une offre déjà publiée (menu
/// "Modifier l'offre" de `EmployerOfferCard`) : champs préremplis, titre
/// "Modifier l'offre", bouton "Enregistrer", pas de nav basse, et
/// `JobOfferRepository.updateOffer` au lieu de `publish`. Renvoie l'offre
/// modifiée via `Navigator.pop`.
class JobOfferPublishScreen extends StatefulWidget {
  const JobOfferPublishScreen({super.key, this.offer});

  final JobOffer? offer;

  @override
  State<JobOfferPublishScreen> createState() => _JobOfferPublishScreenState();
}

class _JobOfferPublishScreenState extends State<JobOfferPublishScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();

  /// Secteur précisé quand "Autres" est coché (`job_offers.other_sector`) —
  /// obligatoire dans ce cas, ignoré sinon.
  final _otherSectorController = TextEditingController();
  String? _contractType;

  /// Catégories de l'offre (au moins une, parmi `kOfferCategories`) — l'offre
  /// apparaît côté candidat dans chacune (`CategoryOffersScreen`).
  /// Présélectionnée sur la catégorie de l'entreprise, le recruteur peut en
  /// ajouter ou en retirer.
  final Set<String> _categories = {};

  final _imagePicker = ImagePicker();
  Uint8List? _posterBytes;
  final AuthService _authService = AuthService();
  final JobOfferRepository _jobOfferRepository = const JobOfferRepository();
  bool _isPublishing = false;

  /// Pastille de la nav basse — même calcul que sur le dashboard.
  int _notificationCount = 0;

  int? get _employerUserId => int.tryParse(_authService.currentUser?.id ?? '');

  bool get _isEditing => widget.offer != null;

  /// En édition, `false` tant que les catégories actuelles de l'offre ne
  /// sont pas chargées (le bouton reste désactivé pendant ce temps).
  bool _categoriesLoaded = true;

  @override
  void initState() {
    super.initState();
    final offer = widget.offer;
    if (offer != null) {
      _titleController.text = offer.title;
      _descriptionController.text = offer.description;
      _locationController.text = offer.location;
      // "À négocier" est la valeur enregistrée quand le champ est laissé vide.
      if (offer.salary != 'À négocier') _salaryController.text = offer.salary;
      if (_contractTypes.contains(offer.contractType)) _contractType = offer.contractType;
      _posterBytes = offer.posterImage;
      _otherSectorController.text = offer.otherSector ?? '';
      _categoriesLoaded = false;
      _loadOfferCategories(offer.id);
    } else {
      _addCompanyCategory();
      _loadNotificationCount();
    }
    for (final controller in [
      _titleController,
      _descriptionController,
      _locationController,
      _otherSectorController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _addCompanyCategory() {
    final companyCategory = _authService.currentUser?.categorieEntreprise;
    if (companyCategory != null && kJobCategories.contains(companyCategory)) {
      _categories.add(companyCategory);
    }
  }

  /// Catégories actuelles de l'offre modifiée ; une offre antérieure à la
  /// migration v28 (aucune catégorie propre) part de la catégorie de
  /// l'entreprise — celle sous laquelle elle apparaît aujourd'hui.
  Future<void> _loadOfferCategories(int offerId) async {
    final categories = await _jobOfferRepository.fetchCategoriesForOffer(offerId);
    if (!mounted) return;
    setState(() {
      if (categories.isNotEmpty) {
        _categories.addAll(categories);
      } else {
        _addCompanyCategory();
      }
      _categoriesLoaded = true;
    });
  }

  Future<void> _loadNotificationCount() async {
    final employerUserId = _employerUserId;
    if (employerUserId == null) return;
    if (_authService.currentUser?.notificationsEnabled == false) {
      if (!mounted) return;
      setState(() => _notificationCount = 0);
      return;
    }
    final count = await _jobOfferRepository
        .countUnreadApplicationNotificationsForEmployer(employerUserId);
    if (!mounted) return;
    setState(() => _notificationCount = count);
  }

  /// Navigation de la barre basse : remplace l'écran courant par l'écran
  /// cible (comportement d'onglets, pas d'empilement) ou revient au
  /// dashboard ("Accueil", toujours la racine de la pile de navigation
  /// après connexion). Comme `_publish` persiste elle-même l'offre avant de
  /// fermer l'écran (voir sa doc), changer d'onglet sans publier équivaut
  /// simplement à annuler le formulaire — aucune perte de données.
  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    late final Widget screen;
    switch (index) {
      case 1:
        screen = const CandidateSearchScreen();
        break;
      case 3:
        screen = const EmployerNotificationsScreen();
        break;
      default:
        screen = const EmployerProfileScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

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

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _otherSectorController.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      !_isPublishing &&
      _categoriesLoaded &&
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      _contractType != null &&
      _categories.isNotEmpty &&
      (!_isOtherSelected || _otherSectorController.text.trim().isNotEmpty);

  bool get _isOtherSelected => _categories.contains(kOtherJobCategory);

  /// Persiste directement l'offre (`JobOfferRepository.publish` — l'id et
  /// l'heure de publication sont attribués par le dépôt) puis referme
  /// l'écran, plutôt que de renvoyer les champs bruts à un appelant qui
  /// pourrait ne pas être `EmployerDashboard` (voir doc de la classe).
  Future<void> _publish() async {
    if (!_canPublish || _isPublishing) return;
    setState(() => _isPublishing = true);

    final salary = _salaryController.text.trim().isNotEmpty
        ? _salaryController.text.trim()
        : 'À négocier';
    // Ordre de `kOfferCategories`, pas l'ordre de sélection.
    final categories = kOfferCategories.where(_categories.contains).toList();
    final otherSector = _isOtherSelected ? _otherSectorController.text.trim() : null;

    final editedOffer = widget.offer;
    if (editedOffer != null) {
      final updated = await _jobOfferRepository.updateOffer(
        offer: editedOffer,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        salary: salary,
        contractType: _contractType!,
        posterImage: _posterBytes,
        categories: categories,
        otherSector: otherSector,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offre "${updated.title}" modifiée.')),
      );
      return;
    }

    final employerUserId = int.tryParse(_authService.currentUser?.id ?? '') ?? 0;
    final offer = await _jobOfferRepository.publish(
      employerUserId: employerUserId,
      companyName: _authService.currentUser?.companyName ?? '',
      companyLogo: _authService.currentUser?.photoBytes,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      salary: salary,
      contractType: _contractType!,
      posterImage: _posterBytes,
      categories: categories,
      otherSector: otherSector,
    );
    if (!mounted) return;

    Navigator.pop(context, offer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Offre "${offer.title}" publiée avec succès.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSurfaceColors.of(context);
    return Scaffold(
      backgroundColor: SoftUi.pageBackground(colors),
      appBar: SoftAppBar(
        title: _isEditing ? 'Modifier l\'offre' : 'Publier une offre',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: SoftPillButton(
                label: _isEditing ? 'Enregistrer' : 'Publier',
                compact: true,
                onPressed: _canPublish ? _publish : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.safeAreaHorizontal,
            AppSpacing.sm,
            AppSpacing.safeAreaHorizontal,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte formulaire, façon carte "Type de message" de la
              // maquette : sélecteur segmenté en tête, puis les champs.
              SoftCard(
                padding: const EdgeInsets.all(18),
                radius: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: staggered([
                    Text(
                      'Type de contrat',
                      style: AppTypography.interSemiBold.copyWith(
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildContractSelector(colors),
                    const SizedBox(height: AppSpacing.lg),
                    const SerifSectionTitle('Quel poste proposez-vous ?', fontSize: 20),
                    const SizedBox(height: 4),
                    Text(
                      'Titre, missions, lieu... une offre claire attire de meilleurs profils.',
                      style: AppTypography.interRegular.copyWith(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LightTextField(
                      accentColor: DashboardColors.accent,
                      label: 'Titre du poste',
                      hint: 'Ex : Développeur Flutter',
                      icon: Icons.work_outline_rounded,
                      controller: _titleController,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LightTextField(
                      accentColor: DashboardColors.accent,
                      label: 'Description',
                      hint: 'Décrivez les missions, le profil recherché...',
                      icon: Icons.notes_rounded,
                      controller: _descriptionController,
                      maxLines: 5,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LocationAutocompleteField(
                      accentColor: DashboardColors.accent,
                      hint: 'Ex : Antananarivo',
                      controller: _locationController,
                      options: kMalagasyCities,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LightTextField(
                      accentColor: DashboardColors.accent,
                      label: 'Salaire (optionnel)',
                      hint: 'Ex : 2 500 000 Ar',
                      icon: Icons.payments_outlined,
                      controller: _salaryController,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OfferCategorySelector(
                      selected: _categories,
                      onToggle: (category) => setState(() {
                        if (!_categories.remove(category)) _categories.add(category);
                      }),
                    ),
                    SmoothSwitcher(
                      child: _isOtherSelected
                          ? Column(
                              key: const ValueKey('other-sector'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                      const SizedBox(height: AppSpacing.md),
                      LightTextField(
                        accentColor: DashboardColors.accent,
                        label: 'Précisez le secteur',
                        hint: 'Ex : Aéronautique',
                        icon: Icons.edit_note_rounded,
                        controller: _otherSectorController,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Affiché aux candidats sur votre offre, rangée dans « Autres ».',
                        style: AppTypography.interRegular.copyWith(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Affiche de l\'offre (optionnel)',
                      style: AppTypography.interMedium.copyWith(
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPosterPicker(colors),
                    const SizedBox(height: AppSpacing.xl),
                    SoftPrimaryButton(
                      label: _isEditing ? 'Enregistrer les modifications' : 'Publier l\'offre',
                      icon: _isEditing ? Icons.check_rounded : Icons.send_rounded,
                      loading: _isPublishing,
                      onPressed: _canPublish ? _publish : null,
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  _isEditing
                      ? 'Les candidatures déjà reçues sont conservées'
                      : 'Visible par tous les candidats inscrits · Supprimable à tout moment',
                  textAlign: TextAlign.center,
                  style: AppTypography.interRegular.copyWith(
                    fontSize: 12,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isEditing
          ? null
          : BottomNavigation(
        currentIndex: 2,
        onTap: _onNavTap,
        secondItemIcon: Icons.search_rounded,
        secondItemLabel: 'Recherche',
        notificationCount: _notificationCount,
        accentColor: DashboardColors.accent,
        softHomeButton: true,
      ),
    );
  }

  /// Sélecteur segmenté du type de contrat — même principe que les
  /// boutons "Plainte / Suggestion / Compliment" de la maquette : l'option
  /// choisie passe en bordure + fond violets, les autres restent neutres.
  Widget _buildContractSelector(AppSurfaceColors colors) {
    return Row(
      children: [
        for (var i = 0; i < _contractTypes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildContractOption(colors, _contractTypes[i])),
        ],
      ],
    );
  }

  Widget _buildContractOption(AppSurfaceColors colors, String type) {
    final selected = _contractType == type;
    final ink = SoftUi.brandInk(colors);
    return Material(
      color: selected
          ? SoftUi.tint(colors, DashboardColors.accent)
          : (SoftUi.isDark(colors) ? colors.surface : DashboardColors.segment),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? ink : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _contractType = type),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                _contractIcon(type),
                size: 20,
                color: selected ? ink : colors.textSecondary,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type,
                  style: AppTypography.interSemiBold.copyWith(
                    fontSize: 13,
                    color: selected ? ink : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _contractIcon(String type) {
    switch (type) {
      case 'CDI':
        return Icons.verified_outlined;
      case 'CDD':
        return Icons.event_outlined;
      case 'Stage':
        return Icons.school_outlined;
      default:
        return Icons.laptop_mac_outlined;
    }
  }

  /// Aperçu/sélecteur de l'affiche jointe à l'offre — image affichée sous la
  /// description sur la carte façon post du dashboard candidat (voir
  /// `JobOfferPostCard`), reste `null` si le recruteur n'en ajoute pas.
  Widget _buildPosterPicker(AppSurfaceColors colors) {
    if (_posterBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
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

    return Material(
      color: SoftUi.isDark(colors)
          ? colors.surface
          : DashboardColors.accent.withValues(alpha: 0.035),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickPoster,
        child: SizedBox(
          width: double.infinity,
          height: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: SoftUi.brandInk(colors),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                'Ajouter une affiche',
                style: AppTypography.interRegular.copyWith(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
