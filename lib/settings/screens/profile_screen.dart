import 'dart:io';

import 'package:bnox/core/session_manager.dart';
import 'package:bnox/screens/welcome_screen.dart';
import 'package:bnox/settings/screens/edit_profile_screen.dart';
import 'package:bnox/settings/screens/qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/account_manager.dart';
import '../../core/recovery_manager.dart';
import '../../core/theme_manager.dart';
import 'security_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Account account;
  const ProfileScreen({super.key, required this.account});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Account _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: _account.bnoxId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('B-NOX ID copié'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B1020)
        : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: BnoxColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                        color: BnoxColors.violet.withOpacity(0.4),
                        blurRadius: 24)
                  ],
                ),
                child: _account.avatarPath != null
                    ? ClipOval(
                        child: Image.file(File(_account.avatarPath!),
                            fit: BoxFit.cover, width: 100, height: 100))
                    : Center(
                        child: Text(
                          _account.displayName.isNotEmpty
                              ? _account.displayName[0].toUpperCase()
                              : 'N',
                          style: const TextStyle(
                              color: BnoxColors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
              ),

              const SizedBox(height: 16),
              // Nom + badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_account.displayName,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: BnoxColors.cyan, shape: BoxShape.circle),
                    child: const Icon(Icons.check,
                        color: BnoxColors.dark, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('@${_account.displayName.toLowerCase()}',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 26),
              // Carte B-NOX ID
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BnoxColors.violet.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('B-NOX ID',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(_account.bnoxId,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _copyId,
                      icon: const Icon(Icons.copy_rounded,
                          color: BnoxColors.violet, size: 22),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // --- MENU ---

              // Bouton QR Code
              _menuTile(
                icon: Icons.qr_code,
                title: 'Mon QR code',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QrScreen(account: _account),
                    ),
                  );
                },
                cardColor: cardColor,
                textColor: textColor,
              ),

              _menuTile(
                icon: Icons.edit,
                title: 'Modifier le profil',
                onTap: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditProfileScreen(account: _account)),
                  );
                  if (updated == true) {
                    // Rafraîchir les données
                    final acc = await AccountManager.findById(_account.bnoxId);
                    if (acc != null) setState(() => _account = acc);
                  }
                },
                cardColor: cardColor,
                textColor: textColor,
              ),

              // Bouton Thème
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeManager.themeMode,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return _menuTile(
                    icon: isDark ? Icons.light_mode : Icons.dark_mode,
                    title: isDark
                        ? 'Passer en mode clair'
                        : 'Passer en mode sombre',
                    onTap: () => ThemeManager.toggleTheme(!isDark),
                    cardColor: cardColor,
                    textColor: textColor,
                  );
                },
              ),

              // Bouton Sécurité
              _menuTile(
                icon: Icons.shield_outlined,
                title: 'Sécurité & confidentialité',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SecurityScreen(account: _account))),
                cardColor: cardColor,
                textColor: textColor,
              ),

              // Bouton Phrase de récupération
              _menuTile(
                icon: Icons.vpn_key_outlined,
                title: 'Ma phrase de récupération',
                onTap: () async {
                  var words = await RecoveryManager.loadWords(_account.bnoxId);
                  if (words.isEmpty) {
                    words = await RecoveryManager.generateAndSaveWords(
                        _account.bnoxId);
                  }

                  if (!mounted) return;

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: cardColor,
                      title: Text('Phrase de récupération',
                          style: TextStyle(color: textColor)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notez ces 12 mots. Ils sont la seule façon de restaurer votre compte.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            words.join(' '),
                            style: const TextStyle(
                                color: BnoxColors.cyan,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.5),
                          ),
                        ],
                      ),
                      actions: [
                        // BOUTON COPIER
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: words.join(' ')));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Phrase copiée dans le presse-papiers !'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          },
                          child: const Text('Copier',
                              style: TextStyle(color: BnoxColors.cyan)),
                        ),
                        // BOUTON FERMER
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  );
                },
                cardColor: cardColor,
                textColor: textColor,
              ),

              // Déconnexion (à ajouter)
              _menuTile(
                icon: Icons.logout,
                title: 'Se déconnecter',
                onTap: () async {
                  await SessionManager.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                cardColor: cardColor,
                textColor: Colors.redAccent,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      required Color cardColor,
      required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500))),
              Icon(Icons.chevron_right, color: Colors.grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
