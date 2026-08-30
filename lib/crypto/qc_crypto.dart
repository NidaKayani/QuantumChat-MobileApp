import 'dart:convert';
import 'dart:math';

import 'package:pinenacl/x25519.dart';

const keySetSize = 5;

class KeyPairHex {
  const KeyPairHex({required this.publicKey, required this.secretKey});
  final String publicKey;
  final String secretKey;
}

class SealedEnvelope {
  const SealedEnvelope({
    required this.ciphertext,
    required this.nonce,
    required this.ephemeralPublicKey,
    required this.targetPublicKey,
  });

  final String ciphertext;
  final String nonce;
  final String ephemeralPublicKey;
  final String targetPublicKey;

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'nonce': nonce,
        'ephemeralPublicKey': ephemeralPublicKey,
        'targetPublicKey': targetPublicKey,
      };

  factory SealedEnvelope.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('Missing envelope');
    }
    return SealedEnvelope(
      ciphertext: json['ciphertext'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      ephemeralPublicKey: (json['ephemeralPublicKey'] as String? ?? '').toLowerCase(),
      targetPublicKey: (json['targetPublicKey'] as String? ?? '').toLowerCase(),
    );
  }
}

String toHex(Uint8List bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}

Uint8List fromHex(String hex) {
  final clean = hex.trim().toLowerCase();
  if (clean.length.isOdd) {
    throw const FormatException('Odd-length hex string');
  }
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

KeyPairHex generateKeyPair() {
  final secret = PrivateKey.generate();
  return KeyPairHex(
    publicKey: toHex(Uint8List.fromList(secret.publicKey)),
    secretKey: toHex(Uint8List.fromList(secret)),
  );
}

List<KeyPairHex> generateKeySet([int size = keySetSize]) {
  return List.generate(size, (_) => generateKeyPair());
}

String pickRandom(List<String> keys) {
  if (keys.isEmpty) {
    throw StateError('Cannot pick from an empty key list');
  }
  return keys[Random.secure().nextInt(keys.length)];
}

/// X25519 secret keys deterministically produce one public key.
String derivePublicKey(String secretKeyHex) {
  final secret = PrivateKey(fromHex(secretKeyHex));
  return toHex(Uint8List.fromList(secret.publicKey));
}

/// Sealed-box construction matching `frontend/src/crypto/keys.js`:
/// ephemeral X25519 + `nacl.box` (XSalsa20-Poly1305). Private keys never leave the device.
SealedEnvelope sealMessage(String plaintext, String targetPublicKeyHex) {
  return sealBytes(Uint8List.fromList(utf8.encode(plaintext)), targetPublicKeyHex);
}

SealedEnvelope sealBytes(Uint8List bytes, String targetPublicKeyHex) {
  final sealed = sealFileBytes(bytes, targetPublicKeyHex);
  return SealedEnvelope(
    ciphertext: base64Encode(sealed.cipherBytes),
    nonce: sealed.nonce,
    ephemeralPublicKey: sealed.ephemeralPublicKey,
    targetPublicKey: sealed.targetPublicKey,
  );
}

/// Raw-byte seal for attachments (matches website `sealBytes` in keys.js).
class SealedFileBytes {
  const SealedFileBytes({
    required this.cipherBytes,
    required this.nonce,
    required this.ephemeralPublicKey,
    required this.targetPublicKey,
  });

  final Uint8List cipherBytes;
  final String nonce;
  final String ephemeralPublicKey;
  final String targetPublicKey;
}

SealedFileBytes sealFileBytes(Uint8List bytes, String targetPublicKeyHex) {
  final ephemeral = PrivateKey.generate();
  final box = Box(
    myPrivateKey: ephemeral,
    theirPublicKey: PublicKey(fromHex(targetPublicKeyHex)),
  );
  final nonce = Uint8List.fromList(List<int>.generate(24, (_) => Random.secure().nextInt(256)));
  final encrypted = box.encrypt(bytes, nonce: nonce);
  return SealedFileBytes(
    cipherBytes: Uint8List.fromList(encrypted.cipherText),
    nonce: base64Encode(Uint8List.fromList(encrypted.nonce)),
    ephemeralPublicKey: toHex(Uint8List.fromList(ephemeral.publicKey)),
    targetPublicKey: targetPublicKeyHex.toLowerCase(),
  );
}

Uint8List? unsealFileBytes(
  Uint8List cipherBytes, {
  required String nonce,
  required String ephemeralPublicKey,
  required String myPrivateKeyHex,
}) {
  try {
    final box = Box(
      myPrivateKey: PrivateKey(fromHex(myPrivateKeyHex)),
      theirPublicKey: PublicKey(fromHex(ephemeralPublicKey)),
    );
    final opened = box.decrypt(EncryptedMessage(
      cipherText: cipherBytes,
      nonce: base64Decode(nonce),
    ));
    return Uint8List.fromList(opened);
  } catch (_) {
    return null;
  }
}

class SecretBoxSealed {
  const SecretBoxSealed({
    required this.cipherBytes,
    required this.nonce,
    required this.key,
  });

  final Uint8List cipherBytes;
  final String nonce;
  final String key;
}

SecretBoxSealed secretboxSeal(Uint8List bytes) {
  final key = PineNaClUtils.randombytes(SecretBox.keyLength);
  final box = SecretBox(key);
  final encrypted = box.encrypt(bytes);
  return SecretBoxSealed(
    cipherBytes: Uint8List.fromList(encrypted.cipherText),
    nonce: base64Encode(Uint8List.fromList(encrypted.nonce)),
    key: base64Encode(Uint8List.fromList(key)),
  );
}

Uint8List? secretboxOpen(Uint8List cipherBytes, String nonceB64, String keyB64) {
  try {
    final box = SecretBox(base64Decode(keyB64));
    final opened = box.decrypt(EncryptedMessage(
      cipherText: cipherBytes,
      nonce: base64Decode(nonceB64),
    ));
    return Uint8List.fromList(opened);
  } catch (_) {
    return null;
  }
}

String? unsealMessage(SealedEnvelope envelope, String myPrivateKeyHex) {
  final plain = unsealBytes(envelope, myPrivateKeyHex);
  if (plain == null) return null;
  return utf8.decode(plain, allowMalformed: false);
}

Uint8List? unsealBytes(SealedEnvelope envelope, String myPrivateKeyHex) {
  try {
    final box = Box(
      myPrivateKey: PrivateKey(fromHex(myPrivateKeyHex)),
      theirPublicKey: PublicKey(fromHex(envelope.ephemeralPublicKey)),
    );
    final cipher = EncryptedMessage(
      cipherText: base64Decode(envelope.ciphertext),
      nonce: base64Decode(envelope.nonce),
    );
    final opened = box.decrypt(cipher);
    return Uint8List.fromList(opened);
  } catch (_) {
    return null;
  }
}

String formatKeyFile({
  required String username,
  required String email,
  required List<String> secretKeys,
}) {
  return [
    'QuantumChat Private Keys',
    'Account: $email ($username)',
    'Generated: ${DateTime.now().toUtc().toIso8601String()}',
    '',
    'KEEP THIS FILE SECRET. Anyone who has it can read your messages.',
    'To use QuantumChat on another device, log in there and',
    'upload this file when asked for your private keys.',
    '',
    ...secretKeys,
    '',
  ].join('\n');
}

List<String> parseKeyFile(String text) {
  final matches = RegExp(r'\b[0-9a-f]{64}\b', caseSensitive: false).allMatches(text);
  return matches.map((m) => m.group(0)!.toLowerCase()).toList();
}
