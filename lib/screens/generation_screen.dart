import 'package:bnox/screens/identity_created_screen.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/account_manager.dart';

class GenerationScreen extends StatefulWidget {
  final String displayName;

  const GenerationScreen({super.key, required this.displayName});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  int _currentStep = 0;
  Account? _account;

  final List<String> _steps = [
    'Identité en cours de création',
    'Clés de chiffrement générées',
    'Publication sur le réseau',
    'B-NOX ID en cours d\'attribution',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addListener(() {
      int step = (_controller.value * _steps.length).floor();
      if (step > _steps.length) step = _steps.length;
      if (step != _currentStep) setState(() => _currentStep = step);
    });

    _run();
  }

  Future<void> _run() async {
    _controller.forward();
    try {
      final acc = await AccountManager.createAccount(displayName: widget.displayName);
      _account = acc;
    } catch (e) {
      // Gérer l'erreur
    }
    await _controller.forward().orCancel.catchError((_) {});
    if (!mounted) return;
    
    // Dans _run(), après await _controller.forward...


// Si le compte a bien été créé
if (_account != null) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => IdentityCreatedScreen(account: _account!),
    ),
  );
}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BnoxColors.dark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                'Création de votre\nB-NOX ID',
                textAlign: TextAlign.center,
                style: TextStyle(color: BnoxColors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _progress,
                builder: (_, __) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 10,
                          backgroundColor: const Color(0xFF1A2238),
                          valueColor: const AlwaysStoppedAnimation<Color>(BnoxColors.cyan),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('${(_progress.value * 100).round()}%', style: const TextStyle(color: BnoxColors.cyan, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
              ...List.generate(_steps.length, (i) {
                final done = i < _currentStep;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Icon(
                        done ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: done ? const Color(0xFF3BE28A) : BnoxColors.gray.withOpacity(0.4),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(_steps[i], style: TextStyle(color: done ? BnoxColors.white : BnoxColors.gray, fontSize: 13.5)),
                    ],
                  ),
                );
              }),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}