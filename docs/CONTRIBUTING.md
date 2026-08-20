# Contributing to QuantumChat Mobile

Thanks for contributing to the QuantumChat Flutter client for Android and iOS. It talks to the
same backend as the web app and holds the same client-side X25519 / NaCl keyring: private keys
never leave the phone.

## Before you start

1. Read [`docs/REQUIREMENTS.md`](https://github.com/QuantumLogicsLabs/QuantumChat/blob/main/docs/REQUIREMENTS.md) (E2E X5 rules).
2. Follow the [Code of Conduct](CODE_OF_CONDUCT.md).
3. Report vulnerabilities via [SECURITY.md](SECURITY.md), not public issues.
4. For Gradle/Xcode toolchain setup and known build issues, see [BUILD.md](BUILD.md).

## Development setup

```bash
cd mobileApp
flutter pub get
flutter run
```

You need a running [QuantumChat-Backend](https://github.com/QuantumLogicsLabs/QuantumChat-Backend)
(`npm run dev` → `http://localhost:5000`). See the [README](../README.md) for emulator vs. device
API URLs — the Android emulator uses `10.0.2.2`, not `localhost`.

## Checks before a PR

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

Do not introduce:

- Logging of private keys, seeds, or `keys.txt` contents (`avoid_print` is intentionally off in
  [`analysis_options.yaml`](../analysis_options.yaml), so this isn't caught automatically — review
  it by hand)
- Key material stored outside `flutter_secure_storage` (see `lib/crypto/key_storage.dart`)
- Sending message plaintext to the API or QuantumAI without an explicit client opt-in path
- Breaking the sealed-box round trip covered by `test/crypto_test.dart`

## Pull requests

1. Keep changes focused.
2. Preserve client-held keys and X5 sealed-box behavior — the server should never need plaintext.
3. Add or update a test in `test/` when touching `lib/crypto/`.
4. Note any platform-specific setup a reviewer needs (Android SDK, Xcode) in the PR description —
   there's no CI configured on this repo yet, so builds are verified locally.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](../LICENSE).
