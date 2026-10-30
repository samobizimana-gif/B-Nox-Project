import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RecoveryManager {
  RecoveryManager._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _key(String bnoxId) => 'recovery_$bnoxId';

  /// Génère une phrase BIP-39 (12 mots français) et la sauvegarde.
  static Future<List<String>> generateAndSaveWords(String bnoxId) async {
    // Utilisation de la syntaxe correcte du package bip39_mnemonic
    final mnemonic = Mnemonic.generate(
      Language.french,
      length: MnemonicLength.words12,
    );
    
    final sentence = mnemonic.sentence;
    await _storage.write(key: _key(bnoxId), value: sentence);
    
    return mnemonic.words;
  }

  /// Charge la phrase stockée.
  static Future<List<String>> loadWords(String bnoxId) async {
    final raw = await _storage.read(key: _key(bnoxId));
    if (raw == null || raw.isEmpty) return [];
    return raw.split(' ');
  }

  /// Vérifie si les mots saisis correspondent à ceux stockés.
  static Future<bool> verifyWords({
    required String bnoxId,
    required List<String> words,
  }) async {
    final stored = await loadWords(bnoxId);
    if (stored.length != 12 || words.length != 12) return false;
    
    for (int i = 0; i < 12; i++) {
      if (stored[i].toLowerCase().trim() != words[i].toLowerCase().trim()) {
        return false;
      }
    }
    return true;
  }

  /// Supprime la phrase (pour la suppression de compte).
  static Future<void> deleteWords(String bnoxId) async {
    await _storage.delete(key: _key(bnoxId));
  }
}