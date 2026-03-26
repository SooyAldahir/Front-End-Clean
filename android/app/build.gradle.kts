import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.aldahirballina.FamiliasEDI301"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.aldahirballina.FamiliasEDI301"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Solo asigna si key.properties existe y tiene todas las propiedades
            if (keystorePropertiesFile.exists()) {
                keyAlias     = keystoreProperties["keyAlias"]?.toString()      ?: ""
                keyPassword  = keystoreProperties["keyPassword"]?.toString()   ?: ""
                storeFile    = keystoreProperties["storeFile"]?.let { project.file(it.toString()) }
                storePassword= keystoreProperties["storePassword"]?.toString() ?: ""
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Debug usa el signing de debug por defecto — sin cambios
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Si no hay key.properties, usa debug signing para poder compilar
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
}