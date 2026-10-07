@echo off
rem Construit l'APK / l'AAB JOEM de PRODUCTION, branche sur l'API du VPS en HTTPS.
rem
rem   build-apk-prod.bat https://api.joem.mg/api          -> dist\JOEM-prod.apk
rem   build-apk-prod.bat https://api.joem.mg/api aab      -> dist\JOEM-prod.aab (Play Store)
rem
rem Exige android\key.properties (cle de signature release) et une URL en
rem https:// : le HTTP non chiffre reste alors bloque par Android.
setlocal
set "API=%~1"
set "FORMAT=%~2"
if "%FORMAT%"=="" set "FORMAT=apk"

if "%API%"=="" (
  echo Usage : build-apk-prod.bat https://^<domaine^>/api [apk^|aab]
  exit /b 1
)
if /i not "%API:~0,8%"=="https://" (
  echo L'URL de production doit commencer par https:// ^(recu : %API%^)
  exit /b 1
)

cd /d "%~dp0"
if not exist android\key.properties (
  echo android\key.properties absent : l'APK serait signe avec la cle de DEBUG.
  exit /b 1
)

echo.
echo === Construction JOEM production (%FORMAT%, API : %API%) ===
echo.
call flutter pub get || goto :erreur

if not exist dist mkdir dist
if /i "%FORMAT%"=="aab" (
  call flutter build appbundle --release --dart-define=API_BASE_URL=%API% || goto :erreur
  copy /y "build\app\outputs\bundle\release\app-release.aab" "dist\JOEM-prod.aab" >nul || goto :erreur
  echo === OK : dist\JOEM-prod.aab ===
) else (
  call flutter build apk --release --dart-define=API_BASE_URL=%API% || goto :erreur
  copy /y "build\app\outputs\flutter-apk\app-release.apk" "dist\JOEM-prod.apk" >nul || goto :erreur
  echo === OK : dist\JOEM-prod.apk ===
)
start "" explorer "%~dp0dist"
exit /b 0

:erreur
echo.
echo === ECHEC de la construction : voir les messages ci-dessus ===
exit /b 1
