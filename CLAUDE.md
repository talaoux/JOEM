



# CLAUDE.md

Ce fichier fournit des indications à Claude Code (claude.ai/code) pour travailler sur le code de ce dépôt.

## Aperçu du projet

JOEM ("Job Offer & Employment Madagascar") est une application Flutter ciblant le marché de l'emploi malgache, mettant en relation recruteurs et chercheurs d'emploi. Le flux complet onboarding → inscription → connexion → dashboard existe maintenant en présentation pure (données mockées en dur, pas de backend, pas de state management, pas de routeur déclaratif — uniquement `Navigator.push`/`pushReplacement`).

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

Il n'y a pas de configuration CI, pas de règles de lint personnalisées au-delà de l'ensemble par défaut `flutter_lints`, et pas d'étape de génération de code (pas de `build_runner`). `pubspec.yaml` ne déclare toujours que `cupertino_icons` et `google_fonts` comme dépendances runtime — aucune lib de state management (provider/riverpod/bloc) ni de routeur (go_router) n'a été ajoutée.

## Architecture

Le code suit une structure **feature-first** sous `lib/` :

- `lib/core/` — briques partagées entre toutes les fonctionnalités :
  - `theme/` — tokens de design : `app_colors.dart`, `app_spacing.dart`, `app_durations.dart`, `app_shadows.dart`, `app_radii.dart` / `app_radius.dart`, `app_text_styles.dart` / `app_typography.dart` (échelles Poppins/Inter via Google Fonts), et `app_theme.dart` (le `ThemeData` Material 3 global, toujours *non* appliqué — voir ci-dessous).
  - `widgets/` — composants partagés : `glass_container.dart`/`glass_button.dart` (verre dépoli), le kit de formulaire clair (`form_surface.dart`, `light_text_field.dart`, `light_dropdown.dart`, `centered_logo.dart`, `google_sign_in_button.dart`, `or_divider.dart`), le kit d'inscription en wizard (`registration_stepper.dart`, `wizard_navigation.dart`, `step_one_account.dart`), et le kit dashboard (`dashboard_card.dart`, `section_header.dart`, `advice_card.dart`, `mini_line_chart_painter.dart`).
  - `services/auth_service.dart` — service d'authentification mock utilisé par l'écran de connexion et les dashboards actuellement branchés (voir "Deux implémentations parallèles" ci-dessous).
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
```

Les wizards d'inscription ne créent pas de compte utilisable : `LoginScreen` ne connaît que les comptes de démo codés en dur dans `AuthService` (voir plus bas), donc s'inscrire puis se connecter avec ce compte échoue.

### Deux implémentations parallèles pour l'auth et les dashboards

Deux paires concurrentes coexistent, non harmonisées — à surveiller pour ne pas dupliquer le travail par erreur :

1. **Branche active (celle réellement utilisée par `LoginScreen`)**
   - Auth : `lib/core/services/auth_service.dart` — `AuthService extends ChangeNotifier`, 2 comptes de démo en dur (`employeur@gmail.com` / `candidat@gmail.com`), méthodes `login()`, `logout()`, `isEmployer()`, `isJobSeeker()`.
   - Dashboards : `lib/features/dashboard/presentation/pages/employer_dashboard.dart` et `job_seeker_dashboard.dart` (+ leurs widgets dans `lib/features/dashboard/presentation/widgets/`). Beaucoup de logique responsive ad hoc en dur dans l'écran (helpers `_isSmallScreen`/`_getStatCardAspectRatio`/etc.) plutôt que dans des widgets réutilisables.

2. **Branche non branchée (code présent mais jamais importé par un écran atteignable)**
   - Auth : `lib/features/login/data/mock_auth_service.dart` (+ `data/auth_exception.dart`, `domain/auth_user.dart`, `domain/user_role.dart`) — `MockAuthService`, un seul compte de test, exceptions typées (`AuthException`). Modèle plus propre (séparation data/domain) mais `LoginScreen` ne l'utilise pas.
   - Dashboards : `lib/features/employer_dashboard/presentation/employer_dashboard_screen.dart` et `lib/features/job_seeker_dashboard/presentation/job_seeker_dashboard_screen.dart` — reproduction fidèle de la maquette `maquette_employeur.png`, layout responsive large/étroit factorisé (`_buildWideLayout`/`_buildNarrowLayout`), réutilise les widgets partagés `core/widgets/` (`DashboardCard`, `SectionHeader`, `AdviceCard`). C'est cette implémentation que couvre `test/employer_dashboard_smoke_test.dart` — donc le seul test de dashboard existant teste un écran que l'utilisateur ne peut pas atteindre en lançant l'app.

**À trancher/harmoniser** : choisir laquelle des deux paires devient la version canonique (le second dashboard, plus propre et testé, est un bon candidat) et supprimer/rebrancher l'autre plutôt que de continuer à faire évoluer les deux en parallèle. Idem pour `app_text_styles.dart` vs `app_typography.dart` et `app_radii.dart` vs `app_radius.dart`, qui semblent être deux tentatives du même token de design.

### Écran d'accueil (welcome)

`lib/features/welcome/presentation/welcome_screen.dart` reste un `StatefulWidget` avec un `AnimationController` (1500ms, `easeOutCubic`) pilotant les animations d'apparition. Composition en `Stack` : `BackgroundImageWidget` → `DarkOverlayWidget` → contenu défilant (`LogoSectionWidget` → `HeroTextWidget` → deux `RoleSelectionCardWidget` → footer "Se connecter"). `RoleSelectionCardWidget` garde son propre effet glassmorphism inline plutôt que `core/widgets/glass_container.dart`.

### Ce qu'on trouve dans les dashboards

Contenu (mocké, en dur dans chaque écran, aucun ne vient d'une API) commun aux deux implémentations, Espace Employeur :
- En-tête avec initiale/avatar, badge de notifications, salutation ("Bonjour {prénom}").
- Barre de recherche + filtre.
- Bouton/carte "Publier une offre".
- Grille de KPI/statistiques : offres publiées/actives, candidatures reçues, entretiens, embauches/vues — avec mini-graphique de tendance (`mini_line_chart_painter.dart`) sur la version `employer_dashboard/`.
- Liste "Mes offres" (titre, ville, salaire, nb de candidatures, bouton éditer).
- Liste "Candidats" / "Nouveaux candidats" (nom, poste, expérience, statut : Nouveau/Vue/Entretien).
- Carte "Entretiens du jour" (heure, candidat, poste).
- Carte conseil (`AdviceCard`).
- Navigation basse (`BottomNavigation` / `DashboardBottomNav`).

Espace Chercheur d'emploi :
- En-tête + barre de recherche/filtre, salutation ("Bonjour {prénom}").
- Bannière hero ("Trouvez le job qui vous correspond" sur la version `job_seeker_dashboard/`, calquée sur `maquette_employeur.png`).
- Statistiques perso : candidatures envoyées, entretiens, favoris, réponses reçues / vues de profil — avec mini-graphique de tendance.
- Grille de secteurs/catégories (Informatique, BTP, Santé, Commerce, Hôtellerie, Finance, Marketing, Éducation, Industrie...).
- Liste d'offres recommandées (entreprise, poste, ville, type de contrat, expérience, fourchette de salaire, badge "nouveau", favori).
- Chips "Continuer ma recherche" (historique de recherche) — version `dashboard/` uniquement.
- Liste "Mes prochains entretiens" (entreprise, date, heure, lieu).
- Carte "Complétion du profil" avec barre de progression — version `job_seeker_dashboard/` uniquement.
- Carte "Boost"/mise en avant du profil — version `job_seeker_dashboard/` uniquement.
- Carte conseil carrière + navigation basse.

## Ce qui est déjà fait

- Projet Flutter généré pour Android, iOS, web, Windows, Linux, macOS.
- Tokens du design system dans `lib/core/theme/` (couleurs, dégradés, glassmorphism, typographie Poppins/Inter, espacements, rayons, ombres, durées d'animation) — avec doublons non résolus (`app_text_styles.dart`/`app_typography.dart`, `app_radii.dart`/`app_radius.dart`).
- `Responsive`, `GlassContainer`/`GlassButton`, kit de formulaire clair, kit wizard d'inscription, kit dashboard partagés dans `lib/core/`.
- Écran d'accueil/onboarding complet (image de fond, overlay, logo animé, texte hero, deux cartes glassmorphism de sélection de rôle, footer connexion), en français.
- Deux wizards d'inscription mono-écran (à étapes) : recruteur (3 étapes) et chercheur d'emploi (5 étapes), fond blanc, même identité visuelle.
- Écran de connexion (`LoginScreen`) : email/mot de passe + bouton Google (stub), "se souvenir de moi", validation basique, redirection par rôle après connexion réussie.
- Navigation entièrement câblée entre ces écrans avec `Navigator.push`/`pushReplacement` (plus aucun stub `debugPrint`/TODO comme avant).
- Deux implémentations de dashboards (Employeur / Chercheur d'emploi), chacune avec sa propre pile auth mock — voir "Deux implémentations parallèles" ci-dessus pour le détail et l'incohérence à résoudre.
- Un test de fumée pour l'écran d'accueil, et un test de fumée (`test/employer_dashboard_smoke_test.dart`) pour `EmployerDashboardScreen` (la variante non branchée à `LoginScreen`).
- `maquette_employeur.png` ajouté à la racine comme référence visuelle pour les dashboards.

## Ce qui reste à faire

- **Choisir et fusionner** l'une des deux paires auth+dashboard décrites plus haut (probablement `MockAuthService`/`employer_dashboard`/`job_seeker_dashboard`, plus propres et testés) ; supprimer l'autre plutôt que de les laisser diverger.
- **Brancher les wizards d'inscription à l'auth** : aujourd'hui, s'inscrire ne crée aucun compte utilisable ; seuls les comptes de démo codés en dur permettent de se connecter.
- Résoudre les doublons de tokens de thème (`app_text_styles.dart` vs `app_typography.dart`, `app_radii.dart` vs `app_radius.dart`) et harmoniser les imports (relatifs vs `package:joem/...`).
- Aucune solution de gestion d'état n'est en place (pas de provider/riverpod/bloc dans `pubspec.yaml`) — l'app reste de la présentation pure avec état local par écran.
- Aucune intégration backend/API — tout est mocké en dur (comptes de démo, offres, candidats, entretiens).
- `main.dart` construit toujours son propre thème inline au lieu d'utiliser `AppTheme.dark`.
- Le glassmorphism de `RoleSelectionCardWidget` reste codé à la main plutôt que de réutiliser `GlassContainer`.
- Boutons "Google", "Mot de passe oublié", filtres de recherche, "Voir tout", actions rapides des dashboards (créer offre, voir offres, candidats, calendrier, favoris, etc.) sont tous des stubs (`onTap: () {}` ou `debugPrint`).
- Couverture de tests très partielle : un test welcome + un test dashboard (sur la branche non utilisée) ; rien sur les wizards d'inscription, l'écran de connexion, la navigation de bout en bout, ou la branche dashboard réellement branchée à `LoginScreen`.
- `README.md` est encore le boilerplate par défaut de `flutter create` et n'a pas été mis à jour pour JOEM.