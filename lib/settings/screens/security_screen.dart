import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/account_manager.dart';
import '../../core/security_manager.dart';

class SecurityScreen extends StatefulWidget {
  final Account account;
  const SecurityScreen({super.key, required this.account});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _loading = true;
  bool _bioSupported = false;
  bool _bioActive = false;
  bool _pinActive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supported = await SecurityManager.isBiometricAvailable();
    final methods = await SecurityManager.loadMethods(widget.account.bnoxId);

    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioActive = methods['biometric'] ?? false;
      _pinActive = methods['pin'] ?? false;
      _loading = false;
    });
  }

  Future<void> _saveMethods() async {
    await SecurityManager.saveMethods(
      bnoxId: widget.account.bnoxId,
      biometric: _bioActive,
      pin: _pinActive,
    );
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PinSetupDialog(),
      );
      if (pin == null || pin.isEmpty) return;
      
      await SecurityManager.savePin(bnoxId: widget.account.bnoxId, pin: pin);
      setState(() => _pinActive = true);
    } else {
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _VerifyPinDialog(),
      );
      if (pin == null) return;
      
      final valid = await SecurityManager.verifyPin(bnoxId: widget.account.bnoxId, pin: pin);
      if (!valid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN incorrect'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      
      await SecurityManager.savePin(bnoxId: widget.account.bnoxId, pin: '');
      setState(() => _pinActive = false);
    }
    await _saveMethods();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Sécurité & confidentialité', style: TextStyle(color: textColor, fontSize: 18)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: BnoxColors.cyan))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildSwitch(
                      'Biométrie (Empreinte)', 
                      _bioActive, 
                      _bioSupported, 
                      (v) {
                        setState(() => _bioActive = v);
                        _saveMethods();
                      },
                      cardColor, textColor
                    ),
                    const SizedBox(height: 10),
                    _buildSwitch(
                      'Code PIN (6 chiffres)', 
                      _pinActive, 
                      true, 
                      _togglePin,
                      cardColor, textColor
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, bool enabled, Function(bool) onChanged, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: TextStyle(color: enabled ? textColor : Colors.grey)),
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
        activeColor: BnoxColors.cyan,
      ),
    );
  }
}

// ============================================================
// Dialogues PIN (Adaptés au thème)
// ============================================================
class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();
  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dialogColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;

    return AlertDialog(
      backgroundColor: dialogColor,
      title: Text('Créer un PIN', style: TextStyle(color: textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pin1,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            style: TextStyle(color: textColor),
            decoration: const InputDecoration(hintText: 'Nouveau PIN (6 chiffres)'),
          ),
          TextField(
            controller: _pin2,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            style: TextStyle(color: textColor),
            decoration: const InputDecoration(hintText: 'Confirmer le PIN'),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
        TextButton(
          onPressed: () {
            if (_pin1.text.length != 6) return setState(() => _error = '6 chiffres requis');
            if (_pin1.text != _pin2.text) return setState(() => _error = 'Les PIN ne correspondent pas');
            Navigator.pop(context, _pin1.text);
          },
          child: const Text('Valider', style: TextStyle(color: BnoxColors.cyan)),
        ),
      ],
    );
  }
}

class _VerifyPinDialog extends StatefulWidget {
  const _VerifyPinDialog();
  @override
  State<_VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<_VerifyPinDialog> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dialogColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;

    return AlertDialog(
      backgroundColor: dialogColor,
      title: Text('Entrez votre PIN', style: TextStyle(color: textColor)),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        obscureText: true,
        autofocus: true,
        style: TextStyle(color: textColor),
        decoration: const InputDecoration(hintText: '••••••'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Valider', style: TextStyle(color: BnoxColors.cyan)),
        ),
      ],
    );
  }
}