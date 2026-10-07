/// Décide si une offre publiée convient au profil d'un candidat, c'est-à-dire
/// si elle mérite une notification "Nouvelle offre". Toutes les offres restent
/// affichées dans le fil de tous les candidats : seule la notification est
/// filtrée.
///
/// Règle : un mot significatif de l'intitulé de l'offre correspond à un mot du
/// titre professionnel ou d'une compétence du candidat. Accents et majuscules
/// ignorés, formes proches rapprochées (développeur / développeuse,
/// comptable / comptabilité). Un candidat sans titre ni compétence ne reçoit
/// aucune notification d'offre.
///
/// Miroir de `joem_api/app/Services/OfferMatcher.php` (mode API) : garder les
/// deux identiques.
abstract final class OfferMatcher {
  /// Mots trop courants dans les intitulés pour dire quoi que ce soit du poste.
  static const _stopWords = {
    'de', 'du', 'des', 'la', 'le', 'les', 'un', 'une', 'et', 'ou', 'en', 'au', 'aux', 'a', 'l', 'd',
    'pour', 'par', 'avec', 'dans', 'sur', 'chez', 'the', 'and', 'of', 'for', 'in',
    'h', 'f', 'hf', 'junior', 'senior', 'confirme', 'confirmee', 'experimente', 'experimentee',
    'stagiaire', 'stage', 'alternance', 'alternant', 'poste', 'offre', 'emploi', 'cdi', 'cdd',
    'freelance', 'temps', 'plein', 'partiel', 'mission', 'profil', 'recherche', 'recrute', 'urgent',
    'madagascar', 'charge', 'chargee', 'agent', 'assistant', 'assistante',
  };

  /// Plus court préfixe commun pour que deux mots différents comptent comme
  /// le même mot.
  static const _minPrefix = 5;

  static const _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ç': 'c', 'ñ': 'n', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
  };

  /// Mots significatifs du titre professionnel et des compétences.
  static Set<String> candidateKeywords(String? title, Iterable<String> skills) => {
        ...keywords(title ?? ''),
        for (final skill in skills) ...keywords(skill),
      };

  /// [candidateKeywords] vient de [OfferMatcher.candidateKeywords].
  static bool matches(String offerTitle, Set<String> candidateKeywords) {
    if (candidateKeywords.isEmpty) return false;
    for (final offerWord in keywords(offerTitle)) {
      for (final candidateWord in candidateKeywords) {
        if (_similar(offerWord, candidateWord)) return true;
      }
    }
    return false;
  }

  static Set<String> keywords(String text) {
    final folded = text.toLowerCase().split('').map((c) => _accents[c] ?? c).join();
    return folded
        .split(RegExp(r'[^a-z0-9+#]+'))
        .where((w) => w.length >= 2 && !_stopWords.contains(w))
        .toSet();
  }

  static bool _similar(String a, String b) {
    if (a == b) return true;
    final shortest = a.length < b.length ? a.length : b.length;
    if (shortest < _minPrefix) return false;
    var prefix = 0;
    while (prefix < shortest && a.codeUnitAt(prefix) == b.codeUnitAt(prefix)) {
      prefix++;
    }
    final needed = shortest - 3 > _minPrefix ? shortest - 3 : _minPrefix;
    return prefix >= needed;
  }
}
