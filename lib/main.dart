import 'package:flutter/material.dart';
import 'package:joem/features/welcome/presentation/welcome_screen.dart';

void main() {
  runApp(const JOEMApp());
}

class JOEMApp extends StatelessWidget {
  const JOEMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JOEM - Job Offer & Employment Madagascar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Material Design 3
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        // Désactiver le splash par défaut pour un look plus premium
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        // Configuration des cartes
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        // Configuration des boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}