import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Contact {
  final String bnoxId;
  final String name;
  final String publicKeyEd25519;
  final String publicKeyX25519;
  final bool verified;
  final DateTime addedAt;

  Contact({
    required this.bnoxId,
    required this.name,
    required this.publicKeyEd25519,
    required this.publicKeyX25519,
    required this.verified,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'bnox_id': bnoxId,
        'name': name,
        'pub_ed': publicKeyEd25519,
        'pub_x': publicKeyX25519,
        'verified': verified,
        'added_at': addedAt.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        bnoxId: json['bnox_id'],
        name: json['name'],
        publicKeyEd25519: json['pub_ed'] ?? '',
        publicKeyX25519: json['pub_x'] ?? '',
        verified: json['verified'] ?? false,
        addedAt: DateTime.parse(json['added_at']),
      );
}

class ContactManager {
  ContactManager._();

  static String _key(String accountId) => 'contacts_$accountId';

  static Future<List<Contact>> getContacts(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(accountId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Contact.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> exists({required String accountId, required String bnoxId}) async {
    final contacts = await getContacts(accountId);
    return contacts.any((c) => c.bnoxId == bnoxId);
  }

  static Future<Contact> addContact({
    required String accountId,
    required String bnoxId,
    required String name,
    required String publicKeyEd25519,
    required String publicKeyX25519,
    required bool verified,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getContacts(accountId);

    final contact = Contact(
      bnoxId: bnoxId,
      name: name,
      publicKeyEd25519: publicKeyEd25519,
      publicKeyX25519: publicKeyX25519,
      verified: verified,
      addedAt: DateTime.now(),
    );

    contacts.add(contact);
    
    final raw = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_key(accountId), raw);
    
    return contact;
  }

  // --- NOUVELLE MÉTHODE DE SUPPRESSION ---
  static Future<void> deleteContact({
    required String accountId,
    required String bnoxId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getContacts(accountId);
    contacts.removeWhere((c) => c.bnoxId == bnoxId);
    final raw = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_key(accountId), raw);
  }
}