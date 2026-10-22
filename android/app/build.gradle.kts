import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing with the upload key (scripts/create-upload-key.sh). android/key.properties and the keystore
// are never committed. Without them (CI, a fresh clone) release builds fall back to the debug key.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.goawaygo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published on Google Play. Must match the package name of the Android OAuth client
        // in Google Cloud (project goaway-483709) and the iOS bundle ID.
        applicationId = "com.goawaygo.app"
        // Android 8.0 (API 26) or newer: required by sentry_flutter 10 (crash reporting). Phones on Android 7 can't
        // install the app; the website's /download page says so. iOS: 15.0 (ios/, same reason).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // The 64-bit-only build (flutter build apk --target-platform android-arm64, scripts/release-android.sh)
        // must contain no other ABI folders: plugins ship libraries for every ABI, and a 32-bit phone would install
        // the APK and then crash for lack of the Flutter engine. With only arm64-v8a, those phones refuse it cleanly.
        if (project.findProperty("target-platform") == "android-arm64") {
            logger.lifecycle("GoAwayGo: 64-bit-only build, other ABIs excluded")
            packaging { jniLibs { excludes += listOf("lib/armeabi-v7a/**", "lib/x86_64/**", "lib/x86/**") } }
        }
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) signingConfigs.getByName("upload") else signingConfigs.getByName("debug")
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
