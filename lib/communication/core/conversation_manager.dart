import 'package:bnox/core/contact_manager.dart';
import 'message.dart';
import 'message_manager.dart';

class Conversation {
  final Contact contact;
  final Message? lastMessage;
  final int unreadCount; // <-- AJOUTÉ

  Conversation({required this.contact, this.lastMessage, this.unreadCount = 0});

  DateTime get sortDate => lastMessage?.timestamp ?? contact.addedAt;
}

class ConversationManager {
  ConversationManager._();

  static Future<List<Conversation>> getConversations(String accountId) async {
    final contacts = await ContactManager.getContacts(accountId);
    final list = <Conversation>[];

    for (final c in contacts) {
      final msgs = await MessageManager.getMessages(accountId: accountId, contactId: c.bnoxId);
      if (msgs.isNotEmpty) {
        msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final unread = await MessageManager.getUnreadCount(accountId: accountId, contactId: c.bnoxId);
        
        list.add(Conversation(
          contact: c, 
          lastMessage: msgs.last,
          unreadCount: unread,
        ));
      }
    }
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return list;
  }
}