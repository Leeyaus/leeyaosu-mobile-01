// android/app/build.gradle.kts
import java.util.Properties
import java.io.FileInputStream

// --- 讀取 keystore 設定 ---
val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) {
    keystoreProperties.load(FileInputStream(keystoreFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter 官方 Gradle 外掛（新版 Flutter 會自動處理依賴）
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter 專案根目錄（保持預設）
flutter {
    source = "../.."
}

android {
    // ⚠️ 與你的套件名一致（若你仍用預設就維持這個值）
    namespace = "com.yaosulee.mobile"

    // 建議與你環境相容的 SDK / NDK 版本
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        // ⚠️ 與上方 namespace 同步（若需上架，建議改成 com.yaosulee.app）
        applicationId = "com.yaosulee.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = 1          // 上架每次要 +1
        versionName = "1.0.1"    // 自訂版本字串
    }

    // --- 簽章設定（讀取 key.properties） ---
    signingConfigs {
        create("release") {
            // 若 key.properties 存在才設定；避免本地沒有檔案時 build 失敗
            if (keystoreFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"]!!)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
    getByName("debug") {
        isMinifyEnabled = false
        isShrinkResources = false
    }
    getByName("release") {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
        signingConfig = signingConfigs.getByName("release")
    }
}

    // Java / Kotlin 17（對應 AGP 8+）
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    //（可選）避免某些 META-INF 衝突
    packaging {
        resources.excludes += setOf(
            "META-INF/DEPENDENCIES",
            "META-INF/LICENSE",
            "META-INF/LICENSE.txt",
            "META-INF/license.txt",
            "META-INF/NOTICE",
            "META-INF/NOTICE.txt",
            "META-INF/notice.txt",
            "META-INF/ASL2.0"
        )
    }
}

// 依賴由 Flutter 外掛注入，通常這裡不需要手動新增
dependencies {
    // 留空即可；需要原生庫再視需要加
}
