import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/constants.dart';
import '../../core/account_manager.dart';
import '../../core/contact_manager.dart';
import '../../core/recovery_manager.dart';
import 'edit_profile_screen.dart';
import 'qr_screen.dart';

class MyProfileScreen extends StatefulWidget {
  final Account account;
  const MyProfileScreen({super.key, required this.account});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late Account _account;
  int _contactCount = 0;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final contacts = await ContactManager.getContacts(_account.bnoxId);
    if (mounted) {
      setState(() => _contactCount = contacts.length);
    }
  }

  // --- FORMATAGE DE LA DATE EN FRANÇAIS ---
  String _formatDate(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return 'Inscrit le ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: _account.bnoxId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('B-NOX ID copié !'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _shareProfile() async {
    await Share.share(
      'Rejoins-moi sur B-NOX !\n\nMon ID : ${_account.bnoxId}\nMon username : @${_account.username ?? _account.displayName.toLowerCase()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Mon Profil', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: BnoxColors.primaryGradient,
                  boxShadow: [BoxShadow(color: BnoxColors.violet.withOpacity(0.4), blurRadius: 24)],
                ),
                child: _account.avatarPath != null
                  ? ClipOval(child: Image.file(File(_account.avatarPath!), fit: BoxFit.cover, width: 100, height: 100))
                  : Center(child: Text(_account.displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 16),
              Text(_account.displayName, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
              if (_account.username != null) ...[
                const SizedBox(height: 4),
                Text('@${_account.username}', style: const TextStyle(color: BnoxColors.cyan, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 10),
              
              // --- STATISTIQUES (DATE FORMATÉE) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Text(_formatDate(_account.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Text('$_contactCount contact${_contactCount > 1 ? 's' : ''}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),

              const SizedBox(height: 30),

              // Carte B-NOX ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.15))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('B-NOX ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(_account.bnoxId, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: _copyId, icon: const Icon(Icons.copy_rounded, color: BnoxColors.cyan, size: 22)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bouton QR Code
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrScreen(account: _account))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [BnoxColors.violet.withOpacity(0.1), BnoxColors.cyan.withOpacity(0.1)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BnoxColors.violet.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, color: BnoxColors.violet, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mon QR Code', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Scannez pour m\'ajouter instantanément', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // --- MENU PROFIL ---
              _menuTile(
                icon: Icons.edit,
                title: 'Modifier le profil',
                subtitle: 'Nom, photo, @username',
                onTap: () async {
                  final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditProfileScreen(account: _account)));
                  if (updated == true) {
                    final acc = await AccountManager.findById(_account.bnoxId);
                    if (acc != null) setState(() => _account = acc);
                  }
                },
                cardColor: cardColor, textColor: textColor,
              ),
              
              _menuTile(
                icon: Icons.share,
                title: 'Partager mon profil',
                onTap: _shareProfile,
                cardColor: cardColor, textColor: textColor,
              ),

              _menuTile(
                icon: Icons.vpn_key_outlined,
                title: 'Phrase de récupération',
                subtitle: 'Vos 12 mots secrets',
                onTap: () async {
                  var words = await RecoveryManager.loadWords(_account.bnoxId);
                  if (words.isEmpty) words = await RecoveryManager.generateAndSaveWords(_account.bnoxId);
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: cardColor,
                      title: Text('Phrase de récupération', style: TextStyle(color: textColor)),
                      content: Text(words.join(' '), style: const TextStyle(color: BnoxColors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
                      actions: [
                        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: words.join(' '))); Navigator.pop(context); }, child: const Text('Copier')),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                      ],
                    ),
                  );
                },
                cardColor: cardColor, textColor: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap, required Color cardColor, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.withOpacity(0.15))),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
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
}