# Security Policy

## Supported versions

| Version | Supported |
| ------- | --------- |
| `main` (latest) | Yes |

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Use [GitHub Private Vulnerability Reporting](https://github.com/QuantumLogicsLabs/QuantumChat-MobileApp/security/advisories/new).

Include reproduction steps, affected screens/flows, device/OS details, and impact. Prefer
non-destructive PoCs.

### What to expect

- Triage acknowledgement
- Coordinated fix and disclosure
- Credit when appropriate and desired

## In scope

- Private key / keyring exposure (logs, `keys.txt` export, `flutter_secure_storage` misuse)
- Plaintext message leakage to the network or to disk (caches, backups, crash reports)
- Broken seal/unseal or key-import validation (`lib/crypto/`)
- Auth/session token exposure (storage, logging, deep links)
- Dependency issues with a realistic exploit path in this app

## Out of scope

- Users who lose `keys.txt` or uninstall the app without backing up keys
- Compromised or rooted/jailbroken devices (general)
- Backend-only issues (report to [QuantumChat-Backend](https://github.com/QuantumLogicsLabs/QuantumChat-Backend))
- Web client-only issues (report to [QuantumChat-Frontend](https://github.com/QuantumLogicsLabs/QuantumChat-Frontend))

## Key handling

- Keys are generated on-device and stored via `flutter_secure_storage` (Keystore on Android,
  Keychain on iOS) — see `lib/crypto/key_storage.dart`.
- `keys.txt` is shown once at signup as a manual backup; it is not retained by the app after the
  unlock/import flow completes.
- Login never generates new keys. A device without a matching keyring must import `keys.txt` or
  generate a fresh pool — old ciphertext stays unreadable either way.
- Logout clears the session token only; the keyring stays in secure storage.

## Safe harbor

Good-faith research that follows this policy and avoids abusing real users' data will not be
pursued legally by the maintainers.
