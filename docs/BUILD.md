# Build guide

Build setup, current toolchain versions, and known issues for the Android and iOS builds.

## Prerequisites

- Flutter 3.38+ / Dart SDK `>=3.5.0 <4.0.0` (`flutter doctor` should show no blockers)
- Android: Android Studio or the command-line SDK, JDK 17
- iOS: macOS + Xcode (CocoaPods installed)

## First-time platform files

`android/` and `ios/` are checked in, but if either is missing or incomplete (a fresh clone can
lack `ios/Runner.xcodeproj`, `ios/Podfile`, etc.):

```bash
cd mobileApp
flutter create . --project-name quantumchat --org labs.quantumlogics --platforms android,ios
```

This regenerates platform scaffolding only — it does not touch `lib/`.

## Android

Current pinned versions (`android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties`):

| Component | Version |
| --- | --- |
| Gradle | 8.12 |
| Android Gradle Plugin (AGP) | 8.10.1 |
| Kotlin | 2.2.20 |
| `compileSdk` / `targetSdk` | 35 |
| Java | 17 |

```bash
cd mobileApp
flutter run -d <device-id>          # debug
flutter build apk --release         # release APK
flutter build appbundle --release   # Play Store bundle
```

The release build type currently reuses the **debug signing config**
(`android/app/build.gradle.kts`) — that's fine for local/side-loaded builds, but a real signing
config (keystore + `key.properties`) is needed before shipping a release build anywhere else.

### Known issue: AGP version does not exist

`settings.gradle.kts` previously pinned `com.android.application` to `8.10.2`, which Gradle failed
to resolve from Google/MavenCentral/Gradle Plugin Portal with:

```
Plugin [id: 'com.android.application', version: '8.10.2', apply: false] was not found
```

That version was never published — Google's Maven metadata jumps `8.10.0` → `8.10.1` → `8.11.0`,
with no `8.10.2` patch. It's pinned to `8.10.1` now (compatible with Gradle 8.12). If this shows up
again after bumping the AGP version, check the real version list before pinning:

```bash
curl -s https://dl.google.com/android/maven2/com/android/tools/build/gradle/maven-metadata.xml
```

### Gradle wrapper distribution

`gradle-wrapper.properties` may point `distributionUrl` at a local file path (e.g.
`file:///C:/Android/gradle-8.12-all.zip`) instead of `services.gradle.org`, as a workaround for
slow/unreliable downloads of the ~200 MB Gradle distribution on some machines. This is
machine-specific — if that path doesn't exist on your machine, either download the matching
Gradle zip yourself and update the path, or point `distributionUrl` back at the standard
`https://services.gradle.org/distributions/gradle-8.12-all.zip`.

## iOS

```bash
cd mobileApp
flutter build ios --release   # or open ios/Runner.xcworkspace in Xcode after `pod install`
```

Set the bundle identifier and signing team in Xcode (`ios/Runner.xcworkspace` → Runner target →
Signing & Capabilities) before archiving.

## Troubleshooting

- **Stale plugin/dependency resolution after editing Gradle files**: `flutter clean` then re-run.
- **`flutter.sdk not set in local.properties`**: run `flutter pub get` once from `mobileApp/`, or
  create `android/local.properties` with `flutter.sdk=<path-to-flutter-sdk>`.
- **Emulator can't reach a local backend**: use `10.0.2.2`, not `localhost`, from the Android
  emulator (see the [README](../README.md)).
