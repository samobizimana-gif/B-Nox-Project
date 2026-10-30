import 'dart:convert';

class Message {
  final String id;
  final String from;
  final String to;
  final String text;
  final String nonce;
  final String ciphertext;
  final String mac;
  final DateTime timestamp;
  final String signature;
  final String senderPublicEd;
  final String senderPublicX;
  
  // Champs pour les fichiers
  final String? filePath;
  final String? fileHash;

  bool? verified;
  bool delivered;
  bool read;

  Message({
    required this.id,
    required this.from,
    required this.to,
    required this.text,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
    required this.timestamp,
    required this.signature,
    required this.senderPublicEd,
    required this.senderPublicX,
    this.filePath,
    this.fileHash,
    this.verified,
    this.delivered = false,
    this.read = false,
  });

  String get signedContent => '$from|$to|$nonce|$ciphertext|$mac|${timestamp.toIso8601String()}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'text': text,
        'nonce': nonce,
        'ciphertext': ciphertext,
        'mac': mac,
        'timestamp': timestamp.toIso8601String(),
        'signature': signature,
        'sender_public_ed': senderPublicEd,
        'sender_public_x': senderPublicX,
        'file_path': filePath,
        'file_hash': fileHash,
        'delivered': delivered,
        'read': read,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] ?? '',
        from: json['from'] ?? '',
        to: json['to'] ?? '',
        text: json['text'] ?? '',
        nonce: json['nonce'] ?? '',
        ciphertext: json['ciphertext'] ?? '',
        mac: json['mac'] ?? '',
        timestamp: DateTime.parse(json['timestamp']),
        signature: json['signature'] ?? '',
        senderPublicEd: json['sender_public_ed'] ?? '',
        senderPublicX: json['sender_public_x'] ?? '',
        filePath: json['file_path'],
        fileHash: json['file_hash'],
        delivered: json['delivered'] ?? false,
        read: json['read'] ?? false,
      );
}