# JOEM

JOEM est une application mobile Flutter de mise en relation entre recruteurs et chercheurs d'emploi à Madagascar. Elle utilise SQLite en mode local et peut connecter les parcours pris en charge à l'API Laravel avec API_BASE_URL.

## Prérequis

- Flutter et Dart compatibles avec les contraintes de pubspec.yaml.
- Pour les fonctionnalités connectées : l'API JOEM démarrée et son adresse accessible depuis l'appareil.

## Développement

Lancer en mode local :

    flutter pub get
    flutter run

Sans API_BASE_URL, l'application utilise le mode local. Pour lancer avec l'API, passe son URL au build, par exemple :

    flutter run --dart-define=API_BASE_URL=https://api.exemple.mg/api

Pour tester sur un téléphone avec le serveur Windows du réseau local, voir [Construire et installer un APK de test](docs/CONSTRUIRE_APK.md).

## Vérifications

    flutter analyze
    flutter test

## Builds

- APK de test sur le réseau local : build-apk.bat <IP-LAN-DU-PC>.
- APK/AAB de production : build-apk-prod.bat https://<domaine>/api [apk|aab]. Ce script exige la clé de signature de production configurée dans android/key.properties.

Le contrat avec l'API Laravel est documenté dans C:\Users\WINDOWS 10\Desktop\joem_api\docs\CONTRAT_API.md.
