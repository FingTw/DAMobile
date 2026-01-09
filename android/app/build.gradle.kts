plugins {
    id("com.android.application")
    // Plugin này bắt buộc để đọc file google-services.json
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.untitled3" // Đảm bảo cái này khớp package name của bạn
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.untitled3"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// --- THÊM KHỐI DEPENDENCIES NÀY VÀO CUỐI ---
dependencies {
    // Sử dụng Firebase BOM để tự quản lý version (khuyên dùng)
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))

    // Thư viện Messaging (để nhận thông báo)
    implementation("com.google.firebase:firebase-messaging")

    // (Tuỳ chọn) Thư viện Analytics
    implementation("com.google.firebase:firebase-analytics")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}