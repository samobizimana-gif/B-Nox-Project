import 'dart:convert';
import '../communication/core/message_manager.dart';
import '../communication/transport/inbox_manager.dart';
import 'notification_manager.dart'; // <-- IMPORT

class SyncManager {
  SyncManager._();

  static Future<void> syncInbox(String myBnoxId) async {
    try {
      final pendingMsgs = await InboxManager.fetchMessages(myBnoxId)
          .timeout(const Duration(seconds: 2), onTimeout: () => []);
      
      for (var msg in pendingMsgs) {
        if (msg.from != myBnoxId) {
          if (msg.text.contains('"action": "DELETE"')) {
            try {
              final data = jsonDecode(msg.text);
              final targetId = data['target_id'];
              await MessageManager.deleteMessage(
                accountId: myBnoxId, 
                contactId: msg.from, 
                messageId: targetId
              );
            } catch (e) {}
            continue;
          }

          // 1. Sauvegarder le message
          await MessageManager.saveMessage(
            accountId: myBnoxId,
            contactId: msg.from,
            message: msg,
          );

          // 2. Déclencher la notification
          // On affiche un extrait du message (ou "Nouveau message" si c'est un fichier)
          String preview = msg.text.length > 30 ? '${msg.text.substring(0, 30)}...' : msg.text;
          await NotificationManager.showMessageNotification(
            title: 'Nouveau message B-NOX',
            body: preview,
          );
        }
      }
    } catch (e) {
      print('Sync ignorée (hors ligne ou erreur) : $e');
    }
  }
}