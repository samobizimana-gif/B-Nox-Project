import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    Navigator.pop(context, raw); // Renvoie le texte du QR
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs du thème
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    const double scanSize = 260.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Scanner un QR code', style: TextStyle(color: textColor, fontSize: 18)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // ---------- ZONE CAMÉRA (Carré central) ----------
            Center(
              child: Container(
                width: scanSize,
                height: scanSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BnoxColors.cyan, width: 3),
                  boxShadow: [
                    BoxShadow(color: BnoxColors.cyan.withOpacity(0.2), blurRadius: 20),
                  ],
                ),
                // On "coupe" la caméra pour qu'elle ne prenne que ce carré
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ---------- TEXTE ----------
            Text(
              'Placez le QR code dans le cadre',
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}