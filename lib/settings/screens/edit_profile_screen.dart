import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants.dart';
import '../../core/account_manager.dart';

class EditProfileScreen extends StatefulWidget {
  final Account account;
  const EditProfileScreen({super.key, required this.account});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.account.displayName;
    _usernameCtrl.text = widget.account.username ?? '';
    _avatarPath = widget.account.avatarPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 600);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final newPath = '${dir.path}/avatar_${widget.account.bnoxId}.jpg';
      await File(picked.path).copy(newPath);
      setState(() => _avatarPath = newPath);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final newUsername = _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim().toLowerCase();
      
      // Si on change le username, on met à jour la date
      final now = DateTime.now();
      final usernameChanged = newUsername != widget.account.username;
      final newUpdatedAt = usernameChanged ? now : widget.account.usernameUpdatedAt;

      await AccountManager.updateAccount(
        bnoxId: widget.account.bnoxId,
        displayName: _nameCtrl.text.trim(),
        avatarPath: _avatarPath,
        username: newUsername,
        usernameUpdatedAt: newUpdatedAt,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    // --- LOGIQUE DES 10 MINUTES ---
    bool isUsernameLocked = false;
    String helperText = 'Optionnel.';
    
    if (widget.account.username != null && widget.account.usernameUpdatedAt != null) {
      final diff = DateTime.now().difference(widget.account.usernameUpdatedAt!);
      if (diff.inMinutes >= 10) {
        isUsernameLocked = true;
        helperText = 'Modifiable à nouveau dans 3 mois (ou via le support).';
      } else {
        helperText = 'Vous pouvez encore le modifier (${10 - diff.inMinutes} min restantes).';
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Modifier le profil', style: TextStyle(color: textColor)), 
        iconTheme: IconThemeData(color: textColor)
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Prendre une photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choisir dans la galerie'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                      ],
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: BnoxColors.violet,
                backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                child: _avatarPath == null ? const Icon(Icons.camera_alt, color: Colors.white, size: 40) : null,
              ),
            ),
            const SizedBox(height: 30),

            // Nom d'affichage
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(labelText: 'Nom d\'affichage', labelStyle: TextStyle(color: BnoxColors.gray)),
            ),
            const SizedBox(height: 20),

            // Username avec verrouillage
            TextField(
              controller: _usernameCtrl,
              enabled: !isUsernameLocked, // <-- VERROUILLAGE ICI
              style: TextStyle(color: isUsernameLocked ? Colors.grey : textColor),
              decoration: InputDecoration(
                labelText: 'Nom d\'utilisateur (@)',
                labelStyle: const TextStyle(color: BnoxColors.gray),
                prefixText: '@ ',
                prefixStyle: const TextStyle(color: BnoxColors.cyan, fontWeight: FontWeight.bold),
                suffixIcon: isUsernameLocked ? const Icon(Icons.lock, color: Colors.grey, size: 20) : null,
                helperText: helperText,
                helperStyle: TextStyle(color: isUsernameLocked ? Colors.orange : BnoxColors.cyan, fontSize: 11),
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}