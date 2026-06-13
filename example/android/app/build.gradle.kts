plugins {
  id("com.android.application")
  id("dev.flutter.flutter-gradle-plugin")
}

android {
  namespace = "hu.co.tramontana.sendlog_example"
  compileSdk = flutter.compileSdkVersion
  ndkVersion = flutter.ndkVersion

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  defaultConfig {
    applicationId = "hu.co.tramontana.sendlog_example"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
  }

  buildTypes {
    getByName("release") {
      signingConfig = signingConfigs.getByName("debug")
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
  implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.22")
}