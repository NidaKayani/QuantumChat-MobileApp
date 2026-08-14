import 'package:flutter_test/flutter_test.dart';
import 'package:quantumchat/crypto/qc_crypto.dart';

void main() {
  test('sealed box round-trips like the web client', () {
    final pair = generateKeyPair();
    final envelope = sealMessage('hello quantum', pair.publicKey);
    expect(envelope.targetPublicKey, pair.publicKey.toLowerCase());
    expect(envelope.ephemeralPublicKey.length, 64);
    final plain = unsealMessage(envelope, pair.secretKey);
    expect(plain, 'hello quantum');
  });

  test('wrong private key cannot decrypt', () {
    final a = generateKeyPair();
    final b = generateKeyPair();
    final envelope = sealMessage('secret', a.publicKey);
    expect(unsealMessage(envelope, b.secretKey), isNull);
  });

  test('derivePublicKey matches generateKeyPair', () {
    final pair = generateKeyPair();
    expect(derivePublicKey(pair.secretKey), pair.publicKey);
  });

  test('parseKeyFile extracts 64-char hex keys', () {
    final keys = parseKeyFile('QuantumChat Private Keys\nabc\n${'a' * 64}\n${'b' * 64}\n');
    expect(keys.length, 2);
    expect(keys.first, 'a' * 64);
  });
}
