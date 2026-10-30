import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/account_manager.dart';
import '../../core/contact_manager.dart';
import '../../core/registry_manager.dart';

class AddContactScreen extends StatefulWidget {
  final Account account;
  const AddContactScreen({super.key, required this.account});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  
  String? _error;
  bool _verifying = false;
  bool _saving = false;
  
  String _pubEd = '';
  String _pubX = '';
  
  // Pour l'UI : Savoir si on cherche par ID ou par @username
  bool _isSearchingById = true; 

  void _toggleSearchMode(bool isById) {
    setState(() {
      _isSearchingById = isById;
      _idCtrl.clear();
      _error = null;
      _pubEd = '';
      _pubX = '';
    });
  }

  Future<void> _verifyId() async {
    final input = _idCtrl.text.trim();
    setState(() { _error = null; _pubEd = ''; _pubX = ''; });

    if (input.isEmpty) return;

    RegistryEntry? entry;

    if (_isSearchingById) {
      entry = await RegistryManager.lookup(input.toUpperCase());
    } else {
      // On s'assure que le @ est bien géré par la méthode lookupByUsername
      entry = await RegistryManager.lookupByUsername(input);
    }

    if (!mounted) return;

    if (entry == null) {
      setState(() => _error = 'Aucun compte trouvé avec ce ${_isSearchingById ? "B-NOX ID" : "@username"}.');
      return;
    }

    if (entry.bnoxId == widget.account.bnoxId) {
      setState(() => _error = 'Vous ne pouvez pas vous ajouter vous-même.');
      return;
    }

    setState(() {
      _idCtrl.text = entry!.bnoxId; // On remplit avec le vrai ID
      _pubEd = entry.publicKeyEd25519;
      _pubX = entry.publicKeyX25519;
      if (_nameCtrl.text.isEmpty) {
        _nameCtrl.text = entry.displayName;
      }
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.length < 2) {
      setState(() => _error = 'Le nom est trop court.');
      return;
    }
    if (_pubEd.isEmpty) {
      setState(() => _error = 'Vérifiez d\'abord le contact.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ContactManager.addContact(
        accountId: widget.account.bnoxId,
        bnoxId: _idCtrl.text.trim().toUpperCase(),
        name: _nameCtrl.text.trim(),
        publicKeyEd25519: _pubEd,
        publicKeyX25519: _pubX,
        verified: true,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Erreur: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF1A2238) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Ajouter un contact', style: TextStyle(color: textColor, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- SÉLECTEUR DE MODE (ID vs USERNAME) ---
              Container(
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleSearchMode(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isSearchingById ? BnoxColors.violet : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('B-NOX ID', style: TextStyle(color: _isSearchingById ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleSearchMode(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isSearchingById ? BnoxColors.violet : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('@ Username', style: TextStyle(color: !_isSearchingById ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Nom
              Text('Nom du contact', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Ex. Aline',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                  filled: true,
                  fillColor: inputBgColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: BnoxColors.cyan, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Identifiant (ID ou Username)
              Text(_isSearchingById ? 'B-NOX ID' : 'Nom d\'utilisateur', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idCtrl,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: _isSearchingById ? 'BNX-XXX-XXX-XXX' : '@username',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: Icon(_isSearchingById ? Icons.badge_outlined : Icons.alternate_email, color: Colors.grey),
                        filled: true,
                        fillColor: inputBgColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: BnoxColors.cyan, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verifyId,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BnoxColors.violet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _verifying 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Vérifier', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),

              if (_pubEd.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3BE28A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3BE28A).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: Color(0xFF3BE28A), size: 20),
                        SizedBox(width: 10),
                        Text('Contact trouvé et vérifié', style: TextStyle(color: Color(0xFF3BE28A), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: (_pubEd.isEmpty || _saving) ? null : BnoxColors.primaryGradient,
                    color: (_pubEd.isEmpty || _saving) ? Colors.grey.withOpacity(0.2) : null,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: (_pubEd.isEmpty || _saving) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}