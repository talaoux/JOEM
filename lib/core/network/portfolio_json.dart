import 'package:joem/core/services/auth_service.dart'
    show Certification, Formation, JobExperience, PortfolioProject, ProfessionalLink;

import 'remote_images.dart';

/// Horodatage ISO 8601 UTC de l'API (contrat §7), en heure locale.
DateTime parseApiDateTime(Object? value) =>
    (value is String ? DateTime.tryParse(value)?.toLocal() : null) ?? DateTime.now();

DateTime? parseOptionalApiDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

List<Map<String, dynamic>> jsonList(Object? value) =>
    value is List ? value.cast<Map<String, dynamic>>() : const [];

JobExperience experienceFromJson(Map<String, dynamic> json) => JobExperience(
      id: json['id'] as int,
      poste: json['poste'] as String,
      entreprise: json['entreprise'] as String,
      dateDebut: json['date_debut'] as String? ?? '',
      dateFin: json['date_fin'] as String?,
      enCours: json['en_cours'] as bool? ?? false,
      description: json['description'] as String?,
    );

Future<PortfolioProject> portfolioProjectFromJson(Map<String, dynamic> json) async => PortfolioProject(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      link: json['link'] as String?,
      imageBytes: await RemoteImages.load(json['image_url']),
      createdAt: parseApiDateTime(json['created_at']),
      role: json['role'] as String?,
      technologies: [for (final item in json['technologies'] as List? ?? const []) item as String],
      features: [for (final item in json['features'] as List? ?? const []) item as String],
      githubLink: json['github_link'] as String?,
      demoLink: json['demo_link'] as String?,
    );

Formation formationFromJson(Map<String, dynamic> json) => Formation(
      id: json['id'] as int,
      etablissement: json['etablissement'] as String,
      filiere: json['filiere'] as String?,
      dateDebut: json['date_debut'] as String? ?? '',
      dateFin: json['date_fin'] as String?,
    );

Future<Certification> certificationFromJson(Map<String, dynamic> json) async => Certification(
      id: json['id'] as int,
      name: json['name'] as String,
      organism: json['organism'] as String?,
      date: json['date'] as String?,
      imageBytes: await RemoteImages.load(json['image_url']),
      verificationLink: json['verification_link'] as String?,
    );

ProfessionalLink professionalLinkFromJson(Map<String, dynamic> json) => ProfessionalLink(
      id: json['id'] as int,
      label: json['label'] as String,
      url: json['url'] as String,
    );
