import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants.dart';

class BnoxQr extends StatelessWidget {
  final String data;
  final double size;

  const BnoxQr({
    super.key,
    required this.data,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
          ),
          // Logo BN au centre
          Container(
            width: size * 0.22,
            height: size * 0.22,
            decoration: BoxDecoration(
              color: BnoxColors.dark,
              borderRadius: BorderRadius.circular(size * 0.05),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: BnoxColors.violet.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'BN',
                style: TextStyle(
                  color: BnoxColors.cyan,
                  fontSize: size * 0.09,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(
                      color: BnoxColors.violet.withOpacity(0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}