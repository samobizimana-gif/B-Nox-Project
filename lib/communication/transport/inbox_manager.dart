import 'package:firebase_database/firebase_database.dart';
import '../core/message.dart';

class InboxManager {
  InboxManager._();

  static DatabaseReference get _db => FirebaseDatabase.instance.ref('inbox');

  /// Dépose un message pour un destinataire (on utilise msg.to)
  static Future<void> depositMessage(Message message) async {
    try {
      await _db.child(message.to).child(message.id).set(message.toJson());
    } catch (e) {
      print('Erreur dépôt inbox: $e');
    }
  }

  /// Récupère les messages en attente pour l'utilisateur connecté
  static Future<List<Message>> fetchMessages(String myBnoxId) async {
    try {
      final snapshot = await _db.child(myBnoxId).get();
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final messages = <Message>[];
      
      data.forEach((key, value) {
        final map = Map<String, dynamic>.from(value as Map);
        map['id'] = key; // On s'assure que l'ID est bien récupéré
        messages.add(Message.fromJson(map));
      });

      // On supprime SEULEMENT les messages qu'on vient de lire pour ce compte
      await _db.child(myBnoxId).remove();

      return messages;
    } catch (e) {
      return [];
    }
  }
}