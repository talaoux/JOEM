/// Configuration du branchement sur l'API Laravel `joem_api`
/// (contrat : `joem_api/docs/CONTRAT_API.md`).
///
/// L'URL de base est fournie au lancement, jamais écrite en dur :
///
/// ```text
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.70:8000/api
/// ```
///
/// Sans `API_BASE_URL`, [ApiConfig.isEnabled] vaut `false` et l'application
/// fonctionne comme avant, 100% en local sur SQLite (tests compris).
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isEnabled => baseUrl.isNotEmpty;
}

/// Conversion du rôle entre la base locale (`job_seeker`) et l'API
/// (`candidate`) — seul endroit de l'application où les deux vocabulaires
/// se rencontrent (contrat §6).
abstract final class ApiRole {
  static const String localJobSeeker = 'job_seeker';
  static const String apiCandidate = 'candidate';

  static String toApi(String localRole) =>
      localRole == localJobSeeker ? apiCandidate : localRole;

  static String toLocal(String apiRole) =>
      apiRole == apiCandidate ? localJobSeeker : apiRole;
}
