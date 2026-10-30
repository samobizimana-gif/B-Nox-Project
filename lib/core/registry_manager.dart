import 'package:firebase_database/firebase_database.dart';
import 'crypto_manager.dart';

class RegistryEntry {
  final String bnoxId;
  final String publicKeyEd25519;
  final String publicKeyX25519;
  final String? avatarBase64;
  final String displayName;
  final String? username;

  RegistryEntry({
    required this.bnoxId,
    required this.publicKeyEd25519,
    required this.publicKeyX25519,
    this.avatarBase64,
    required this.displayName,
    this.username,
  });
}

class RegistryManager {
  RegistryManager._();
  static DatabaseReference get _db => FirebaseDatabase.instance.ref('registry');

  static Future<void> publishAccount({
    required String bnoxId,
    required String publicKeyEd25519,
    required String publicKeyX25519,
  }) async {
    try {
      await _db.child(bnoxId).set({
        'pub_ed': publicKeyEd25519,
        'pub_x': publicKeyX25519,
        'ts': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  static Future<void> publishProfile({
    required String bnoxId,
    required String displayName,
    String? avatarBase64,
    String? username,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'display_name': displayName,
      };
      if (avatarBase64 != null) data['avatar_base64'] = avatarBase64;
      if (username != null) data['username'] = username;
      await _db.child(bnoxId).update(data);
    } catch (_) {}
  }

  static Future<RegistryEntry?> lookup(String bnoxId) async {
    try {
      final snapshot = await _db.child(bnoxId).get();
      if (!snapshot.exists) return null;

      final data = snapshot.value;
      if (data is! Map) return null;

      final map = Map<String, dynamic>.from(data);
      final pubEd = map['pub_ed'] as String?;
      final pubX = map['pub_x'] as String?;

      if (pubEd == null || pubX == null) return null;

      final recomputed = CryptoManager.bnoxIdFromPublicKey(pubEd);
      if (recomputed != bnoxId) return null;

      return RegistryEntry(
        bnoxId: bnoxId,
        publicKeyEd25519: pubEd,
        publicKeyX25519: pubX,
        avatarBase64: map['avatar_base64'],
        displayName: map['display_name'] ?? 'Inconnu',
        username: map['username'],
      );
    } catch (_) {
      return null;
    }
  }

  static Future<RegistryEntry?> lookupByUsername(String username) async {
    try {
      final cleanUsername = username.replaceAll('@', '').toLowerCase();
      final snapshot = await _db.orderByChild('username').equalTo(cleanUsername).get();
      
      if (!snapshot.exists) return null;

      final data = snapshot.value;
      if (data is! Map) return null;

      final map = Map<String, dynamic>.from(data);
      final bnoxId = map.keys.first;
      final userData = Map<String, dynamic>.from(map[bnoxId] as Map);

      return RegistryEntry(
        bnoxId: bnoxId,
        publicKeyEd25519: userData['pub_ed'] ?? '',
        publicKeyX25519: userData['pub_x'] ?? '',
        avatarBase64: userData['avatar_base64'],
        displayName: userData['display_name'] ?? 'Inconnu',
        username: userData['username'],
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> unpublishAccount(String bnoxId) async {
    try {
      await _db.child(bnoxId).remove();
    } catch (_) {}
  }
}