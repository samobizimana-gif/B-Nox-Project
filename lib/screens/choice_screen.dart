import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'create_identity_screen.dart';
import 'login_screen.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/logo.png', width: 80, height: 80, errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 80, color: BnoxColors.violet)),
              const SizedBox(height: 20),
              Text('Choisissez une option', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),
              
              _ChoiceCard(
                icon: Icons.login,
                title: 'Se connecter',
                subtitle: 'J\'ai déjà une identité B-NOX.',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                cardColor: cardColor, textColor: textColor,
              ),
              const SizedBox(height: 20),
              
              _ChoiceCard(
                icon: Icons.person_add,
                title: 'Créer mon identité',
                subtitle: 'Je suis nouveau sur B-NOX.',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateIdentityScreen())),
                cardColor: cardColor, textColor: textColor,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textColor;

  const _ChoiceCard({required this.icon, required this.title, required this.subtitle, required this.onTap, required this.cardColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: BnoxColors.primaryGradient),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}