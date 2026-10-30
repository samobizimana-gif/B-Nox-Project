import 'package:flutter/material.dart';
import '../../core/constants.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Aide & Support', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Guide de démarrage rapide', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tout ce qu\'il faut savoir pour utiliser B-NOX.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),

            _buildStepCard(
              step: '1',
              title: 'Créer un compte',
              description: 'Au premier lancement, cliquez sur "Créer mon identité". Choisissez un nom d\'affichage. L\'application génère automatiquement vos clés cryptographiques et votre B-NOX ID unique.',
              icon: Icons.person_add,
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildStepCard(
              step: '2',
              title: 'Se connecter',
              description: 'Si vous avez déjà un compte, cliquez sur "Se connecter". Entrez votre B-NOX ID (ou @username) et votre phrase de récupération de 12 mots.',
              icon: Icons.login,
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildStepCard(
              step: '3',
              title: 'Ajouter un contact',
              description: 'Allez dans l\'onglet "Contacts" et cliquez sur le bouton "+". Vous pouvez scanner le QR code de votre ami ou entrer son B-NOX ID / @username.',
              icon: Icons.person_add_alt_1,
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildStepCard(
              step: '4',
              title: 'Discuter en toute sécurité',
              description: 'Ouvrez une discussion depuis l\'onglet "Chat" ou "Contacts". Vos messages sont chiffrés de bout en bout. Un logo B-NOX apparaît quand le message est lu.',
              icon: Icons.chat_bubble_outline,
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildStepCard(
              step: '5',
              title: 'Supprimer un message',
              description: 'Faites un appui long sur un message. Vous pouvez le supprimer pour vous uniquement, ou pour tout le monde (si vous êtes l\'expéditeur).',
              icon: Icons.delete_outline,
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildStepCard(
              step: '6',
              title: 'Sécuriser son application',
              description: 'Allez dans "Paramètres" > "Sécurité". Activez le code PIN ou la biométrie (empreinte digitale) pour verrouiller l\'accès à B-NOX.',
              icon: Icons.shield_outlined,
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildStepCard(
              step: '7',
              title: 'Personnaliser son profil',
              description: 'Dans l\'onglet "Profil", changez votre photo, votre nom, ou définissez un @username pour être plus facile à trouver.',
              icon: Icons.edit,
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildStepCard(
              step: '8',
              title: 'Récupérer son compte',
              description: 'Dans l\'onglet "Profil", cliquez sur "Phrase de récupération". Notez ces 12 mots. Ils sont la SEULE façon de restaurer votre compte si vous changez de téléphone.',
              icon: Icons.vpn_key,
              textColor: textColor,
              cardColor: cardColor,
            ),

            const SizedBox(height: 30),
            Center(
              child: Text('Besoin d\'aide supplémentaire ?', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('support@bnox.app', style: const TextStyle(color: BnoxColors.cyan, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color textColor,
    required Color cardColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: BnoxColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: BnoxColors.cyan, size: 18),
                    const SizedBox(width: 8),
                    Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}