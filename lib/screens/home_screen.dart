import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/account_manager.dart';
import '../core/session_manager.dart';
import '../core/sync_manager.dart';
import '../contact/screens/contacts_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../settings/screens/my_profile_screen.dart';
import '../communication/core/conversation_manager.dart';
import '../communication/screens/chat_screen.dart';
import 'more_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final Account account;
  const HomeScreen({super.key, required this.account});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  bool _loading = true;
  Timer? _refreshTimer;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await SyncManager.syncInbox(widget.account.bnoxId);
    final list =
        await ConversationManager.getConversations(widget.account.bnoxId);
    if (!mounted) return;
    setState(() {
      _conversations = list;
      _filteredConversations = list;
      _loading = false;
    });
  }

  Future<void> _silentRefresh() async {
    if (_currentTab != 0) return;
    await SyncManager.syncInbox(widget.account.bnoxId);
    final list =
        await ConversationManager.getConversations(widget.account.bnoxId);
    if (mounted) {
      if (list.length != _conversations.length ||
          (list.isNotEmpty &&
              _conversations.isNotEmpty &&
              list.first.lastMessage?.id !=
                  _conversations.first.lastMessage?.id)) {
        setState(() {
          _conversations = list;
          _onSearch(_searchCtrl.text);
        });
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations
            .where((c) =>
                c.contact.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showMenu(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.person_outline, color: textColor),
              title: Text('Mon profil', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTab = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await SessionManager.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: [
            _buildDiscussions(), // 0
            ContactsScreen(account: widget.account), // 1
            SettingsScreen(account: widget.account), // 2
            MyProfileScreen(account: widget.account), // 3
            const MoreScreen(), // 4
          ],
        ),
      ),
      bottomNavigationBar: _buildFixedBottomNav(),
    );
  }

  Widget _buildDiscussions() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final headerColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B1020)
        : Colors.white;
    final inputBgColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A2238)
        : Colors.white;

    return Column(
      children: [
        // --- EN-TÊTE (SANS LE "J") ---
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          color: headerColor,
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                  children: const [
                    TextSpan(text: 'B-'),
                    TextSpan(
                        text: 'NOX', style: TextStyle(color: BnoxColors.cyan)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _currentTab = 3),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: BnoxColors.violet,
                  child: Text(
                    widget.account.displayName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                  onPressed: () => _showMenu(context),
                  icon: Icon(Icons.more_vert, color: textColor)),
            ],
          ),
        ),

        // --- BARRE DE RECHERCHE AMÉLIORÉE ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.grey, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),

        // --- LISTE DES DISCUSSIONS ---
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: BnoxColors.cyan))
              : _filteredConversations.isEmpty
                  ? _buildEmptyState(textColor)
                  : ListView.separated(
                      itemCount: _filteredConversations.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.withOpacity(0.1),
                        height: 1,
                        indent: 76,
                      ),
                      itemBuilder: (_, i) {
                        final c = _filteredConversations[i];
                        return ListTile(
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                        account: widget.account,
                                        contact: c.contact)));
                            _load();
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: BnoxColors.violet,
                              child: Text(c.contact.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold))),
                          title: Text(c.contact.name,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(c.lastMessage?.text ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                c.lastMessage != null
                                    ? '${c.lastMessage!.timestamp.hour}:${c.lastMessage!.timestamp.minute.toString().padLeft(2, '0')}'
                                    : '',
                                style: TextStyle(
                                    color: c.unreadCount > 0
                                        ? BnoxColors.cyan
                                        : Colors.grey,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              if (c.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: BnoxColors.cyan,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text('${c.unreadCount}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text('Aucune discussion',
              style: TextStyle(
                  color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Commencez une conversation depuis l\'onglet Contacts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFixedBottomNav() {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? BnoxColors.cyan.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) {
          setState(() => _currentTab = i);
          if (i == 0) _load();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: BnoxColors.cyan,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Contacts'),
          BottomNavigationBarItem(
            icon: _SettingsIcon(isSelected: false),
            activeIcon: _SettingsIcon(isSelected: true),
            label: 'Paramètres',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.apps),
              activeIcon: Icon(Icons.apps),
              label: 'Plus'),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final bool isSelected;
  const _SettingsIcon({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: isSelected
            ? BnoxColors.primaryGradient
            : LinearGradient(colors: [
                BnoxColors.violet.withOpacity(0.3),
                BnoxColors.cyan.withOpacity(0.3)
              ]),
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: BnoxColors.violet.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Icon(
        Icons.settings,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black54),
        size: 20,
      ),
    );
  }
}
