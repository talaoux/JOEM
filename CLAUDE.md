
# CLAUDE.md

Ce fichier fournit des indications à Claude Code (claude.ai/code) pour travailler sur le code de ce dépôt.

## Aperçu du projet

JOEM ("Job Offer & Employment Madagascar") est une application Flutter ciblant le marché de l'emploi malgache, mettant en relation recruteurs et chercheurs d'emploi. Le projet en est à un stade précoce : seul l'écran d'accueil/onboarding est construit pour l'instant, sans navigation, backend ni authentification branchés.

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

Il n'y a pas de configuration CI, pas de règles de lint personnalisées au-delà de l'ensemble par défaut `flutter_lints`, et pas d'étape de génération de code (pas de `build_runner`).

## Architecture

Le code suit une structure **feature-first** sous `lib/` :

- `lib/core/` — briques partagées entre toutes les fonctionnalités :
  - `theme/` — tokens de design : `app_colors.dart` (palette, dégradés, décoration glassmorphism), `app_text_styles.dart` (échelle typographique Poppins/Inter via Google Fonts), `app_spacing.dart`, `app_radii.dart`, et `app_theme.dart` (le `ThemeData` Material 3 global, actuellement *non* appliqué — voir ci-dessous).
  - `widgets/glass_container.dart` — surface "verre dépoli" réutilisable (flou + bordure + lueur) utilisée pour les visuels premium de type carte/bouton.
  - `utils/responsive.dart` — breakpoints partagés (`isTablet`/`isDesktop`) pour les décisions de mise en page responsive.
- `lib/features/<feature>/presentation/` — chaque fonctionnalité possède ses écrans sous `presentation/`, avec un sous-dossier `widgets/` pour les composants propres à l'écran (non partagés ailleurs). Une seule fonctionnalité existe actuellement : `welcome/`.

Convention d'imports : dans les widgets propres à une fonctionnalité, les imports relatifs vers `core` sont utilisés (ex. `../../../../core/theme/app_colors.dart`) ; `lib/main.dart` et les références inter-fonctionnalités utilisent la forme absolue `package:joem/...`.

### Point d'entrée et incohérence de thème

`lib/main.dart` construit `MaterialApp` avec un `ThemeData` **inline** (sombre, Material 3, dérivé de `AppColors.primary`) plutôt que d'utiliser `AppTheme.dark` défini dans `lib/core/theme/app_theme.dart`. Le commentaire de doc sur `AppTheme` précise explicitement que l'écran d'accueil peint ses propres dégradés/surfaces de verre en dehors du thème, mais que chaque *autre* écran futur est censé s'appuyer sur `AppTheme.dark` — le thème de `main.dart` devrait donc, à terme, être remplacé par `AppTheme.dark`.

### Écran d'accueil (welcome)

`lib/features/welcome/presentation/welcome_screen.dart` est un `StatefulWidget` qui possède un unique `AnimationController` (1500ms, courbe `easeOutCubic`) pilotant des animations d'apparition (fade/slide) échelonnées sur ses widgets enfants (logo, texte hero, cartes de rôle, chacun avec un délai basé sur `Interval`). Il compose, dans un `Stack` :

1. `BackgroundImageWidget` — image de fond plein écran (`assets/images/pexels-mizunokozuki-13929421.jpg`) avec `alignment`/`zoom` configurables pour le recadrage.
2. `DarkOverlayWidget` — un dégradé haut/centre/bas assombrissant pour la lisibilité du texte.
3. Contenu défilant au premier plan : `LogoSectionWidget` → `HeroTextWidget` → deux `RoleSelectionCardWidget` ("recruteur" / "chercheur d'emploi") → un footer "Déjà inscrit ? Se connecter".

`RoleSelectionCardWidget` possède son propre `AnimationController` local pour l'effet de pression (scale au tap), distinct de l'animation d'entrée du parent, et implémente son propre effet glassmorphism en inline (son propre `BackdropFilter`/`BoxDecoration`) plutôt que de réutiliser `core/widgets/glass_container.dart` — à harmoniser si un second style de carte "verre" venait à diverger davantage.

## Ce qui est déjà fait

- Projet Flutter généré pour Android, iOS, web, Windows, Linux, macOS.
- Tokens du design system dans `lib/core/theme/` (couleurs, dégradés, décoration glassmorphism, styles de texte via Google Fonts Poppins/Inter, espacements, rayons).
- Helper de breakpoints `Responsive` et widget `GlassContainer` partagés dans `lib/core/`.
- Écran d'accueil/onboarding complet : image de fond + dégradé overlay, logo animé, texte hero animé, deux cartes glassmorphism animées de sélection de rôle (recruteur / chercheur d'emploi), et un lien de connexion en footer — le tout en français.
- Animations d'entrée (fade + slide échelonnés) et animation de pression au tap par carte.
- Un test widget vérifiant que l'écran d'accueil affiche bien le logo JOEM et le slogan.

## Ce qui reste à faire

- **La navigation est entièrement en stub** : `_onRecruiterTap`, `_onJobSeekerTap` et `_onLoginTap` dans `welcome_screen.dart` se contentent d'un `debugPrint` et sont marqués `// TODO`. Aucun routeur (`go_router`/routes `Navigator`) n'existe encore, et aucun écran de destination (flux recruteur, flux chercheur d'emploi, connexion) n'a été construit.
- Aucune solution de gestion d'état n'est en place (pas de dépendance provider/riverpod/bloc dans `pubspec.yaml`) — l'app n'est pour l'instant que de la présentation pure.
- Aucune intégration backend/API, pas d'authentification, pas de couches data/domain — seul un dossier `presentation/` existe par fonctionnalité, la future séparation `data/`/`domain/` (si adoptée) reste à concevoir.
- `main.dart` construit son propre thème inline au lieu d'utiliser `AppTheme.dark` ; à harmoniser une fois que d'autres écrans existeront.
- Le glassmorphism de `RoleSelectionCardWidget` est codé à la main plutôt que de réutiliser `GlassContainer` — à unifier.
- Un seul test de fumée existe ; aucun test ne couvre les widgets individuels, les animations, ni (une fois ajoutées) la navigation/la logique d'état.
- `README.md` est encore le boilerplate par défaut de `flutter create` et n'a pas été mis à jour pour JOEM.