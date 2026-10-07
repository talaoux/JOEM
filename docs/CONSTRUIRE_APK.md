# Construire et installer un APK de test

Ce guide concerne les tests sur le réseau local avec l'API JOEM démarrée sur le PC. Pour publier sur Google Play ou distribuer un build de production, utilise build-apk-prod.bat et une URL HTTPS.

## 1. Démarrer et vérifier l'API

Démarre le serveur avec ..\joem_api\deploy\start-api.bat. Le PC et le téléphone doivent être sur le même Wi-Fi; autorise le port 8000 dans le pare-feu Windows sur un réseau privé.

Trouve l'adresse IPv4 actuelle du PC avec ipconfig, puis vérifie depuis le téléphone :

    http://<IP-LAN-DU-PC>:8000/up
    http://<IP-LAN-DU-PC>:8000/api/categories

La seconde adresse doit renvoyer du JSON. N'utilise pas une adresse VirtualBox ou une ancienne adresse IP.

## 2. Construire l'APK de test

Depuis le dossier joem, lance le script en passant l'IP actuelle du PC :

    build-apk.bat <IP-LAN-DU-PC>

Le résultat est dist\JOEM.apk. L'adresse API est intégrée à l'APK; reconstruis-le si l'adresse du PC change. Ce build local utilise HTTP et une signature de test lorsqu'aucune clé de production n'est configurée : ne le distribue pas comme version de production.

## 3. Installer sur le téléphone

Transfère dist\JOEM.apk au téléphone, ou installe-le avec adb install -r dist\JOEM.apk si le débogage USB est activé. Android peut demander l'autorisation d'installer depuis cette source. N'ignore pas un avertissement Play Protect sans avoir vérifié la provenance du fichier.

Pour mettre à jour l'application, le nouvel APK doit être signé avec la même clé que la version installée. Les builds de test et de production peuvent utiliser des signatures différentes.

## 4. Connexion Google

La connexion Google dépend de la configuration OAuth du projet et de l'empreinte SHA-1 de la clé de signature utilisée. Vérifie lib/core/constants/google_config.dart et la configuration Google Cloud avant de diagnostiquer un échec de connexion.

## Production

Utilise build-apk-prod.bat https://<domaine>/api apk pour un APK ou build-apk-prod.bat https://<domaine>/api aab pour un bundle Play Store. Le script refuse HTTP et exige android/key.properties.
