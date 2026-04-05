import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Configuração para carregar as chaves de assinatura
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    // Caso não exista o arquivo (ex: no GitHub Actions), tenta ler das variáveis de ambiente
    val storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
    val keyPassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
    val keyAlias = System.getenv("ANDROID_KEY_ALIAS")
    
    if (!storePassword.isNullOrEmpty() && !keyPassword.isNullOrEmpty() && !keyAlias.isNullOrEmpty()) {
        keystoreProperties["storePassword"] = storePassword
        keystoreProperties["keyPassword"] = keyPassword
        keystoreProperties["keyAlias"] = keyAlias
        keystoreProperties["storeFile"] = "upload-keystore.jks"
    }
}

android {
    namespace = "com.example.passwmob"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.passwmob"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storePassword = keystoreProperties["storePassword"] as String?
            
            val storeFileName = keystoreProperties["storeFile"] as String?
            if (storeFileName != null) {
                // projectDir garante que ele comece a busca dentro de android/app/
                storeFile = file(projectDir.resolve(storeFileName))
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            //signingConfig = signingConfigs.getByName("debug")

            // Substituímos o debug pelo release que acabamos de configurar
            signingConfig = signingConfigs.getByName("release")
            
            // Ativa otimizações de código (opcional, mas recomendado para produção)
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
