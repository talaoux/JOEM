@echo off
rem Construit l'APK JOEM installable sur un telephone, branche sur l'API du PC.
rem
rem   build-apk.bat                  -> API sur http://192.168.1.70:8000/api
rem   build-apk.bat 192.168.1.42     -> autre adresse IP du PC
rem
rem Resultat : dist\JOEM.apk (a copier sur le telephone).
setlocal
set "IP=%~1"
if "%IP%"=="" set "IP=192.168.1.70"
set "API=http://%IP%:8000/api"

cd /d "%~dp0"
echo.
echo === Construction de l'APK JOEM (API : %API%) ===
echo.
call flutter pub get || goto :erreur
call flutter build apk --release --dart-define=API_BASE_URL=%API% || goto :erreur

if not exist dist mkdir dist
copy /y "build\app\outputs\flutter-apk\app-release.apk" "dist\JOEM.apk" >nul || goto :erreur
echo.
echo === OK : dist\JOEM.apk (API : %API%) ===
start "" explorer "%~dp0dist"
exit /b 0

:erreur
echo.
echo === ECHEC de la construction : voir les messages ci-dessus ===
exit /b 1
