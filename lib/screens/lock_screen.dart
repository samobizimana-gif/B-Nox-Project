import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/account_manager.dart';
import '../core/security_manager.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  final Account account;
  const LockScreen({super.key, required this.account});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  Map<String, bool> _methods = {};
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final methods = await SecurityManager.loadMethods(widget.account.bnoxId);
    if (!mounted) return;
    setState(() {
      _methods = methods;
      _checking = false;
    });

    if (methods['biometric'] == true) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await SecurityManager.authenticateBiometric(reason: 'Déverrouillez B-NOX');
    if (ok && mounted) _goHome();
  }

  Future<void> _tryPin() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinPromptDialog(),
    );

    if (pin == null) return;

    final valid = await SecurityManager.verifyPin(bnoxId: widget.account.bnoxId, pin: pin);
    if (!mounted) return;
    
    if (valid) {
      _goHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorrect'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _goHome() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(account: widget.account)));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _checking
            ? const Center(child: CircularProgressIndicator(color: BnoxColors.cyan))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: BnoxColors.primaryGradient),
                      child: Center(
                        child: Text(
                          widget.account.displayName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Bonjour ${widget.account.displayName}', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Déverrouillez pour accéder à B-NOX', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 40),

                    if (_methods['biometric'] == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SizedBox(
                          width: 200, height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _tryBiometric,
                            icon: const Icon(Icons.fingerprint, color: Colors.white),
                            label: const Text('Déverrouiller', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BnoxColors.violet,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                          ),
                        ),
                      ),

                    if (_methods['pin'] == true)
                      SizedBox(
                        width: 200, height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _tryPin,
                          icon: Icon(Icons.password, color: textColor),
                          label: Text('Utiliser le PIN', style: TextStyle(color: textColor)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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

class _PinPromptDialog extends StatefulWidget {
  const _PinPromptDialog();
  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
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