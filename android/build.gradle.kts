
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// `file_picker` détecte AGP 9+ et, pensant que le built-in Kotlin d'AGP va
// compiler ses sources, saute l'application du plugin Kotlin classique —
// alors que ce projet garde `android.builtInKotlin=false` (voir
// `gradle.properties`, `flutter_plugin_android_lifecycle` casse avec
// `true`). Sans plugin Kotlin appliqué, `FilePickerPlugin.kt` n'est
// jamais compilé ("cannot find symbol: class FilePickerPlugin" côté
// Java). On force le plugin Kotlin classique sur ce seul module.
subprojects {
    if (project.name == "file_picker") {
        project.plugins.apply("org.jetbrains.kotlin.android")
    }
}

// Force consistent JVM target across all subprojects to avoid compatibility issues
gradle.projectsEvaluated {
    subprojects.forEach { project ->
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
