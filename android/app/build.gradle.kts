plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.japanese_immersion_reader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.japanese_immersion_reader"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Matches the ABIs cargoNdkBuild (below) actually cross-compiles the
        // Sudachi tokenizer's native library for -- must stay in sync with
        // that task's `-t` flags.
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
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

// Cross-compiles the Sudachi tokenizer's Rust native library
// (`rust/`, package `sudachi_tokenizer`) for Android via cargo-ndk
// (`cargo install cargo-ndk`, added by hand -- not a Gradle/Flutter plugin),
// straight into jniLibs/<abi>/ where AGP already looks for prebuilt native
// libraries -- no separate copy step needed. See
// `lib/l2_linguistics/tokenizer/native_library_loader.dart`'s Android
// branch for how the app locates this at runtime, and
// `rust/vendor/README.md` for why a vendored, locally-patched copy of the
// `sudachi` crate is needed at all to make this cross-compile succeed.
//
// Requires `cargo-ndk` on PATH and Android targets installed via
// `rustup target add aarch64-linux-android armv7-linux-androideabi
// x86_64-linux-android` -- a fresh checkout without these will fail this
// task with a clear cargo/rustup error, not a silent skip, which is
// intentional: a release APK missing this library crashes at first
// tokenizer use, not at build time, so failing loud here is safer.
val cargoNdkBuild by tasks.registering(Exec::class) {
    workingDir = file("../../rust")
    environment("ANDROID_NDK_HOME", android.ndkDirectory.absolutePath)
    commandLine(
        "cargo",
        "ndk",
        "-t", "arm64-v8a",
        "-t", "armeabi-v7a",
        "-t", "x86_64",
        "-o", file("src/main/jniLibs").absolutePath,
        "build",
        "--release",
    )
}

tasks.matching { it.name == "preBuild" }.configureEach { dependsOn(cargoNdkBuild) }
