import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as sha;
import 'package:cryptography/cryptography.dart';

class BnoxKeyPairs {
  final SimpleKeyPair ed25519;
  final SimplePublicKey ed25519Public;
  final SimpleKeyPair x25519;
  final SimplePublicKey x25519Public;
  final String ed25519PublicBase64;
  final String x25519PublicBase64;
  final String ed25519PrivateBase64;
  final String x25519PrivateBase64;
  final String seedBase64;

  BnoxKeyPairs({
    required this.ed25519,
    required this.ed25519Public,
    required this.x25519,
    required this.x25519Public,
    required this.ed25519PublicBase64,
    required this.x25519PublicBase64,
    required this.ed25519PrivateBase64,
    required this.x25519PrivateBase64,
    required this.seedBase64,
  });
}

class CryptoManager {
  CryptoManager._();

  static final _ed25519 = Ed25519();
  static final _x25519 = X25519();
  static final _aesGcm = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  // ============================================================
  // 1. Génération des deux paires à partir d'une seed unique
  // ============================================================
  static Future<BnoxKeyPairs> generateKeyPairs() async {
    final rnd = Random.secure();
    final seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = rnd.nextInt(256);
    }
    return await deriveKeyPairs(seed);
  }

  static Future<BnoxKeyPairs> deriveKeyPairs(Uint8List seed) async {
    // Ed25519 (Signature)
    final ed25519 = await _ed25519.newKeyPairFromSeed(seed);
    final ed25519Public = await ed25519.extractPublicKey();
    final ed25519PrivateBytes = await ed25519.extractPrivateKeyBytes();

    // X25519 (Chiffrement) dérivée via HKDF
    final x25519Seed = await _hkdf.deriveKey(
      secretKey: SecretKey(seed),
      nonce: utf8.encode('bnox-x25519'),
      info: utf8.encode('encryption'),
    );

    final x25519 = await _x25519.newKeyPairFromSeed(
      await x25519Seed.extractBytes(),
    );
    final x25519Public = await x25519.extractPublicKey();
    final x25519PrivateBytes = await x25519.extractPrivateKeyBytes();

    return BnoxKeyPairs(
      ed25519: ed25519,
      ed25519Public: ed25519Public,
      x25519: x25519,
      x25519Public: x25519Public,
      ed25519PublicBase64: base64Encode(ed25519Public.bytes),
      x25519PublicBase64: base64Encode(x25519Public.bytes),
      ed25519PrivateBase64: base64Encode(ed25519PrivateBytes),
      x25519PrivateBase64: base64Encode(x25519PrivateBytes),
      seedBase64: base64Encode(seed),
    );
  }

  // ============================================================
  // 2. Reconstruction (pour la connexion)
  // ============================================================
  static Future<SimpleKeyPair> ed25519FromPrivate(String privateBase64) async {
    return await _ed25519.newKeyPairFromSeed(base64Decode(privateBase64));
  }

  static Future<SimpleKeyPair> x25519FromPrivate(String privateBase64) async {
    return await _x25519.newKeyPairFromSeed(base64Decode(privateBase64));
  }

  // ============================================================
  // 3. B-NOX ID (Hash de la clé publique Ed25519)
  // ============================================================
  static String bnoxIdFromPublicKey(String ed25519PublicBase64) {
    const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    final pubBytes = base64Decode(ed25519PublicBase64);
    final hash = sha.sha256.convert(pubBytes).bytes;

    final buffer = StringBuffer();
    for (int i = 0; i < 9; i++) {
      buffer.write(alphabet[hash[i] % alphabet.length]);
    }

    final raw = buffer.toString();
    return 'BNX-${raw.substring(0, 3)}-${raw.substring(3, 6)}-${raw.substring(6, 9)}';
  }

  // ============================================================
  // 4. Signature / Vérification
  // ============================================================
  static Future<String> sign({
    required String privateKeyBase64,
    required String message,
  }) async {
    final keyPair = await ed25519FromPrivate(privateKeyBase64);
    final signature = await _ed25519.sign(utf8.encode(message), keyPair: keyPair);
    return base64Encode(signature.bytes);
  }

  static Future<bool> verify({
    required String publicKeyBase64,
    required String message,
    required String signatureBase64,
  }) async {
    try {
      final pubBytes = base64Decode(publicKeyBase64);
      final sigBytes = base64Decode(signatureBase64);
      final publicKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final signature = Signature(sigBytes, publicKey: publicKey);

      return await _ed25519.verify(utf8.encode(message), signature: signature);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // 5. Chiffrement X25519 + AES-256-GCM
  // ============================================================
  static Future<Map<String, String>> encrypt({
    required String senderPrivateX25519Base64,
    required String recipientPublicX25519Base64,
    required String plaintext,
  }) async {
    final senderPrivate = await x25519FromPrivate(senderPrivateX25519Base64);
    final recipientPubBytes = base64Decode(recipientPublicX25519Base64);
    final recipientPublic = SimplePublicKey(recipientPubBytes, type: KeyPairType.x25519);

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: senderPrivate,
      remotePublicKey: recipientPublic,
    );

    final aesKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('bnox-aes'),
      info: utf8.encode('message-encryption'),
    );

    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: aesKey,
      nonce: nonce,
    );

    return {
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  static Future<String?> decrypt({
    required String recipientPrivateX25519Base64,
    required String senderPublicX25519Base64,
    required String nonceBase64,
    required String ciphertextBase64,
    required String macBase64,
  }) async {
    try {
      final recipientPrivate = await x25519FromPrivate(recipientPrivateX25519Base64);
      final senderPubBytes = base64Decode(senderPublicX25519Base64);
      final senderPublic = SimplePublicKey(senderPubBytes, type: KeyPairType.x25519);

      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: recipientPrivate,
        remotePublicKey: senderPublic,
      );

      final aesKey = await _hkdf.deriveKey(
        secretKey: sharedSecret,
        nonce: utf8.encode('bnox-aes'),
        info: utf8.encode('message-encryption'),
      );

      final secretBox = SecretBox(
        base64Decode(ciphertextBase64),
        nonce: base64Decode(nonceBase64),
        mac: Mac(base64Decode(macBase64)),
      );

      final clear = await _aesGcm.decrypt(secretBox, secretKey: aesKey);
      return utf8.decode(clear);
    } catch (_) {
      return null;
    }
  }

  static String generateChallenge() {
    final rnd = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return base64Encode(bytes);
  }
}