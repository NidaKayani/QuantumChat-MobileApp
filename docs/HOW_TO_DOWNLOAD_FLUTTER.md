# How to download Flutter

This project targets **Flutter 3.38+** (Dart SDK `>=3.5.0 <4.0.0`, see
[`pubspec.yaml`](../pubspec.yaml)). Use the stable channel — not beta/dev/master.

## 1. Install

Pick your OS and follow the official installer (fastest path is `flutter downgrade`/`upgrade`
inside your existing install if you already have Flutter, or the `flutter` version manager /
FVM if you juggle multiple projects):

### Windows

1. Download the latest stable zip: https://docs.flutter.dev/get-started/install/windows
2. Extract it somewhere **without spaces or admin-restricted paths**, e.g. `C:\src\flutter`
   (avoid `C:\Program Files\flutter`).
3. Add `C:\src\flutter\bin` to your `PATH` (User `Path` variable, not System, unless you need it
   for all users).
4. Open a **new** terminal so the `PATH` change takes effect.

### macOS

```bash
brew install --cask flutter
```

or download the zip from https://docs.flutter.dev/get-started/install/macos and add
`flutter/bin` to your shell profile's `PATH`.

### Linux

```bash
sudo snap install flutter --classic
```

or download the tarball from https://docs.flutter.dev/get-started/install/linux and add
`flutter/bin` to `PATH`.

## 2. Verify

```bash
flutter --version
flutter doctor
```

`flutter doctor` should show no blockers for the platforms you're building. It will also flag
missing Android SDK / Xcode / CocoaPods pieces — install what it points at.

Android Studio isn't required if you already have the Android SDK and command-line tools
installed and `ANDROID_SDK_ROOT`/`ANDROID_HOME` set; `flutter doctor` will tell you if it can't
find the SDK.

## 3. Point this project at your SDK (Android only)

`mobileApp/android/local.properties` isn't committed (see `.gitignore`) — it's generated the
first time you run `flutter pub get` or `flutter run` from `mobileApp/`. If you ever see
`flutter.sdk not set in local.properties` (covered in [BUILD.md](BUILD.md)), create it manually:

```properties
flutter.sdk=C:\\src\\flutter
```

(use your actual install path; on macOS/Linux this is a normal forward-slash path).

## 4. Get project dependencies

```bash
cd mobileApp
flutter pub get
```

Then continue with the [README](../README.md) to run the app, or [BUILD.md](BUILD.md) for
Android/iOS toolchain setup and known build issues.

## Switching Flutter versions

If a teammate is on a different Flutter version than the one this repo expects, mismatched
`pubspec.lock` resolutions or Gradle/Kotlin plugin versions are the usual symptom. Check the
currently active version and channel with `flutter --version`, and switch channel with
`flutter channel stable && flutter upgrade` if you're not already on stable.
