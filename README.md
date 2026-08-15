# QuantumChat — Mobile

Native Flutter messenger for Android and iOS. It talks to the same QuantumChat backend as the web app and uses the same client-side X25519 / NaCl sealed-box encryption: private keys never leave the phone.

## What it includes

- Landing, register, login, 2FA, forgot password
- `keys.txt` backup after signup, and an unlock gate (import keys or generate a new pool)
- Conversation list (All / Unread / Groups / Friends) with presence
- Encrypted DMs and group chats, realtime Socket.IO, typing, read/delivery ticks
- Reactions, search, new chat, create group
- Settings: profile, privacy, theme (Dark / Light / Eyecare), API URL, logout

Calls, stories, QuantumAI, and attachments are not in this first mobile cut — text messaging, groups, and the keyring match the web client.

## Prerequisites

- Flutter 3.38+ (`flutter doctor`)
- A running QuantumChat backend (`cd ../backend && npm run dev` → `http://localhost:5000`)

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
```

**Android emulator** (backend on the host machine):

```bash
flutter run
```

The default API URL is `http://10.0.2.2:5000`. Change it in Settings → Server if needed.

**iOS simulator**:

```bash
flutter run
```

Default API URL is `http://localhost:5000`.

**Physical device** — set the API URL in Settings to your computer's LAN address, e.g. `http://192.168.1.20:5000`, and make sure the backend CORS allowlist includes that origin (native apps usually send no `Origin`, which the backend already allows).

**Production backend**:

```bash
flutter run --dart-define=API_URL=https://quantum-chat-backend.vercel.app
```

Note: Vercel hosting has no Socket.IO; the app falls back to REST polling.

## Encryption (same as web)

1. Register generates a 5-key X25519 pool on device and publishes only the public halves.
2. Each DM is sealed twice (`forRecipient` + `forSender`) with `nacl.box`.
3. Groups seal one envelope per member.
4. Login does not create keys. If this device has no matching keyring, import `keys.txt` or generate a new pool (old ciphertext stays unreadable).
5. Logout clears the JWT session only — the keyring stays in secure storage.

## Project layout

```
lib/
  main.dart                 # storage, auth, theme bootstrap
  config.dart               # API / signal URLs
  crypto/                   # tweetnacl-compatible seal/unseal + keyring
  api/                      # REST + Socket.IO
  models/
  state/                    # AuthController, ChatController, ThemeController
  screens/                  # landing, auth, inbox, thread, settings
  theme/                    # QuantumChat navy / light / eyecare
```
1) how to run mobile app
cd D:\QuantumLogics\QuantumChat\mobileApp
flutter emulators --launch Pixel_7


