import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'choice_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Adaptation au thème
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ---------- Fond ----------
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: bgColor),
            ),
          ),

          // ---------- Voile sombre (uniquement en mode sombre pour lire le texte) ----------
          if (isDark)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BnoxColors.dark.withOpacity(0.55),
                      BnoxColors.dark.withOpacity(0.85),
                      BnoxColors.dark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            )
          else
            // En mode clair, on met un voile blanc pour lire le texte noir
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.7)),
            ),

          // ---------- Contenu ----------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/logo.png',
                    width: 160,
                    height: 160,
                    errorBuilder: (_, __, ___) => const _FallbackLogo(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'B-NOX',
                    style: TextStyle(color: textColor, fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Byond Network Ownership & eXchange',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? BnoxColors.gray : Colors.black54, fontSize: 12, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 18),
                  const _SloganShort(),
                  const Spacer(flex: 3),
                  Text(
                    'Une nouvelle façon\nde communiquer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sécurisée. Vérifiée. À vous.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? BnoxColors.gray : Colors.black54, fontSize: 14),
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: BnoxColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: BnoxColors.violet.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChoiceScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: const Text('Commencer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Avec B-NOX, vos données vous appartiennent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? BnoxColors.gray : Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SloganShort extends StatelessWidget {
  const _SloganShort();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        children: [
          TextSpan(text: 'Connect.  ', style: TextStyle(color: textColor)),
          const TextSpan(text: 'Verify.  ', style: TextStyle(color: BnoxColors.cyan)),
          TextSpan(text: 'Own.', style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: BnoxColors.primaryGradient,
        boxShadow: [BoxShadow(color: BnoxColors.violet.withOpacity(0.4), blurRadius: 30)],
      ),
      child: const Center(child: Text('B', style: TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold))),
    );
  }
}