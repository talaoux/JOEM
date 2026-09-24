import 'package:flutter/material.dart';
import 'package:joem/core/navigation/app_route_observer.dart';
import 'package:joem/core/navigation/fade_through_page_transitions_builder.dart';
import 'package:joem/core/services/display_preferences_controller.dart';
import 'package:joem/core/theme/app_surface_colors.dart';
import 'package:joem/features/splash/presentation/splash_screen.dart';

void main() {
  runApp(const JOEMApp());
}

class JOEMApp extends StatefulWidget {
  const JOEMApp({super.key});

  @override
  State<JOEMApp> createState() => _JOEMAppState();
}

class _JOEMAppState extends State<JOEMApp> {
  final DisplayPreferencesController _displayPreferences = DisplayPreferencesController.instance;

  @override
  void initState() {
    super.initState();
    _displayPreferences.addListener(_onDisplayPreferencesChanged);
  }

  @override
  void dispose() {
    _displayPreferences.removeListener(_onDisplayPreferencesChanged);
    super.dispose();
  }

  void _onDisplayPreferencesChanged() => setState(() {});

  /// Commun aux deux variantes claire/sombre : seule l'extension
  /// [AppSurfaceColors] attachée change, tout le reste (boutons, cartes,
  /// `colorScheme`) reste identique à l'unique thème d'origine pour ne pas
  /// affecter les écrans (login, wizards, dashboard employeur) qui ne
  /// consultent jamais `Theme.of(context)` pour leurs couleurs.
  ThemeData _buildTheme(AppSurfaceColors surfaceColors) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        // Bleu océan (`DashboardColors.accent`) : couleur des espaces
        // candidat et recruteur. Ne colore que les éléments Material par
        // défaut (boutons de dialogue, sélecteurs de date/heure,
        // indicateurs de chargement...) ; l'accueil, la connexion et les
        // wizards posent leur violet explicitement et n'en dépendent pas.
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.dark,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      extensions: [surfaceColors],
      // Applique un fondu enchaîné + léger glissement à *toute* navigation
      // `Navigator.push`/`pushReplacement` de l'app (toutes plateformes),
      // sans avoir à toucher chacun des appels dans les écrans — voir
      // `FadeThroughPageTransitionsBuilder`.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeThroughPageTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JOEM - Job Offer & Employment Madagascar',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [appRouteObserver],
      themeMode: _displayPreferences.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(AppSurfaceColors.light),
      darkTheme: _buildTheme(AppSurfaceColors.dark),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scale = _displayPreferences.isLargeText
            ? DisplayPreferencesController.largeTextScaleFactor
            : 1.0;
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(scale * mediaQuery.textScaler.scale(1.0)),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
