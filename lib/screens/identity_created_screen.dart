import 'package:bnox/core/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../core/account_manager.dart';
import '../widgets/bnox_qr.dart';
import 'home_screen.dart'; // On importe le HomeScreen

class IdentityCreatedScreen extends StatelessWidget {
  final Account account;

  const IdentityCreatedScreen({super.key, required this.account});

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: account.bnoxId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('B-NOX ID copié'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _shareId() async {
    await Share.share(
      'Mon identité B-NOX :\n${account.bnoxId}\n\n'
      'Ajoutez-moi sur B-NOX avec cet identifiant.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BnoxColors.dark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Coche succès
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B2A1E).withOpacity(0.6),
                  border: Border.all(
                      color: const Color(0xFF3BE28A).withOpacity(0.6),
                      width: 1.5),
                ),
                child:
                    const Icon(Icons.check, color: Color(0xFF3BE28A), size: 40),
              ),

              const SizedBox(height: 22),

              const Text(
                'Votre identité est prête',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: BnoxColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Bienvenue ${account.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: BnoxColors.gray, fontSize: 14),
              ),

              const SizedBox(height: 30),

              // Carte B-NOX ID
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      account.bnoxId,
                      style: const TextStyle(
                          color: BnoxColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _copyId(context),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded,
                            color: BnoxColors.violet, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // QR Code
              BnoxQr(data: account.bnoxId, size: 200),

              const Spacer(),

              // Bouton Partager
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _shareId,
                  icon:
                      const Icon(Icons.share, color: BnoxColors.cyan, size: 20),
                  label: const Text(
                    'Partager mon ID',
                    style: TextStyle(
                        color: BnoxColors.cyan,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: BnoxColors.cyan.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bouton Continuer vers HomeScreen
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: BnoxColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      // Sauvegarde la session
                      await SessionManager.setActiveAccount(account.bnoxId);

                      if (!context.mounted) return;

                      // Navigation vers l'accueil
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(account: account),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text('Continuer',
                        style: TextStyle(
                            color: BnoxColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
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
