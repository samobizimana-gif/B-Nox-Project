import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/account_manager.dart';
import '../../widgets/bnox_qr.dart';

class QrScreen extends StatelessWidget {
  final Account account;
  const QrScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Mon QR code', style: TextStyle(color: textColor)),
      ),
      body: SafeArea(
        child: Center( // <-- CENTRE TOUT LE CONTENU
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // <-- CENTRE VERTICALEMENT
              crossAxisAlignment: CrossAxisAlignment.center, // <-- CENTRE HORIZONTALEMENT
              children: [
                // Avatar
                Container(
                  width: 80, 
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, 
                    gradient: BnoxColors.primaryGradient
                  ),
                  child: Center(
                    child: Text(
                      account.displayName.isNotEmpty ? account.displayName[0].toUpperCase() : 'N',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  account.displayName, 
                  style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)
                ),
                
                const SizedBox(height: 30),
                
                // QR Code (Centré)
                Center(
                  child: BnoxQr(data: account.bnoxId, size: 220),
                ),
                
                const SizedBox(height: 20),
                
                // B-NOX ID textuel (Centré)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF0B1020) 
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.bnoxId, 
                          style: TextStyle(color: textColor, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.w600)
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: account.bnoxId));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('B-NOX ID copié !')));
                          },
                          child: const Icon(Icons.copy_rounded, color: BnoxColors.cyan, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                const Text(
                  'Scannez ce code pour m\'ajouter', 
                  style: TextStyle(color: Colors.grey, fontSize: 13)
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}