import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import 'generation_screen.dart';

class CreateIdentityScreen extends StatefulWidget {
  const CreateIdentityScreen({super.key});

  @override
  State<CreateIdentityScreen> createState() => _CreateIdentityScreenState();
}

class _CreateIdentityScreenState extends State<CreateIdentityScreen> {
  final _nameCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Veuillez saisir un nom.';
    if (name.length < 3) return 'Minimum 3 caractères.';
    if (name.contains(' ')) return 'Pas d\'espace autorisé.';
    if (RegExp(r'[0-9]').hasMatch(name)) return 'Pas de chiffre autorisé.';
    if (!RegExp(r'^[A-Z]').hasMatch(name)) return 'Doit commencer par une majuscule.';
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(name)) return 'Lettres uniquement.';
    return null;
  }

  void _continue() {
    final error = _validateName(_nameCtrl.text);
    setState(() => _error = error);
    if (error != null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerationScreen(displayName: _nameCtrl.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BnoxColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: BnoxColors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text(
                'Créer votre identité',
                style: TextStyle(color: BnoxColors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Votre identité sera créée localement.',
                style: TextStyle(color: BnoxColors.gray, fontSize: 14),
              ),
              const SizedBox(height: 36),
              const Text(
                'Nom d\'affichage',
                style: TextStyle(color: BnoxColors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                maxLength: 32,
                style: const TextStyle(color: BnoxColors.white),
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  hintText: 'Nox',
                  counterStyle: const TextStyle(color: BnoxColors.gray),
                  prefixIcon: const Icon(Icons.person_outline, color: BnoxColors.gray),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _error != null ? Colors.redAccent : BnoxColors.cyan.withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _error != null ? Colors.redAccent : BnoxColors.cyan, width: 1.5),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                  ),
                ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: BnoxColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text('Continuer', style: TextStyle(color: BnoxColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}