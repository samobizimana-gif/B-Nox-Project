import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/account_manager.dart';
import '../../core/contact_manager.dart';
import '../../communication/screens/chat_screen.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  final Account account;
  const ContactsScreen({super.key, required this.account});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ContactManager.getContacts(widget.account.bnoxId);
    if (!mounted) return;
    setState(() { _contacts = list; _loading = false; });
  }

  // --- MENU D'OPTIONS DU CONTACT ---
  void _showContactOptions(Contact c) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),
            
            ListTile(
              leading: Icon(Icons.info_outline, color: textColor),
              title: Text('Détails du contact', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _showContactDetails(c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Supprimer le contact', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await ContactManager.deleteContact(accountId: widget.account.bnoxId, bnoxId: c.bnoxId);
                _load();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('Annuler', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showContactDetails(Contact c) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Détails', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom : ${c.name}', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('B-NOX ID : ${c.bnoxId}', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('Vérifié : ${c.verified ? "Oui ✓" : "Non"}', style: TextStyle(color: c.verified ? Colors.green : Colors.orange)),
            const SizedBox(height: 8),
            Text('Clé Ed25519 : ${c.publicKeyEd25519.substring(0, 10)}...', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Contacts', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.person_add, color: BnoxColors.cyan, size: 28),
                    onPressed: () async {
                      final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddContactScreen(account: widget.account)));
                      if (res == true) _load();
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator(color: BnoxColors.cyan))
                : _contacts.isEmpty
                  ? const Center(child: Text('Aucun contact.\nAppuyez sur + pour en ajouter.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (_, i) {
                        final c = _contacts[i];
                        return ListTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(account: widget.account, contact: c))),
                          onLongPress: () => _showContactOptions(c), // <-- APPUI LONG ICI
                          leading: CircleAvatar(backgroundColor: BnoxColors.violet, child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                          title: Text(c.name, style: TextStyle(color: textColor)),
                          subtitle: Text(c.bnoxId, style: const TextStyle(color: Colors.grey)),
                          trailing: c.verified ? const Icon(Icons.verified, color: Color(0xFF3BE28A), size: 18) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}