# Construire l'APK JOEM pour un téléphone

## 1. Démarrer l'API sur le PC

Double-cliquer sur `joem_api\deploy\start-api.bat` (Apache de Laragon, port 8000).
Vérifier depuis le navigateur du PC : http://192.168.1.70:8000/api/categories doit afficher du JSON.

## 2. Vérifier l'adresse IP du PC

Dans un terminal : `ipconfig` → ligne « Adresse IPv4 » de la carte Wi-Fi/Ethernet
(pas `192.168.56.1`, qui est la carte VirtualBox). Aujourd'hui : `192.168.1.70`.

## 3. Construire l'APK

Dans le dossier `joem` :

```bat
build-apk.bat
```

ou, si l'IP du PC a changé :

```bat
build-apk.bat 192.168.1.42
```

Durée : quelques minutes (la première fois plus longtemps). Résultat : `joem\dist\JOEM.apk`.

Commande équivalente sans le script :

```bat
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.70:8000/api
```

→ `build\app\outputs\flutter-apk\app-release.apk`

L'adresse de l'API est **gravée dans l'APK** : si l'IP du PC change, il faut reconstruire
l'APK et le réinstaller.

## 4. Copier l'APK sur le téléphone B

Au choix : câble USB (copier `JOEM.apk` dans « Téléchargements »), Google Drive,
Telegram/WhatsApp « à soi-même », ou `adb install -r dist\JOEM.apk` si le débogage USB est activé.

## 5. Installer sur le téléphone B

1. Ouvrir `JOEM.apk` depuis le gestionnaire de fichiers.
2. Autoriser « Installer des applications inconnues » pour l'application utilisée (Fichiers, Drive...).
3. Si Play Protect avertit : « Plus de détails » → « Installer quand même ».
4. Mise à jour : installer le nouvel APK par-dessus, les données sont conservées.
   Si Android refuse (« conflit de paquet ») : désinstaller JOEM puis réinstaller.

## 6. Utiliser

Le téléphone doit être **sur le même Wi-Fi que le PC**, avec l'API démarrée (étape 1).
Si l'app affiche « Impossible de joindre le serveur JOEM » : ouvrir
`http://192.168.1.70:8000/api/categories` dans le navigateur du téléphone.
S'il n'affiche rien → problème de réseau/pare-feu/IP, pas de l'app.

## Remarques

- Sans `android/key.properties`, l'APK est signé avec la clé de debug : parfait pour tester,
  refusé par le Play Store. Toujours construire depuis le même PC, sinon Android refusera
  la mise à jour (signature différente) → désinstaller puis réinstaller.
- La connexion Google ne marche pas tant que `kGoogleServerClientId` n'est pas configuré
  (`lib/core/constants/google_config.dart`) et que l'empreinte SHA-1 de la clé qui signe
  l'APK n'est pas déclarée sur Google Cloud Console.
- Le HTTP non chiffré n'est autorisé que parce que l'adresse de l'API commence par
  `http://` (voir `android/app/build.gradle.kts`). Avec un vrai serveur en `https://`,
  il reste bloqué, comme il se doit.
