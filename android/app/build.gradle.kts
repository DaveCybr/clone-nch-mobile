import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.jtinovation.nch_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Add signing configs
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nurulchotib"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use release signing config
            signingConfig = signingConfigs.getByName("release")
            // Enable R8/ProGuard for code obfuscation and size reduction
            isMinifyEnabled = true
            isShrinkResources = true
            // Generate debug symbols for native code
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Ensure native debug symbols are included
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        create("releaseNoMinify") {
            // Release build without minification (for testing)
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        debug {
            // Keep debug symbols for development
            isDebuggable = true
            isMinifyEnabled = false
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

dependencies {
    // Google Play Core untuk mengatasi missing class errors
    // implementation("com.google.android.play:core:1.10.3")
    // implementation("com.google.android.play:core-ktx:1.8.1")
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:review:2.0.2")
}

flutter {
    source = "../.."
}
