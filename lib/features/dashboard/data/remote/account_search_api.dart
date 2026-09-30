import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/portfolio_json.dart';
import 'package:joem/core/network/remote_images.dart';
import 'package:joem/features/dashboard/data/account_search_repository.dart';

/// [AccountSearchRepository] quand l'application parle à l'API : un
/// recruteur trouve les candidats inscrits sur les autres téléphones, et
/// inversement.
class AccountSearchApi {
  const AccountSearchApi(this.client);

  final ApiClient client;

  Future<List<CandidateSearchResult>> searchJobSeekers(String query) async {
    final rows = await client.getAllPages('/search/candidates', query: {'q': query});
    return Future.wait(rows.map(candidateFromJson));
  }

  /// `GET /candidates/{id}` : compte aussi une vue du profil (contrat §12).
  Future<CandidateSearchResult?> fetchJobSeekerById(String userId) async {
    try {
      return candidateFromJson(await client.get('/candidates/$userId') as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<CompanySearchResult>> searchEmployers(String query) async {
    final rows = await client.getAllPages('/search/companies', query: {'q': query});
    return Future.wait(rows.map((row) => companyFromJson(row['id'] as int, row['employer_profile'] as Map<String, dynamic>)));
  }

  Future<List<String>> fetchHistory(String searchType) async =>
      [for (final query in await client.get('/search/history', query: {'type': searchType}) as List) query as String];

  Future<void> recordSearch(String searchType, String query) =>
      client.post('/search/history', body: {'type': searchType, 'query': query});

  Future<void> removeHistoryEntry(String searchType, String query) =>
      client.delete('/search/history', body: {'type': searchType, 'query': query});

  Future<void> clearHistory(String searchType) => client.delete('/search/history', body: {'type': searchType});

  /// Ouvrir le profil sur le serveur y enregistre la vue du recruteur.
  Future<void> recordProfileView(String profileUserId) async => fetchJobSeekerById(profileUserId);

  Future<int> countProfileViews() async => ((await client.get('/stats')) as Map<String, dynamic>)['profile_views_count'] as int? ?? 0;

  Future<List<ProfileViewer>> fetchProfileViewers() async {
    final rows = await client.getAllPages('/stats/profile-viewers');
    return Future.wait(rows.map((row) async {
      final profile = row['employer_profile'] as Map<String, dynamic>?;
      return ProfileViewer(
        viewedAt: parseApiDateTime(row['viewed_at']),
        company: profile == null ? null : await companyFromJson(row['viewer_user_id'] as int, profile),
      );
    }));
  }

  static Future<CandidateSearchResult> candidateFromJson(Map<String, dynamic> json) async {
    final profile = json['candidate_profile'] as Map<String, dynamic>;
    final photo = RemoteImages.load(profile['photo_url']);
    final projects = Future.wait(jsonList(json['portfolio_projects']).map(portfolioProjectFromJson));
    final certifications = Future.wait(jsonList(json['certifications']).map(certificationFromJson));

    return CandidateSearchResult(
      userId: (json['id'] as int).toString(),
      firstName: profile['prenom'] as String? ?? '',
      lastName: profile['nom'] as String? ?? '',
      position: profile['titre_professionnel'] as String?,
      localisation: profile['localisation'] as String?,
      telephone: profile['telephone'] as String?,
      presentation: profile['presentation'] as String?,
      photo: await photo,
      skills: [for (final skill in jsonList(json['skills'])) skill['name'] as String],
      experiences: [for (final row in jsonList(json['experiences'])) experienceFromJson(row)],
      portfolioProjects: await projects,
      objectifs: profile['objectifs'] as String?,
      formations: [for (final row in jsonList(json['formations'])) formationFromJson(row)],
      certifications: await certifications,
      professionalLinks: [for (final row in jsonList(json['professional_links'])) professionalLinkFromJson(row)],
      portfolioThemeColor: profile['portfolio_theme_color'] as String?,
    );
  }

  static Future<CompanySearchResult> companyFromJson(int userId, Map<String, dynamic> profile) async {
    final contactName = '${profile['prenom'] ?? ''} ${profile['nom'] ?? ''}'.trim();
    return CompanySearchResult(
      userId: userId.toString(),
      companyName: profile['nom_entreprise'] as String? ?? '',
      contactName: contactName.isEmpty ? null : contactName,
      localisation: profile['localisation'] as String?,
      telephone: profile['telephone'] as String?,
      description: profile['description'] as String?,
      logo: await RemoteImages.load(profile['logo_url']),
    );
  }
}
