import java.util.Properties

// Signing credentials live outside the repo: android/.gitignore excludes both
// key.properties and *.jks. A missing file is not an error here, so a debug
// build still works on a machine that has no release key — the release build
// type is what refuses to fall back.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.KHEasyDev.easy_plate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time APIs that need backporting
        // on older Android releases.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.KHEasyDev.easy_plate"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Firebase Auth/Firestore require API 23; maxOf keeps whatever Flutter
        // asks for when its own floor is higher.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storePath = keystoreProperties.getProperty("storeFile")
            if (storePath != null) {
                // Resolved against android/app, which is where key.properties
                // names the file relative to.
                storeFile = file(storePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Play rejects anything signed with the debug key, so a release
            // build without credentials must fail loudly rather than quietly
            // produce an artefact that cannot be uploaded.
            if (keystoreProperties.getProperty("storeFile") == null) {
                throw GradleException(
                    "Release build needs android/key.properties with storeFile, " +
                        "storePassword, keyAlias and keyPassword."
                )
            }
            signingConfig = signingConfigs.getByName("release")

            // Native crashes arrive unsymbolicated without this, and Play warns
            // on every upload that debug symbols are missing. SYMBOL_TABLE
            // rather than FULL: it symbolicates stack traces just as well and
            // costs a fraction of the bundle size, since FULL carries complete
            // DWARF debug info for the whole Flutter engine.
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
