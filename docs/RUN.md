# Running the app

Assumes Flutter is installed ([HOW_TO_DOWNLOAD_FLUTTER.md](HOW_TO_DOWNLOAD_FLUTTER.md)) and, if
`android/`/`ios/` are missing or incomplete, that you've run `flutter create .` per the
[README](../README.md#first-time-platform-files).

## 1. Start the backend

```bash
cd backend
npm run dev   # http://localhost:5000
```

## 2. Get dependencies

```bash
cd mobileApp
flutter pub get
```

## 3. Pick a target and run

### Android emulator

List configured AVDs, launch one, then run:

```bash
flutter emulators
flutter emulators --launch Pixel_7   # or whatever your AVD is named
flutter run
```

The app's default API URL is `http://10.0.2.2:5000` — the emulator's alias for the host
machine's `localhost`. Change it in Settings → Server if your backend runs elsewhere.

### iOS simulator (macOS only)

```bash
open -a Simulator
flutter run
```

Default API URL is `http://localhost:5000`.

### Physical device

```bash
flutter devices   # confirm it's detected (USB debugging / trust this computer)
flutter run
```

Set the API URL in Settings to your computer's LAN address, e.g. `http://192.168.1.20:5000` —
`10.0.2.2`/`localhost` don't resolve to your host machine from a real device. Make sure the
backend's CORS allowlist includes that origin; native apps usually send no `Origin` header,
which the backend already allows.

### Production backend

```bash
flutter run --dart-define=API_URL=https://quantum-chat-backend.vercel.app
```

Vercel hosting has no Socket.IO — the app falls back to REST polling against that backend.

## Hot reload / restart

With `flutter run` attached: `r` for hot reload, `R` for hot restart, `q` to quit. Hot reload
won't pick up changes to `main.dart` bootstrapping (storage/auth/theme init) or native
(Android/iOS) code — use hot restart or re-run for those.

## Troubleshooting

- **Nothing in `flutter devices`**: for Android, check `adb devices` shows the emulator/device;
  for a physical device, confirm USB debugging is on and you accepted the "trust this computer"
  prompt.
- **App can't reach the backend**: see the API URL notes above — this is almost always a
  `10.0.2.2` vs `localhost` vs LAN-IP mismatch, not a real network issue.
- **Build/Gradle errors**: see [BUILD.md](BUILD.md).
