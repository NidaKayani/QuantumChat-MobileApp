# QuantumChat — Mobile

Native Flutter messenger for Android and iOS. It talks to the same QuantumChat backend as the web app and uses the same client-side X25519 / NaCl sealed-box encryption: private keys never leave the phone.

## What it includes

- Landing, register, login, 2FA (login + settings setup/disable), forgot password
- `keys.txt` backup after signup, and an unlock gate (import keys or generate a new pool)
- Conversation list (All / Unread / Groups / Friends) with presence
- Friend request accept / decline
- Encrypted DMs and group chats, realtime Socket.IO, typing, read/delivery ticks
- Reactions, reply, edit, delete, copy, in-thread message search
- Attachments (gallery / camera / files) via init→upload→finalize (same as web)
- GIF picker (backend Giphy proxy)
- Mute, clear chat, block / unblock
- Stories rail (post image story, view)
- Group info: members, add member, leave / remove
- Settings: profile, avatar, privacy, password, 2FA, themes (Dark / Light / Eyecare + dreamy FX), API URL, logout

## Not in this cut yet (website has them)

- Voice / video calls and meetings (WebRTC)
- Conversation vault / key vault
- Native push (FCM / APNs) — backend push today is web VAPID-oriented
- QuantumAI, polls / events, full i18n, per-chat wallpapers
- Sealed (AES-GCM) stories — mobile posts unsealed image stories for now

## Prerequisites

- Flutter 3.38+ (`flutter doctor`)
- A running QuantumChat backend (`cd ../backend && npm run dev` → `http://localhost:5000`)
- Android SDK platforms 34–36, Build-Tools, Platform-Tools, Emulator, NDK + CMake, JDK 17

## First-time platform files

If `android/` or `ios/` are missing or incomplete:

```bash
cd mobileApp
flutter create . --project-name quantumchat --org labs.quantumlogics --platforms android,ios
```

That fills in Gradle / Xcode scaffolding without replacing `lib/`.

## Run

```bash
cd mobileApp
flutter pub get
flutter run
```

See [docs/RUN.md](docs/RUN.md) for emulator/simulator/device specifics, API URL configuration
(`10.0.2.2` vs `localhost` vs LAN IP), and running against the production backend.

## Encryption (same as web)

1. Register generates a 5-key X25519 pool on device and publishes only the public halves.
2. Each DM is sealed twice (`forRecipient` + `forSender`) with `nacl.box`.
3. Groups seal one envelope per member.
4. Attachments use the same sealed-box (DM) or secretbox (group) model as the website.
5. Login does not create keys. If this device has no matching keyring, import `keys.txt` or generate a new pool (old ciphertext stays unreadable).
6. Logout clears the JWT session only — the keyring stays in secure storage.

## Project layout

This repo targets **Android and iOS only** (no web, Windows, macOS, or Linux folders).

```
mobileApp/
  lib/          ← app screens and logic (where you work)
  android/      ← Android build wrapper
  ios/          ← iPhone build wrapper
  assets/       ← images and bundled files
  test/         ← automated tests
  pubspec.yaml  ← app name, version, and package list
  docs/         ← run/build/contributing guides
```

```
lib/
  main.dart
  config.dart
  crypto/                   # tweetnacl-compatible seal/unseal + keyring
  api/                      # REST + Socket.IO
  models/
  state/                    # AuthController, ChatController, ThemeController
  screens/                  # landing, auth, inbox, thread, settings, group info
  theme/
  widgets/                  # theme scene, stories rail, GIF picker, attachments
```

Temporary folders (`build/`, `.dart_tool/`) are recreated by Flutter — safe to delete with `flutter clean`.

## More docs

See [docs/](docs/) for contributing guidelines, build setup, and the Flutter SDK install guide.
