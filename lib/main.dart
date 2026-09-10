import 'package:flutter/material.dart';
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
        seedColor: const Color(0xFFA855F7),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JOEM - Job Offer & Employment Madagascar',
      debugShowCheckedModeBanner: false,
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
