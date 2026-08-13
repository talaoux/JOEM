




    
















# CLAUDE.md

Ce fichier fournit des indications à Claude Code (claude.ai/code) pour travailler sur le code de ce dépôt.

## Aperçu du projet

JOEM ("Job Offer & Employment Madagascar") est une application Flutter ciblant le marché de l'emploi malgache, mettant en relation recruteurs et chercheurs d'emploi. Le flux complet onboarding → inscription → connexion → dashboard est câblé de bout en bout, avec une vraie persistance locale (SQLite via `sqflite`/`sqflite_common_ffi`, voir `lib/core/database/app_database.dart` — comptes, offres, candidatures, notifications, historique de recherche : plus un simple mock en mémoire, mais toujours pas de vrai serveur/API distant). Pas de state management (pas de provider/riverpod/bloc), pas de routeur déclaratif — uniquement `Navigator.push`/`pushReplacement`. Certaines listes (statistiques, "Candidats suggérés", "Entretiens du jour"...) restent volontairement mockées en dur faute de fonctionnalité correspondante — voir "Ce qui reste à faire".

## Commandes

```bash
flutter pub get                     # installer les dépendances
flutter run                         # lancer sur un appareil/émulateur connecté
flutter run -d chrome                # lancer dans un navigateur (la cible web est configurée)
flutter test                        # lancer tous les tests
flutter test test/widget_test.dart  # lancer un seul fichier de test
flutter test --plain-name "Welcome screen loads"  # lancer un seul test par son nom
flutter analyze                     # analyse statique (utilise flutter_lints, voir analysis_options.yaml)
flutter build apk / ios / web       # builds par plateforme
```

Il n'y a pas de configuration CI, pas de règles de lint personnalisées au-delà de l'ensemble par défaut `flutter_lints`, et pas d'étape de génération de code (pas de `build_runner`). `pubspec.yaml` déclare, en plus de `cupertino_icons`/`google_fonts` : `image_picker` (photo de couverture/profil/logo — la couverture reste en mémoire via `Uint8List`/`MemoryImage`, non persistée ; l'avatar/logo, lui, est persisté, voir plus bas), `file_picker`/`open_file` (CV), et surtout `sqflite`/`sqflite_common_ffi`/`sqflite_common_ffi_web`/`sqlite3_flutter_libs`/`path`/`path_provider`/`crypto` — la vraie base SQLite locale (`lib/core/database/app_database.dart`, un seul fichier `joem.db`, migrations versionnées dans `onUpgrade`) qui persiste comptes, offres, candidatures, notifications et historique de recherche. Aucune lib de state management (provider/riverpod/bloc) ni de routeur (go_router) n'a été ajoutée. `image_picker` nécessite les entrées `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` dans `ios/Runner/Info.plist` (déjà ajoutées).

## Architecture

Le code suit une structure **feature-first** sous `lib/` :

- `lib/core/` — briques partagées entre toutes les fonctionnalités :
  - `theme/` — tokens de design : `app_colors.dart`, `app_spacing.dart`, `app_durations.dart`, `app_shadows.dart`, `app_radii.dart` / `app_radius.dart`, `app_text_styles.dart` / `app_typography.dart` (échelles Poppins/Inter via Google Fonts), et `app_theme.dart` (le `ThemeData` Material 3 global, toujours *non* appliqué — voir ci-dessous).
  - `widgets/` — composants partagés : `glass_container.dart`/`glass_button.dart` (verre dépoli — `GlassButton` accepte un paramètre optionnel `color` pour surcharger le mauve `AppColors.primary` par défaut ; login et les wizards d'inscription lui passent `OnboardingColors.violet`), le kit de formulaire clair (`form_surface.dart`, `light_text_field.dart`, `light_dropdown.dart`, `joem_gradient_logo.dart`, `google_sign_in_button.dart`, `or_divider.dart`), le kit d'inscription en wizard (`registration_stepper.dart`, `wizard_navigation.dart`, `step_one_account.dart`), le kit dashboard (`dashboard_card.dart`, `section_header.dart`, `advice_card.dart`, `mini_line_chart_painter.dart` — utilisés par la branche dashboard non branchée, qui ne compile plus, voir plus bas), `notification_badge.dart` (pastille rouge de compteur style Facebook, réutilisée par les headers et les nav basses des deux dashboards) et `profile_photo_viewer_screen.dart` (`ProfilePhotoViewerScreen` — visionneuse plein écran zoomable d'une photo, partagée par `JobProfileScreen` et `ProfileSidePanel`). `centered_logo.dart` (ancien wordmark en image PNG) a été supprimé, plus aucun écran ne l'important ; `joem_gradient_logo.dart` (`JoemGradientLogo`) le remplace partout — un texte "JOEM" au dégradé navy→violet (`ShaderMask` + Google Fonts Poppins), même identité que le bloc de marque du welcome screen.
  - `services/auth_service.dart` — service d'authentification utilisé par l'écran de connexion et les dashboards actuellement branchés (voir "Deux implémentations parallèles" ci-dessous) : 2 comptes de démo codés en dur, plus tout compte réellement inscrit via un wizard (`users`/`job_seeker_profiles`/`employer_profiles` dans `app_database.dart`, mot de passe hashé via `crypto`) — un compte créé via `RecruiterRegistrationScreen`/`JobSeekerRegistrationScreen` peut donc se reconnecter avec `LoginScreen`, contrairement à ce qu'une lecture rapide du code plus ancien pourrait laisser penser.
  - `database/app_database.dart` — base SQLite locale unique (`joem.db`, migrations versionnées dans `onUpgrade`, `sqflite`/`sqflite_common_ffi` selon la plateforme). Toutes les données réelles de l'app (comptes, offres, candidatures, notifications, historique de recherche) y vivent — voir "Ce qui est déjà fait" pour le détail par repository.
  - `constants/` — listes de référence partagées : `malagasy_cities.dart` (autocomplétion de localisation) et `job_categories.dart` (`kJobCategories`, les 18 secteurs proposés à l'inscription recruteur et réutilisés pour filtrer les offres côté candidat).
  - `utils/responsive.dart` — breakpoints partagés (`isTablet`/`isDesktop`).
- `lib/features/<feature>/presentation/` — chaque fonctionnalité possède ses écrans sous `presentation/` (sous-dossier `widgets/` pour les composants propres à l'écran). Fonctionnalités existantes : `welcome/`, `recruiter_registration/`, `job_seeker_registration/`, `login/`, `dashboard/`, `employer_dashboard/`, `job_seeker_dashboard/`.

Convention d'imports : dans les widgets propres à une fonctionnalité, les imports relatifs vers `core` sont parfois utilisés (ex. `../../../../core/theme/app_colors.dart`), parfois la forme absolue `package:joem/...` — les deux styles coexistent selon le fichier/la session qui l'a écrit.

### Point d'entrée et incohérence de thème

`lib/main.dart` construit toujours `MaterialApp` avec un `ThemeData` **inline** (sombre, Material 3, dérivé d'un `seedColor`) plutôt que d'utiliser `AppTheme.dark` défini dans `lib/core/theme/app_theme.dart`. `home` reste `WelcomeScreen`. Ce thème inline devrait, à terme, être remplacé par `AppTheme.dark` — toujours pas fait.

### Flux d'écrans (navigation câblée avec `Navigator.push`)

```
WelcomeScreen
 ├─ carte "Recruteur"        → RecruiterRegistrationScreen (wizard 3 étapes : Compte, Info, Validation)
 ├─ carte "Chercheur d'emploi" → JobSeekerRegistrationScreen (wizard 5 étapes : Compte, Info, Profil, Tarif, Validation)
 └─ footer "Se connecter"    → LoginScreen
                                 └─ soumission valide → EmployerDashboard ou JobSeekerDashboard
                                    (lib/features/dashboard/presentation/pages/, via AuthService.isEmployer()/isJobSeeker())
                                       ├─ (JobSeekerDashboard) menu bas → Navigator.push vers :
                                       │     ├─ JobCategoriesScreen (Recherche, index 1) → tap catégorie → CategoryOffersScreen
                                       │     ├─ JobPublishScreen (index 2)
                                       │     ├─ JobNotificationsScreen (Notifications, index 3)
                                       │     └─ JobProfileScreen (Profil, index 4) → icône stylo → EditJobSeekerProfileScreen
                                       │        (au retour, l'onglet actif redevient Accueil)
                                       │   header → icône notification → JobNotificationsScreen ;
                                       │   barre de recherche → JobSearchScreen (recherche réelle d'entreprises inscrites,
                                       │   voir "Recherche de comptes" plus bas) → tap résultat → CompanyProfileViewScreen
                                       │   sidebar (avatar header) → ProfileSidePanel → tap avatar → ProfilePhotoViewerScreen
                                       └─ (EmployerDashboard) menu bas → Navigator.push vers :
                                             ├─ CandidateSearchScreen (Recherche) → tap résultat → CandidateProfileViewScreen
                                             ├─ JobOfferPublishScreen (Publier une offre)
                                             ├─ EmployerNotificationsScreen (Notifications) → tap candidature → CandidateApplicationDetailScreen
                                             └─ EmployerProfileScreen (Profil) → icône stylo → EditEmployerProfileScreen
```

Les deux wizards d'inscription créent désormais un vrai compte utilisable : `LoginScreen` accepte aussi bien les comptes de démo codés en dur dans `AuthService` qu'un compte inscrit via `RecruiterRegistrationScreen`/`JobSeekerRegistrationScreen` (persisté en SQLite, voir "Deux implémentations parallèles" ci-dessous) — s'inscrire puis se reconnecter avec ce compte fonctionne.

Dans `JobSeekerDashboard`, seuls les items "Recherche" (index 1), "Publier" (index 2), "Notifications" (index 3) et "Profil" (index 4) du menu bas naviguent réellement (`Navigator.push` vers un écran dédié, `lib/features/dashboard/presentation/pages/`) ; "Accueil" et "Favoris" ne font que changer l'icône active sans changer le contenu affiché.

### Recherche de comptes et profils consultables (candidat ↔ recruteur)

`AccountSearchRepository` (`lib/features/dashboard/data/account_search_repository.dart`) fait une recherche réelle en base, jamais de données mockées : `searchJobSeekers`/`searchEmployers` interrogent `job_seeker_profiles`/`employer_profiles` (+ compétences/expériences pour un candidat), "Aucun résultat" si rien ne correspond. L'historique de recherche (`search_history`, propre à chaque utilisateur et type de recherche) est enregistré à la fois sur validation clavier (`onSubmitted`) et à l'ouverture d'un profil depuis les résultats — sans ce second point, une recherche jamais "validée" au clavier avant de cliquer un résultat ne laissait aucune trace.

- `CandidateSearchScreen` (recruteur cherche un candidat) et `JobSearchScreen` (candidat cherche une entreprise) partagent la même structure : barre de recherche + historique, résultats sous forme de cartes.
- Taper un résultat ouvre une vraie page de profil en lecture seule, pas une simple bottom sheet : `CandidateProfileViewScreen` (même identité visuelle que `JobProfileScreen` — bannière, avatar, "À propos", "Expérience", "Compétences", "Coordonnées") et `CompanyProfileViewScreen` (même identité que `EmployerProfileScreen`), tous deux dans `lib/features/dashboard/presentation/pages/`.

### Deux implémentations parallèles pour l'auth et les dashboards

Deux paires concurrentes coexistent, non harmonisées — à surveiller pour ne pas dupliquer le travail par erreur :

1. **Branche active (celle réellement utilisée par `LoginScreen`)**
   - Auth : `lib/core/services/auth_service.dart` — `AuthService extends ChangeNotifier`, singleton. 2 comptes de démo en dur (`employeur@gmail.com` / `candidat@gmail.com`, id négatif, aucune ligne dans `users`) + tout compte réellement inscrit (lu depuis SQLite). Méthodes `login()`, `logout()`, `restoreSession()` (reconnexion auto au démarrage), `isEmployer()`, `isJobSeeker()`, `setSession()` (ouvre une session juste après inscription), `updateProfilePhoto`/`updateCv`/`updateJobSeekerProfile`/`updateEmployerProfile`/`addExperience`/`deleteExperienceAt` (persistent les modifications faites depuis `JobProfileScreen`/`EmployerProfileScreen` et leurs écrans "Modifier le profil").
   - Dashboards : `lib/features/dashboard/presentation/pages/employer_dashboard.dart` et `job_seeker_dashboard.dart` (+ leurs widgets dans `lib/features/dashboard/presentation/widgets/`). Beaucoup de logique responsive ad hoc en dur dans l'écran (helpers `_isSmallScreen`/`_getStatCardAspectRatio`/etc.) plutôt que dans des widgets réutilisables.
   - Chaque dashboard a désormais son propre header/panneau latéral, plus aucun des deux n'utilise `dashboard_header.dart` (`DashboardHeader`) ni `greeting_section.dart` (`GreetingSection`) : `JobSeekerDashboard` utilise `job_seeker_header.dart` (`JobSeekerHeader` — barre de recherche + notification + avatar, sans logo ni texte de salutation) + `profile_side_panel.dart` (`ProfileSidePanel`) ; `EmployerDashboard` utilise `employer_header.dart` (`EmployerHeader` — barre de recherche de candidats + notification + logo) + `employer_profile_side_panel.dart` (`EmployerProfileSidePanel`). **`DashboardHeader`/`GreetingSection` sont donc orphelins** (plus importés nulle part) — à supprimer plutôt qu'à laisser traîner. `search_bar_widget.dart` (`SearchBarWidget`) reste partagé par tous ces headers/écrans de recherche (étendu avec `showFilterButton`, `onChanged`, `autofocus`, `readOnly`+`onTap` pour un champ non éditable qui ouvre un écran de recherche dédié).

2. **Branche non branchée (code présent mais jamais importé par un écran atteignable)**
   - Auth : `lib/features/login/data/mock_auth_service.dart` (+ `data/auth_exception.dart`, `domain/auth_user.dart`, `domain/user_role.dart`) — `MockAuthService`, un seul compte de test, exceptions typées (`AuthException`). Modèle plus propre (séparation data/domain) mais `LoginScreen` ne l'utilise pas.
   - Dashboards : `lib/features/employer_dashboard/presentation/employer_dashboard_screen.dart` et `lib/features/job_seeker_dashboard/presentation/job_seeker_dashboard_screen.dart` — reproduction fidèle de la maquette `maquette_employeur.png`, layout responsive large/étroit factorisé (`_buildWideLayout`/`_buildNarrowLayout`), réutilise les widgets partagés `core/widgets/` (`DashboardCard`, `SectionHeader`, `AdviceCard`). C'est cette implémentation que couvre `test/employer_dashboard_smoke_test.dart` — donc le seul test de dashboard existant teste un écran que l'utilisateur ne peut pas atteindre en lançant l'app.

**À trancher/harmoniser** : choisir laquelle des deux paires devient la version canonique (le second dashboard, plus propre et testé, est un bon candidat) et supprimer/rebrancher l'autre plutôt que de continuer à faire évoluer les deux en parallèle. Idem pour `app_text_styles.dart` vs `app_typography.dart` et `app_radii.dart` vs `app_radius.dart`, qui semblent être deux tentatives du même token de design.

**Nouveau doublon de palette à surveiller** : les dashboards restent sur `AppColors.primary` (mauve `0xFFA855F7`, `lib/core/theme/app_colors.dart`), tandis que login + les deux wizards d'inscription (et les widgets `core/widgets/` qu'ils partagent — `LightTextField`, `RegistrationStepper`, `WizardNavigation`, `StepOneAccount`, `JoemGradientLogo`, `GlassButton` via son paramètre `color`) utilisent désormais `OnboardingColors.violet`/`navy` (`lib/features/welcome/presentation/welcome_palette.dart`, la palette du welcome screen). Ces widgets `core/widgets/` importent donc un fichier de `features/welcome/` — dépendance inversée à noter si `OnboardingColors` est un jour déplacé/renommé. Les écrans dashboard eux-mêmes (`employer_dashboard.dart`/`job_seeker_dashboard.dart`) n'ont pas été retouchés (toujours `AppColors`), mais une bonne partie de leurs sous-écrans est déjà passée à `OnboardingColors.violet`/`lavender` (recherche de comptes, profils consultables, écrans "Modifier le profil", `JobProfileScreen`/`EmployerProfileScreen`) — le doublon de palette n'est donc plus limité à "login + wizards vs dashboards", il traverse désormais aussi les dashboards eux-mêmes selon l'écran.

### Écran d'accueil (welcome)

`lib/features/welcome/presentation/welcome_screen.dart` est un `StatefulWidget` avec un `AnimationController` (900ms, `easeOutCubic`) pilotant le fondu d'apparition du contenu. Fond en dégradé `OnboardingColors.bgTop → bgBottom` (défini dans `welcome_palette.dart`) avec des vagues violettes décoratives peintes en arrière-plan (`_BottomWavesPainter`). Layout à hauteur fixe, sans scroll, chaque bloc dimensionné en fraction de la hauteur disponible (`OnboardingLayout`) via `LayoutBuilder`, avec un facteur `scale` global (borné 0.82–1.12) qui adapte la typographie à la hauteur utile réelle : `_HeroSection` (image hero) → `_BrandBlock` (wordmark "JOEM" en dégradé navy→violet via `ShaderMask`, grilles de points décoratives, baseline "Job • Offres • ...") → `_TitleBlock` (les deux `_ActionCard` "Je suis recruteur" / "Je cherche un emploi") → `_Divider` → `_DescriptionBlock` → footer "Se connecter" (`_LoginFooter`).

Chaque `_ActionCard` affiche un titre (`_AutoFitText`, taille de base `19 * scale`, jusqu'à 2 lignes, rétrécit automatiquement plutôt que de déborder) et un sous-titre à deux lignes qui défilent en boucle façon ticker (`_RotatingSubtitle`, taille de base `12 * scale`, `maxLines: 1` — chaque ligne est donc forcée sur une seule ligne, `_AutoFitText` réduit la police jusqu'à ce qu'elle tienne plutôt que de passer à la ligne). Textes actuels : recruteur → "Publier des offres et trouvez" / "les meilleur talent" ; chercheur d'emploi → "Trouvez l'opportunité qui correspond" / "à votre profil". `_ActionCard` garde son propre effet de carte (fond blanc, ombre violette) plutôt que `core/widgets/glass_container.dart`.

### Ce qu'on trouve dans les dashboards

Espace Employeur — branche active `lib/features/dashboard/presentation/pages/employer_dashboard.dart` :
- En-tête `EmployerHeader` (logo/initiale, notification avec pastille réelle — `countUnreadApplicationNotificationsForEmployer` — barre de recherche en lecture seule qui ouvre `CandidateSearchScreen`) + `EmployerProfileSidePanel` (logo, nom entreprise, stats, carte "Profil complété" tapable → `EmployerProfileScreen`).
- Bouton "Publier une offre" → `JobOfferPublishScreen` (formulaire réel : titre, description, localisation, salaire, type de contrat, affiche facultative), pas un composeur de post social.
- Grille de KPI/statistiques et carte "Entretiens du jour" : toujours mockées.
- Liste "Mes offres" : réelle (`JobOfferRepository.fetchByEmployer`), plus les offres mockées d'avant.
- Liste "Candidats suggérés" (`_suggestedCandidates`, nom/poste correspondant/% de correspondance/expérience) : **toujours mockée en dur** — pas encore reliée à la recherche réelle de candidats ni aux compétences des offres publiées.
- Carte conseil (`AdviceCard`) et navigation basse (`BottomNavigation`) — voir "Flux d'écrans" pour les 4 sous-écrans accessibles depuis le menu bas.

Espace Chercheur d'emploi — branche active `lib/features/dashboard/presentation/pages/job_seeker_dashboard.dart` :
- En-tête `JobSeekerHeader` : barre de recherche en lecture seule qui ouvre `JobSearchScreen` (sans bouton filtre) + icône notification (ouvre `JobNotificationsScreen`, pastille rouge de compteur réelle — `NotificationBadge`/`countUnreadNotificationsForJobSeeker`) + avatar (ouvre `ProfileSidePanel`). Pas de logo JOEM, pas de texte de salutation ("Bonjour {prénom}...") — retirés à la demande.
- Section "Recommandées pour vous" juste sous le header (liste d'offres réelles, `JobOfferPostCard`, bouton "Voir plus" centré en bas de la liste — toujours un stub).
- Bannière hero ("Trouvez votre prochain emploi"), positionnée après les offres recommandées.
- Statistiques perso : candidatures envoyées, entretiens, favoris, réponses reçues — toujours mockées.
- Grille "Catégories populaires" (8 des 18 catégories de `kJobCategories`) : tap sur une catégorie ou "Voir tout" → `CategoryOffersScreen`/`JobCategoriesScreen`, avec les offres réellement filtrées par secteur (voir plus bas).
- Liste "Mes prochains entretiens" (entreprise, date, heure, lieu) : toujours mockée.
- Carte conseil carrière + navigation basse (`BottomNavigation`, pastille de notification sur l'item "Notifications", voir "Flux d'écrans" pour les sous-écrans accessibles depuis le menu bas et le header).

Sous-écrans du chercheur d'emploi (`lib/features/dashboard/presentation/pages/`) :
- `JobSearchScreen` : recherche réelle d'entreprises inscrites (pas un historique de recherches d'offres) — voir "Recherche de comptes et profils consultables" plus haut ; historique de recherche réel (`search_history`), entrées supprimables via une icône X.
- `JobCategoriesScreen` : grille des 18 catégories (`kJobCategories`) ; tap sur une catégorie → `CategoryOffersScreen`.
- `CategoryOffersScreen` : offres réelles dont l'entreprise appartient à la catégorie choisie (`JobOfferRepository.fetchByCategory`, jointure sur `employer_profiles.categorie`) — mêmes cartes/actions (`JobOfferPostCard` : postuler, enregistrer, masquer) que "Recommandées pour vous" ; "Aucune offre" si aucun recruteur du secteur n'a encore publié.
- `JobNotificationsScreen` : notifications réelles (une offre publiée = une notification, `JobOfferRepository.fetchNotificationsForJobSeeker`) façon LinkedIn — lues (fond blanc) vs non lues (fond mauve clair, texte gras, pastille) ; bouton "Tout marquer comme lu" ; tap = marque comme lue ; appui long ouvre un popup (bottom sheet) avec "Marquer comme non lue" / "Supprimer".
- `JobProfileScreen` : profil façon LinkedIn — bannière + avatar avec icône caméra (bas-droite de la bannière) et popup au tap sur l'avatar ("Voir la photo de profil" → plein écran zoomable via `ProfilePhotoViewerScreen` (`lib/core/widgets/`, partagé avec `ProfileSidePanel`) / "Prendre une photo") ; sélection réelle de photo via `image_picker` (galerie pour la couverture, gardée en mémoire pour la session, non persistée ; caméra/galerie pour l'avatar, celui-ci persisté via `AuthService.updateProfilePhoto`) ; icône stylo (`assets/images/stylo.png`) → `EditJobSeekerProfileScreen` (identité, coordonnées, présentation, tarif/disponibilité, modes de travail, CV, compétences — persisté via `AuthService.updateJobSeekerProfile`) ; carte "Complétion du profil" avec barre de progression ; sections "À propos", "Expérience" (ajout/suppression réels, `AuthService.addExperience`/`deleteExperienceAt`), "Formation" (toujours un placeholder, rien ne la collecte), "Compétences" ; pas de fonctionnalité de déconnexion sur cet écran (retirée à la demande).
- `ProfileSidePanel` : tap sur l'avatar → photo en plein écran (`ProfilePhotoViewerScreen`) ; carte "Profil complété" tapable → `JobProfileScreen`.

Espace Chercheur d'emploi — branche non branchée `lib/features/job_seeker_dashboard/` (toujours inatteignable depuis `LoginScreen`) :
- Carte "Boost"/mise en avant du profil, carte "Complétion du profil", statistiques avec mini-graphique de tendance — voir "Deux implémentations parallèles" plus haut.
- **Ne compile plus** : `sector_item.dart`/`stat_mini_card.dart` (et les widgets partagés `core/widgets/dashboard_card.dart`/`advice_card.dart` qu'elle réutilise) référencent des getters absents de `AppColors`/`AppRadii`/`AppShadows` (`dashboardMauveDark`, `dashboardKpiCard`, `dashboardCard`, etc. — voir `flutter analyze`, ~170 erreurs `undefined_getter`). À corriger avant de rebrancher cette variante, ou à supprimer si la branche active reste la version canonique.

## Ce qui est déjà fait

- Projet Flutter généré pour Android, iOS, web, Windows, Linux, macOS.
- Tokens du design system dans `lib/core/theme/` (couleurs, dégradés, glassmorphism, typographie Poppins/Inter, espacements, rayons, ombres, durées d'animation) — avec doublons non résolus (`app_text_styles.dart`/`app_typography.dart`, `app_radii.dart`/`app_radius.dart`).
- `Responsive`, `GlassContainer`/`GlassButton`, kit de formulaire clair, kit wizard d'inscription, kit dashboard partagés dans `lib/core/`.
- Écran d'accueil/onboarding complet (dégradé de fond + vagues décoratives, wordmark "JOEM" en dégradé animé, texte hero, deux cartes de sélection de rôle avec sous-titres en ticker, footer connexion), en français.
- Deux wizards d'inscription mono-écran (à étapes) : recruteur (3 étapes) et chercheur d'emploi (5 étapes), même identité visuelle qu'entre eux et avec le welcome screen (voir ci-dessous).
- Écran de connexion (`LoginScreen`) : email/mot de passe + bouton Google (stub), "se souvenir de moi", validation basique, redirection par rôle après connexion réussie.
- **Thème login + wizards d'inscription harmonisé avec le welcome screen** : fond passé du blanc uni au dégradé `OnboardingColors.bgTop → bgBottom` sur les 3 écrans ; logo `CenteredLogo` (image PNG) remplacé partout par `JoemGradientLogo` (wordmark texte au dégradé, voir plus haut) ; accents violets (case à cocher, liens, titres, stepper, bouton principal, focus des champs, icônes d'étape) basculés de `AppColors.primary` vers `OnboardingColors.violet`/`navy` — voir "Nouveau doublon de palette à surveiller" plus haut pour le détail des fichiers touchés et de ceux volontairement laissés sur `AppColors` (dashboards).
- Navigation entièrement câblée entre ces écrans avec `Navigator.push`/`pushReplacement` (plus aucun stub `debugPrint`/TODO comme avant).
- Deux implémentations de dashboards (Employeur / Chercheur d'emploi), chacune avec sa propre pile auth — voir "Deux implémentations parallèles" ci-dessus pour le détail et l'incohérence à résoudre.
- Un test de fumée pour l'écran d'accueil, et un test de fumée (`test/employer_dashboard_smoke_test.dart`) pour `EmployerDashboardScreen` (la variante non branchée à `LoginScreen`, qui ne compile plus — voir plus haut).
- `maquette_employeur.png` ajouté à la racine comme référence visuelle pour les dashboards.
- **Backend SQLite réel** (`lib/core/database/app_database.dart`, migrations versionnées) remplaçant les comptes de démo pour tout compte réellement inscrit : les deux wizards (`RecruiterRepository`, `JobSeekerRepository`) créent une vraie ligne `users`/`employer_profiles`/`job_seeker_profiles`, connectable ensuite via `LoginScreen` (mot de passe hashé, `crypto`). Offres d'emploi, candidatures, notifications (offre ↔ candidat, candidature ↔ recruteur), CV (fichier sur disque, pas en BLOB) et historique de recherche sont eux aussi réels — voir `JobOfferRepository`/`AccountSearchRepository`.
- Dashboard chercheur d'emploi retravaillé : header dédié (`JobSeekerHeader` : barre de recherche + notification avec pastille compteur réelle + avatar), section "Recommandées pour vous" remontée juste sous le header, section "Continuer ma recherche" retirée de l'accueil (l'historique vit désormais dans `JobSearchScreen`).
- **Recherche de comptes réelle des deux côtés**, avec vraies pages de profil consultables (pas de bottom sheet résumée) : `CandidateSearchScreen`/`CandidateProfileViewScreen` côté recruteur, `JobSearchScreen`/`CompanyProfileViewScreen` côté candidat — voir "Recherche de comptes et profils consultables" plus haut. Historique de recherche persisté (`search_history`), y compris quand on ouvre un profil sans valider la recherche au clavier.
- **Catégorie d'entreprise obligatoire à l'inscription recruteur** (`StepTwoPersonalInfo`, dropdown filtré sur `kJobCategories`, `employer_profiles.categorie`) et réutilisée côté candidat : `JobCategoriesScreen`/grille "Catégories populaires" → `CategoryOffersScreen` liste les offres réellement publiées par les recruteurs de ce secteur (`JobOfferRepository.fetchByCategory`).
- **Écrans "Modifier le profil" pour les deux rôles** : `EditJobSeekerProfileScreen` (candidat) et `EditEmployerProfileScreen` (recruteur, avec le champ catégorie), ouverts depuis l'icône stylo de `JobProfileScreen`/`EmployerProfileScreen`, persistés via `AuthService.updateJobSeekerProfile`/`updateEmployerProfile`. La carte "Profil complété" (pourcentage + suggestions, `ProfileSidePanel` et les deux écrans profil) est tapable et renvoie vers l'écran d'édition correspondant.
- Photo de profil/logo : sélection réelle via `image_picker`, **persistée** (`job_seeker_profiles.photo`/`employer_profiles.logo`) via `AuthService.updateProfilePhoto`, visible immédiatement dans le header/panneau latéral/profil sans re-sélection. Visionneuse plein écran zoomable partagée (`ProfilePhotoViewerScreen`, `lib/core/widgets/`), utilisée par `JobProfileScreen` et `ProfileSidePanel`.
- Notifications réellement branchées des deux côtés : icône du header (candidat) et pastilles de compteur (candidat + recruteur) ouvrent bien `JobNotificationsScreen`/`EmployerNotificationsScreen` et rafraîchissent le compteur au retour.
- Widget partagé `NotificationBadge` (`lib/core/widgets/`) pour la pastille rouge de compteur, réutilisé sur l'icône notification des deux headers et sur l'item "Notifications" des deux nav basses.

## Ce qui reste à faire

- **Choisir et fusionner** l'une des deux paires dashboard décrites plus haut (la branche non branchée `lib/features/job_seeker_dashboard/`/`employer_dashboard/` ne compile même plus, voir plus haut) ; supprimer l'autre plutôt que de les laisser diverger. Supprimer aussi les widgets désormais orphelins `dashboard_header.dart`/`greeting_section.dart`.
- Résoudre les doublons de tokens de thème (`app_text_styles.dart` vs `app_typography.dart`, `app_radii.dart` vs `app_radius.dart`) et harmoniser les imports (relatifs vs `package:joem/...`).
- Aucune solution de gestion d'état n'est en place (pas de provider/riverpod/bloc dans `pubspec.yaml`) — l'app reste de la présentation pure avec état local par écran, malgré le vrai backend SQLite.
- Toujours aucune intégration API/serveur distant — la persistance reste 100% locale (SQLite sur l'appareil, un seul utilisateur, pas de synchronisation). Certaines listes restent mockées en dur faute de fonctionnalité correspondante : statistiques du dashboard candidat (candidatures/entretiens/favoris/réponses), "Mes prochains entretiens", grille de KPI + "Entretiens du jour" et **"Candidats suggérés"** côté recruteur (`_suggestedCandidates`, pas encore relié à `CandidateSearchScreen` ni aux compétences des offres publiées).
- `main.dart` construit toujours son propre thème inline au lieu d'utiliser `AppTheme.dark`.
- Le glassmorphism de `RoleSelectionCardWidget` reste codé à la main plutôt que de réutiliser `GlassContainer`.
- Boutons "Google", "Mot de passe oublié", actions rapides de type "Voir plus"/quick actions restants (liste "Recommandées pour vous", calendrier, etc.) sont encore des stubs (`onTap: () {}`). Aucun des écrans de recherche réels (`CandidateSearchScreen`/`JobSearchScreen`) n'a de filtre au-delà du texte saisi.
- Items "Accueil" et "Favoris" du menu bas de `JobSeekerDashboard` ne font que changer l'icône active, sans contenu réel derrière.
- Photo de **couverture** (bannière de `JobProfileScreen`/`EmployerProfileScreen`, distincte de l'avatar/logo) : sélectionnée via `image_picker` mais gardée en mémoire (`Uint8List`, état local à l'écran) uniquement — perdue à la fermeture de l'écran, aucune colonne dédiée en base.
- `EditJobSeekerProfileScreen`/`EditEmployerProfileScreen` ne couvrent pas la photo (gérée séparément, tap sur l'avatar/logo) ni, côté candidat, la section "Formation" (jamais collectée nulle part).
- Couverture de tests très partielle : un test welcome + un test dashboard (sur la branche non utilisée, qui ne compile plus) + un test d'intégration recruteur (`test/_tmp_recruiter_login_check.dart`, préfixé `_tmp_` comme scratch). Rien sur les wizards d'inscription en tant que tels, l'écran de connexion, la recherche de comptes, les catégories, ou la navigation de bout en bout de la branche dashboard réellement branchée à `LoginScreen`.
- `README.md` est encore le boilerplate par défaut de `flutter create` et n'a pas été mis à jour pour JOEM.