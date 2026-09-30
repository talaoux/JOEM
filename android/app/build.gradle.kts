import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Contournement Windows : Gradle reçoit la cible avec la barre oblique inverse
// doublée (`-Ptarget=lib\\main.dart`, transmis tel quel en
// `-dTargetFile=lib\\main.dart`) — le compilateur cherche alors
// `package:joem//main.dart` et le build échoue avec "Error when reading
// '/main.dart'". On normalise le chemin en barres obliques (accepté par Flutter
// sur toutes les plateformes) avant que le plugin Flutter ne le lise.
(findProperty("target") as String?)?.let { target ->
    // La valeur reçue peut déjà contenir `\\` : toute suite de `\` devient un seul `/`.
    if (target.contains('\\')) extra["target"] = target.replace(Regex("""\\+"""), "/")
}

// HTTP non chiffré : Android le bloque par défaut en release. On ne
// l'autorise que si l'API donnée au build est en `http://` (PC du réseau
// local, voir `lib/core/network/api_config.dart`) ; une API en `https://` ou
// l'absence d'API garde le blocage. Flutter transmet les `--dart-define` à
// Gradle en Base64, séparés par des virgules.
val apiBaseUrl = (findProperty("dart-defines") as String?)
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it)) }
    ?.firstOrNull { it.startsWith("API_BASE_URL=") }
    ?.substringAfter("=")
val allowCleartextHttp = apiBaseUrl?.startsWith("http://") == true

android {
    namespace = "mg.joem.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identifiant définitif sur le Play Store : ne plus le changer après la
        // première publication.
        applicationId = "mg.joem.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["usesCleartextTraffic"] = allowCleartextHttp.toString()
    }

    // Signature de production : lue depuis `android/key.properties` (exclu de
    // git, comme la clé `.jks`). Voir "Signature de production" dans
    // CLAUDE.md pour créer la clé. Sans ce fichier, le build release retombe
    // sur la clé de debug : utilisable pour tester, REFUSÉ par le Play Store.
    val keystorePropertiesFile = rootProject.file("key.properties")
    val hasReleaseKey = keystorePropertiesFile.exists()
    if (hasReleaseKey) {
        val keystoreProperties = Properties().apply {
            keystorePropertiesFile.inputStream().use { load(it) }
        }
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    } else {
        logger.warn(
            "JOEM : android/key.properties absent — build release signé avec la clé " +
                "de DEBUG (non publiable sur le Play Store).",
        )
    }

    buildTypes {
        debug {
            // Toujours autorisé en debug (flutter run vers un PC local).
            manifestPlaceholders["usesCleartextTraffic"] = "true"
        }
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
