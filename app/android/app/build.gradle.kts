import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // lê src/<flavor>/google-services.json
    id("com.google.firebase.crashlytics") // símbolos para os relatórios de travamento
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de publicação (docs/app.md#publicar-no-android): android/key.properties, fora do git.
val arquivoChave = rootProject.file("key.properties")
val chave = Properties().apply { if (arquivoChave.exists()) load(FileInputStream(arquivoChave)) }

android {
    namespace = "br.com.promocaonamao.promocao_na_mao"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.promocaonamao.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavors: cada um é um app separado no celular e um projeto Firebase próprio.
    //   flutter run --flavor dev --dart-define-from-file=config/dev.json
    // AdMob: o ID do app vai no manifest (sem ele o SDK fecha o app ao abrir). Dev: ID de teste do Google;
    // prod: ADMOB_APP_ID do config/prod.json (público, vai dentro do APK).
    val admobTeste = "ca-app-pub-3940256099942544~3347511713"
    val admobProd = rootProject.file("../config/prod.json").takeIf { it.exists() }
        ?.let { (groovy.json.JsonSlurper().parse(it) as Map<*, *>)["ADMOB_APP_ID"] as String? }.orEmpty()
    flavorDimensions += "ambiente"
    productFlavors {
        create("dev") {
            dimension = "ambiente"
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Promoção DEV"
            manifestPlaceholders["linkHost"] = "promocaonamao-f08a7.web.app"
            manifestPlaceholders["admobAppId"] = admobTeste
        }
        create("prod") {
            dimension = "ambiente"
            manifestPlaceholders["appName"] = "Promoção na Mão"
            manifestPlaceholders["linkHost"] = "www.promocaonamao.com.br"
            manifestPlaceholders["admobAppId"] = admobProd.ifEmpty { admobTeste }
        }
    }

    signingConfigs {
        create("release") {
            if (arquivoChave.exists()) {
                keyAlias = chave["keyAlias"] as String
                keyPassword = chave["keyPassword"] as String
                storeFile = file(chave["storeFile"] as String)
                storePassword = chave["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Nunca publicar com a chave de debug (a loja recusa e os App Links ficariam presos a ela).
            if (!arquivoChave.exists() && gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
                throw GradleException("Falta android/key.properties com a chave de publicação (docs/app.md#publicar-no-android)")
            }
            if (admobProd.isEmpty() && gradle.startParameter.taskNames.any { it.contains("ProdRelease", ignoreCase = true) }) {
                throw GradleException("Falta ADMOB_APP_ID no config/prod.json (docs/app.md#anúncios-no-app-admob)")
            }
            signingConfig = signingConfigs.getByName("release")
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

dependencies {
    // O AdMob (play-services-ads 25.4) traz o WorkManager 2.7.0 (2021), que no release com R8 fecha o app ao abrir:
    // Room não acha o WorkDatabase_Impl (Crashlytics, 0.2.0). O 2.11+ traz Room novo com as regras certas.
    implementation("androidx.work:work-runtime:2.12.0")
}
