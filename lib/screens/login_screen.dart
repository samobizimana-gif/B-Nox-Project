import 'package:flutter/material.dart';
import '../core/account_manager.dart';
import '../core/session_manager.dart';
import '../core/recovery_manager.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _wordsCtrl = TextEditingController();
  String? _error;

  Future<void> _login() async {
    final id = _idCtrl.text.trim().toUpperCase();
    final words = _wordsCtrl.text.trim().toLowerCase().split(RegExp(r'\s+'));

    if (words.length != 12) {
      setState(() => _error = 'La phrase doit contenir exactement 12 mots.');
      return;
    }

    final account = await AccountManager.findById(id);
    if (account == null) {
      setState(() => _error = 'B-NOX ID introuvable sur cet appareil.');
      return;
    }

    final valid = await RecoveryManager.verifyWords(bnoxId: id, words: words);
    if (!valid) {
      setState(() => _error = 'Phrase de récupération incorrecte.');
      return;
    }

    await SessionManager.setActiveAccount(id);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(account: account)));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: IconThemeData(color: textColor)
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Se connecter', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _idCtrl,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(labelText: 'B-NOX ID', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _wordsCtrl,
              maxLines: 3,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(
                labelText: 'Phrase de récupération (12 mots)',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'mot1 mot2 mot3...',
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(onPressed: _login, child: const Text('Se connecter')),
            ),
          ],
        ),
      ),
    );
  }
}