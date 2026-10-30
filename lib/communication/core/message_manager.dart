import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/crypto_manager.dart';
import '../../core/key_storage.dart';
import 'message.dart';

class MessageManager {
  MessageManager._();

  static String _key(String acc, String con) {
    final p = [acc, con]..sort();
    return 'chat_${p[0]}__${p[1]}';
  }

  static String _lastReadKey(String acc, String con) {
    final p = [acc, con]..sort();
    return 'last_read_${p[0]}__${p[1]}';
  }

  // ============================================================
  // Création et Envoi
  // ============================================================
  static Future<Message> createSignedMessage({
    required String fromBnoxId,
    required String toBnoxId,
    required String recipientPublicX25519,
    required String text,
    String? filePath,
    String? fileHash,
  }) async {
    final privEd = await KeyStorage.loadPrivateEd(fromBnoxId);
    final privX = await KeyStorage.loadPrivateX(fromBnoxId);
    final pubEd = await KeyStorage.loadPublicEd(fromBnoxId);
    final pubX = await KeyStorage.loadPublicX(fromBnoxId);

    if (privEd == null || privX == null || pubEd == null || pubX == null) {
      throw Exception('Clés manquantes.');
    }

    final encrypted = await CryptoManager.encrypt(
      senderPrivateX25519Base64: privX,
      recipientPublicX25519Base64: recipientPublicX25519,
      plaintext: text,
    );

    final timestamp = DateTime.now();
    final id = _generateId();

    final message = Message(
      id: id,
      from: fromBnoxId,
      to: toBnoxId,
      text: text,
      nonce: encrypted['nonce']!,
      ciphertext: encrypted['ciphertext']!,
      mac: encrypted['mac']!,
      timestamp: timestamp,
      signature: '',
      senderPublicEd: pubEd,
      senderPublicX: pubX,
      filePath: filePath,
      fileHash: fileHash,
    );

    final signature = await CryptoManager.sign(
      privateKeyBase64: privEd,
      message: message.signedContent,
    );

    return Message(
      id: id,
      from: fromBnoxId,
      to: toBnoxId,
      text: text,
      nonce: encrypted['nonce']!,
      ciphertext: encrypted['ciphertext']!,
      mac: encrypted['mac']!,
      timestamp: timestamp,
      signature: signature,
      senderPublicEd: pubEd,
      senderPublicX: pubX,
      filePath: filePath,
      fileHash: fileHash,
      verified: true,
      delivered: true,
    );
  }

  static Future<Message> createDeleteSignal({
    required String fromBnoxId,
    required String toBnoxId,
    required String recipientPublicX25519,
    required String messageIdToDelete,
  }) async {
    final signalText = '{"action": "DELETE", "target_id": "$messageIdToDelete"}';
    return await createSignedMessage(
      fromBnoxId: fromBnoxId,
      toBnoxId: toBnoxId,
      recipientPublicX25519: recipientPublicX25519,
      text: signalText,
    );
  }

  // ============================================================
  // Vérification et Déchiffrement
  // ============================================================
  static Future<bool> verifyMessage(Message m) async {
    final recomputedId = CryptoManager.bnoxIdFromPublicKey(m.senderPublicEd);
    if (recomputedId != m.from) return false;
    return await CryptoManager.verify(
      publicKeyBase64: m.senderPublicEd,
      message: m.signedContent,
      signatureBase64: m.signature,
    );
  }

  static Future<String?> decryptMessage({
    required Message m,
    required String recipientBnoxId,
  }) async {
    final privX = await KeyStorage.loadPrivateX(recipientBnoxId);
    if (privX == null) return null;
    return await CryptoManager.decrypt(
      recipientPrivateX25519Base64: privX,
      senderPublicX25519Base64: m.senderPublicX,
      nonceBase64: m.nonce,
      ciphertextBase64: m.ciphertext,
      macBase64: m.mac,
    );
  }

  // ============================================================
  // Stockage
  // ============================================================
  static Future<List<Message>> getMessages({required String accountId, required String contactId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(accountId, contactId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Message.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- LA MÉTHODE CORRIGÉE EST ICI ---
  static Future<void> saveMessage({required String accountId, required String contactId, required Message message}) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getMessages(accountId: accountId, contactId: contactId);
    
    // Anti-doublon strict par ID
    if (messages.any((m) => m.id == message.id)) return;

    messages.add(message);
    final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_key(accountId, contactId), raw);
  }

  static Future<void> deleteMessage({
    required String accountId,
    required String contactId,
    required String messageId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getMessages(accountId: accountId, contactId: contactId);
    messages.removeWhere((m) => m.id == messageId);
    final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_key(accountId, contactId), raw);
  }

  static Future<void> deleteConversation({
    required String accountId,
    required String contactId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(accountId, contactId));
  }

  // ============================================================
  // Non-lus
  // ============================================================
  static Future<void> markAsRead({required String accountId, required String contactId}) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getMessages(accountId: accountId, contactId: contactId);
    if (messages.isEmpty) return;
    
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await prefs.setString(_lastReadKey(accountId, contactId), messages.last.id);
  }

    static Future<int> getUnreadCount({required String accountId, required String contactId}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // On récupère l'ID du dernier message lu
    final lastReadId = prefs.getString(_lastReadKey(accountId, contactId));
    final messages = await getMessages(accountId: accountId, contactId: contactId);

    // Si on n'a jamais ouvert la conversation (pas de dernier message lu)
    if (lastReadId == null) {
      // On compte TOUS les messages reçus (ce qui est le comportement actuel)
      return messages.where((m) => m.from != accountId).length;
    }

    // Si on a déjà ouvert la conversation, on cherche où se trouve ce dernier message lu
    final index = messages.indexWhere((m) => m.id == lastReadId);
    
    // Si on ne trouve pas le message lu (ex: il a été supprimé), on compte tous les messages reçus
    if (index == -1) {
      return messages.where((m) => m.from != accountId).length;
    }

    // SINON (c'est le cas normal) : on compte seulement les messages reçus APRÈS le dernier lu
    return messages.sublist(index + 1).where((m) => m.from != accountId).length;
  }

  static Future<void> markMessagesAsRead({required String accountId, required String contactId}) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getMessages(accountId: accountId, contactId: contactId);
    
    bool changed = false;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].to == accountId && !messages[i].read) {
        messages[i].read = true;
        changed = true;
      }
    }

    if (changed) {
      final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString(_key(accountId, contactId), raw);
    }
  }

  static String _generateId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }
}