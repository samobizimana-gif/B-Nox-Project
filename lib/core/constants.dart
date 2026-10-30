import 'package:flutter/material.dart';

class BnoxColors {
  BnoxColors._();

  static const Color dark = Color(0xFF050816);
  static const Color cyan = Color(0xFF00D9FF);
  static const Color blue = Color(0xFF1769FF);
  static const Color violet = Color(0xFF6C2BFF);
  static const Color purple = Color(0xFFA855F7);
  static const Color white = Color(0xFFF8FAFC);
  static const Color gray = Color(0xFF94A3B8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class BnoxStrings {
  BnoxStrings._();

  static const String appName = 'B-NOX';
  static const String sloganShort = 'Connect. Verify. Own.';
  static const String sloganLong = 'BEyond Network Ownership & eXchange';
  static const String tagline = 'Une nouvelle façon\nde communiquer.';
  static const String taglineSub = 'Sécurisée. Vérifiée. À vous.';
  static const String footer = 'Avec B-NOX, vos données vous appartiennent.';
}