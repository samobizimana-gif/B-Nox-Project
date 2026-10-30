import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_manager.dart';
import 'key_storage.dart';
import 'registry_manager.dart';
import 'recovery_manager.dart';

class Account {
  final String bnoxId;
  final String displayName;
  final String? avatarPath;
  final String? username;
  final DateTime? usernameUpdatedAt; // <-- NOUVEAU
  final String publicKeyEd25519;
  final String publicKeyX25519;
  final DateTime createdAt;

  Account({
    required this.bnoxId,
    required this.displayName,
    this.avatarPath,
    this.username,
    this.usernameUpdatedAt, // <-- NOUVEAU
    required this.publicKeyEd25519,
    required this.publicKeyX25519,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'bnox_id': bnoxId,
        'display_name': displayName,
        'avatar_path': avatarPath,
        'username': username,
        'username_updated_at': usernameUpdatedAt?.toIso8601String(), // <-- NOUVEAU
        'pub_ed': publicKeyEd25519,
        'pub_x': publicKeyX25519,
        'created_at': createdAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        bnoxId: json['bnox_id'],
        displayName: json['display_name'],
        avatarPath: json['avatar_path'],
        username: json['username'],
        usernameUpdatedAt: json['username_updated_at'] != null 
            ? DateTime.parse(json['username_updated_at']) 
            : null, // <-- NOUVEAU
        publicKeyEd25519: json['pub_ed'] ?? '',
        publicKeyX25519: json['pub_x'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
      );
}

class AccountManager {
  AccountManager._();
  static const _accountsKey = 'bnox_accounts';

  static Future<Account> createAccount({required String displayName}) async {
    final prefs = await SharedPreferences.getInstance();

    final keyPairs = await CryptoManager.generateKeyPairs();
    final bnoxId = CryptoManager.bnoxIdFromPublicKey(keyPairs.ed25519PublicBase64);

    await KeyStorage.savePrivateEd(bnoxId: bnoxId, value: keyPairs.ed25519PrivateBase64);
    await KeyStorage.savePrivateX(bnoxId: bnoxId, value: keyPairs.x25519PrivateBase64);
    await KeyStorage.savePublicEd(bnoxId: bnoxId, value: keyPairs.ed25519PublicBase64);
    await KeyStorage.savePublicX(bnoxId: bnoxId, value: keyPairs.x25519PublicBase64);
    await KeyStorage.saveSeed(bnoxId: bnoxId, seedBase64: keyPairs.seedBase64);

    await RecoveryManager.generateAndSaveWords(bnoxId);

    final account = Account(
      bnoxId: bnoxId,
      displayName: displayName,
      publicKeyEd25519: keyPairs.ed25519PublicBase64,
      publicKeyX25519: keyPairs.x25519PublicBase64,
      createdAt: DateTime.now(),
    );

    final accounts = await getAccounts();
    accounts.add(account);
    await _saveAccounts(prefs, accounts);

    await RegistryManager.publishAccount(
      bnoxId: account.bnoxId,
      publicKeyEd25519: account.publicKeyEd25519,
      publicKeyX25519: account.publicKeyX25519,
    );

    return account;
  }

  static Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Account.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Account?> findById(String bnoxId) async {
    final accounts = await getAccounts();
    for (final a in accounts) {
      if (a.bnoxId == bnoxId) return a;
    }
    return null;
  }

  static Future<Account> updateAccount({
    required String bnoxId,
    String? displayName,
    String? avatarPath,
    String? username,
    DateTime? usernameUpdatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.bnoxId == bnoxId);
    if (index == -1) throw Exception('Compte introuvable');

    final old = accounts[index];
    final updated = Account(
      bnoxId: old.bnoxId,
      displayName: displayName ?? old.displayName,
      avatarPath: avatarPath ?? old.avatarPath,
      username: username ?? old.username,
      usernameUpdatedAt: usernameUpdatedAt ?? old.usernameUpdatedAt,
      publicKeyEd25519: old.publicKeyEd25519,
      publicKeyX25519: old.publicKeyX25519,
      createdAt: old.createdAt,
    );

    accounts[index] = updated;
    final raw = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsKey, raw);
    
    await RegistryManager.publishProfile(
      bnoxId: updated.bnoxId,
      displayName: updated.displayName,
      avatarBase64: updated.avatarPath,
      username: updated.username,
    );

    return updated;
  }

  static Future<void> _saveAccounts(SharedPreferences prefs, List<Account> accounts) async {
    final raw = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsKey, raw);
  }
}