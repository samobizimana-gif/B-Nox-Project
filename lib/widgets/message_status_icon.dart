import 'package:flutter/material.dart';
import '../../core/constants.dart';

class MessageStatusIcon extends StatelessWidget {
  final bool delivered;
  final bool read;

  const MessageStatusIcon({
    super.key,
    required this.delivered,
    required this.read,
  });

  @override
  Widget build(BuildContext context) {
    if (read) {
      // Lu : Petit logo B-NOX stylisé
      return Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          gradient: BnoxColors.primaryGradient,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'BN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      );
    } else if (delivered) {
      // Reçu : 2 ticks gris
      return const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(Icons.done_all, color: Colors.grey, size: 14),
      );
    } else {
      // Envoyé : 1 tick gris
      return const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(Icons.done, color: Colors.grey, size: 14),
      );
    }
  }
}