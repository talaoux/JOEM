/// Catégories d'entreprise/métier proposées à l'inscription recruteur
/// (`StepTwoPersonalInfo`, catégorie obligatoire) et utilisées côté
/// candidat pour filtrer les offres par secteur (`JobCategoriesScreen`,
/// grille "Catégories populaires" du dashboard) — une seule liste
/// partagée pour que les deux bouts se comprennent.
const List<String> kJobCategories = [
  'Informatique',
  'Commerce',
  'Santé',
  'BTP',
  'Finance',
  'Marketing',
  'Education',
  'Industrie',
  'Transport',
  'Tourisme',
  'Agriculture',
  'Juridique',
  'Ressources Humaines',
  'Communication',
  'Artisanat',
  'Sécurité',
  'Restauration',
  'Textile',
  'Logistique',
  'Télécommunications',
  'Mines & Énergie',
  "BPO & Centres d'appels",
  'ONG & Humanitaire',
  'Immobilier',
];

/// Catégorie "fourre-tout" d'une offre, quand aucun secteur de
/// [kJobCategories] ne correspond — volontairement hors de [kJobCategories]
/// (pas proposée comme catégorie d'entreprise à l'inscription recruteur).
/// Une offre rangée dans "Autres" porte un secteur précisé par le recruteur
/// (`job_offers.other_sector`), affiché au candidat (voir [offerCategoryLabel]).
const String kOtherJobCategory = 'Autres';

/// Catégories proposées pour une offre : [kJobCategories] puis "Autres".
const List<String> kOfferCategories = [...kJobCategories, kOtherJobCategory];

/// Libellé affiché pour une catégorie d'offre : "Autres · Logistique" si
/// l'offre est rangée dans "Autres" avec un secteur précisé, sinon la
/// catégorie telle quelle.
String offerCategoryLabel(String category, String? otherSector) {
  final sector = otherSector?.trim() ?? '';
  if (category == kOtherJobCategory && sector.isNotEmpty) {
    return '$kOtherJobCategory · $sector';
  }
  return category;
}