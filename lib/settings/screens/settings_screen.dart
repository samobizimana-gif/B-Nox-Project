import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/session_manager.dart';
import '../../core/theme_manager.dart';
import '../../core/account_manager.dart';
import '../../core/notification_manager.dart';
import '../../screens/welcome_screen.dart';
import '../../widgets/bnox_toast.dart'; // <-- IMPORT
import 'security_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Account account;
  const SettingsScreen({super.key, required this.account});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _previewMessages = false;
  bool _blockUnknown = false;
  String _storageSize = "Calcul...";

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
      _previewMessages = prefs.getBool('preview_messages') ?? false;
      _blockUnknown = prefs.getBool('block_unknown') ?? false;
    });
    NotificationManager.isEnabled = _notificationsEnabled;
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('chat_')).toList();
    int totalChars = 0;
    for (String key in keys) {
      totalChars += (prefs.getString(key)?.length ?? 0);
    }
    setState(() {
      _storageSize = "${(totalChars / 1024).toStringAsFixed(2)} Ko";
    });
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('chat_')).toList();
    for (String key in keys) {
      await prefs.remove(key);
    }
    _calculateStorage();
    if (!mounted) return;
    BnoxToast.show(context, 'Cache des messages vidé.', icon: Icons.cleaning_services); // <-- TOAST
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Paramètres', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _sectionTitle('APPARENCE'),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeMode,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return _menuTile(
                  icon: isDark ? Icons.light_mode : Icons.dark_mode,
                  title: isDark ? 'Mode clair' : 'Mode sombre',
                  onTap: () => ThemeManager.toggleTheme(!isDark),
                );
              },
            ),
            _menuTile(
              icon: Icons.language,
              title: 'Langue',
              subtitle: 'Français',
              onTap: () => BnoxToast.show(context, 'D\'autres langues bientôt disponibles.', icon: Icons.language), // <-- TOAST
            ),

            _sectionTitle('NOTIFICATIONS'),
            _switchTile(
              icon: Icons.notifications_active_outlined,
              title: 'Activer les notifications',
              value: _notificationsEnabled,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notif_enabled', v);
                setState(() => _notificationsEnabled = v);
                NotificationManager.isEnabled = v;
              },
            ),
            _switchTile(
              icon: Icons.visibility_outlined,
              title: 'Aperçu des messages',
              subtitle: 'Afficher le contenu dans les notifications',
              value: _previewMessages,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('preview_messages', v);
                setState(() => _previewMessages = v);
              },
            ),

            _sectionTitle('SÉCURITÉ & CONFIDENTIALITÉ'),
            _menuTile(
              icon: Icons.shield_outlined,
              title: 'Sécurité & confidentialité',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SecurityScreen(account: widget.account))),
            ),
            _switchTile(
              icon: Icons.block,
              title: 'Bloquer les inconnus',
              subtitle: 'Refuser les messages hors contacts',
              value: _blockUnknown,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('block_unknown', v);
                setState(() => _blockUnknown = v);
              },
            ),

            _sectionTitle('STOCKAGE & DONNÉES'),
            _menuTile(
              icon: Icons.data_usage,
              title: 'Utilisation du stockage',
              subtitle: _storageSize,
              onTap: () {},
            ),
            _menuTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Vider le cache des messages',
              onTap: _clearCache,
            ),

            _sectionTitle('À PROPOS'),
            _menuTile(
              icon: Icons.info_outline,
              title: 'Aide & Support',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
            ),
            const ListTile(
              leading: Icon(Icons.verified_user_outlined, color: Colors.grey),
              title: Text('Version de B-NOX', style: TextStyle(color: Colors.grey, fontSize: 14)),
              trailing: Text('1.0.0', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),

            const SizedBox(height: 20),
            const Divider(),

            _menuTile(
              icon: Icons.logout,
              title: 'Se déconnecter',
              textColor: Colors.redAccent,
              onTap: () async {
                await SessionManager.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _menuTile({required IconData icon, required String title, String? subtitle, Color? textColor, required VoidCallback onTap}) {
    final cardColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;
    final color = textColor ?? Theme.of(context).colorScheme.onSurface;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
                    if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile({required IconData icon, required String title, String? subtitle, required bool value, required Function(bool) onChanged}) {
    final cardColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Icon(icon, color: textColor, size: 22),
          title: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
          subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
          value: value,
          onChanged: onChanged,
          activeColor: BnoxColors.cyan,
        ),
      ),
    );
  }
}