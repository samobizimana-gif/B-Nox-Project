import 'dart:async';
import 'dart:convert';
import 'package:bnox/widgets/message_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/account_manager.dart';
import '../../core/contact_manager.dart';
import '../../core/notification_manager.dart'; // <-- IMPORT NOTIFICATION
import '../core/message.dart';
import '../core/message_manager.dart';
import '../transport/inbox_manager.dart';
import '../transport/transport_manager.dart';

class ChatScreen extends StatefulWidget {
  final Account account;
  final Contact contact;

  const ChatScreen({super.key, required this.account, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};
  StreamSubscription? _msgSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _initTransport();
    
    // Timer de rafraîchissement
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgSub?.cancel();
    TransportManager.transport?.disconnect(widget.contact.bnoxId);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

    Future<void> _load() async {
    // 1. AFFICHAGE INSTANTANÉ : On charge et affiche les messages locaux tout de suite
    final msgs = await MessageManager.getMessages(
      accountId: widget.account.bnoxId, 
      contactId: widget.contact.bnoxId,
    );
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    if (!mounted) return;
    setState(() { 
      _messages = msgs; 
      _loading = false; 
    });
    _scrollToBottom();

    // 2. MARQUER COMME LU (CORRECTION DU BUG)
    // On dit au système que la conversation est ouverte, donc les messages ne sont plus "non lus"
    await MessageManager.markAsRead(
      accountId: widget.account.bnoxId, 
      contactId: widget.contact.bnoxId,
    );
    await MessageManager.markMessagesAsRead(
      accountId: widget.account.bnoxId, 
      contactId: widget.contact.bnoxId,
    );

    // 3. VÉRIFICATION EN ARRIÈRE-PLAN (Cryptographie)
    // On vérifie les signatures sans bloquer l'affichage
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var m in _messages) {
        final isVerified = await MessageManager.verifyMessage(m);
        if (mounted && m.verified != isVerified) {
          setState(() => m.verified = isVerified);
        }
      }
    });
  }

  
  
  Future<void> _silentRefresh() async {
    if (_isSelectionMode) return;

    final msgs = await MessageManager.getMessages(accountId: widget.account.bnoxId, contactId: widget.contact.bnoxId);
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    if (mounted) {
      if (msgs.length != _messages.length) {
        setState(() { _messages = msgs; });
        _scrollToBottom();
      }
    }
  }

  void _initTransport() async {
    final transport = TransportManager.transport;
    if (transport == null) return;

    _msgSub = transport.messages.listen((msg) async {
      if (msg.from == widget.contact.bnoxId) {
        if (_messages.any((m) => m.id == msg.id)) return;
        await MessageManager.saveMessage(accountId: widget.account.bnoxId, contactId: widget.contact.bnoxId, message: msg);
        if (!mounted) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();

        // --- NOTIFICATION ICI ---
        String preview = msg.text.length > 30 ? '${msg.text.substring(0, 30)}...' : msg.text;
        await NotificationManager.showMessageNotification(
          title: 'Nouveau message de ${widget.contact.name}',
          body: preview,
        );
        // ------------------------
      }
    });

    transport.connect(widget.contact.bnoxId).catchError((e) {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    try {
      final msg = await MessageManager.createSignedMessage(
        fromBnoxId: widget.account.bnoxId,
        toBnoxId: widget.contact.bnoxId,
        recipientPublicX25519: widget.contact.publicKeyX25519,
        text: text,
      );
      
      bool sentP2P = false;
      try {
        await TransportManager.transport?.send(msg);
        sentP2P = true;
      } catch (e) {}

      if (!sentP2P) await InboxManager.depositMessage(msg);

      msg.delivered = true;
      await MessageManager.saveMessage(accountId: widget.account.bnoxId, contactId: widget.contact.bnoxId, message: msg);

      if (!mounted) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      debugPrint('Erreur envoi: $e');
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Le partage de $feature sera disponible bientôt.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMessageIds.contains(id)) {
        _selectedMessageIds.remove(id);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(id);
      }
    });
  }

  void _deleteSelected() async {
    for (String id in _selectedMessageIds) {
      await MessageManager.deleteMessage(accountId: widget.account.bnoxId, contactId: widget.contact.bnoxId, messageId: id);
    }
    setState(() {
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
    _load();
  }

  void _showMessageOptions(Message m) {
    if (_isSelectionMode) {
      _toggleSelection(m.id);
      return;
    }

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
              leading: Icon(Icons.check_circle_outline, color: textColor),
              title: Text('Sélectionner', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                setState(() { _isSelectionMode = true; _selectedMessageIds.add(m.id); });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Supprimer pour moi', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await MessageManager.deleteMessage(accountId: widget.account.bnoxId, contactId: widget.contact.bnoxId, messageId: m.id);
                _load();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('Annuler', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF1A2238) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _isSelectionMode 
        ? AppBar(
            backgroundColor: BnoxColors.violet,
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() { _isSelectionMode = false; _selectedMessageIds.clear(); })),
            title: Text('${_selectedMessageIds.length} sélectionné(s)', style: const TextStyle(color: Colors.white)),
            actions: [IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: _deleteSelected)],
          )
        : AppBar(
            backgroundColor: bgColor,
            title: Text(widget.contact.name, style: TextStyle(color: textColor)),
            iconTheme: IconThemeData(color: textColor),
          ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: BnoxColors.cyan))
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final isMe = m.from == widget.account.bnoxId;
                    final isSelected = _selectedMessageIds.contains(m.id);

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(m),
                      onTap: () { if (_isSelectionMode) _toggleSelection(m.id); },
                      child: Container(
                        color: isSelected ? BnoxColors.cyan.withOpacity(0.2) : Colors.transparent,
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                            decoration: BoxDecoration(
                              color: isMe ? BnoxColors.violet : inputBgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m.text, style: TextStyle(color: isMe ? Colors.white : textColor, fontSize: 15)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}', style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                                    if (isMe) MessageStatusIcon(delivered: m.delivered, read: m.read),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(color: bgColor, border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2)))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.image_outlined, color: Colors.grey), onPressed: () => _showComingSoon('images')),
                    IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () => _showComingSoon('fichiers')),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                        decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(22)),
                        child: TextField(
                          controller: _msgCtrl,
                          maxLines: null,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: const InputDecoration(hintText: 'Message...', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: BnoxColors.violet, shape: BoxShape.circle),
                      child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _send),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}