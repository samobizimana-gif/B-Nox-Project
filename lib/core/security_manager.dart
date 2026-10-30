import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityManager {
  SecurityManager._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final LocalAuthentication _auth = LocalAuthentication();

  static String _keyPin(String bnoxId) => 'security_pin_$bnoxId';
  static String _keyMethods(String bnoxId) => 'security_methods_$bnoxId';

  // ============================================================
  // Biométrie
  // ============================================================
  static Future<bool> isBiometricAvailable() async {
  try {
    // On vérifie si l'appareil a un capteur et des biométries enregistrées
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    
    // Si l'un des deux est vrai, on tente
    return canCheck || isSupported;
  } catch (_) {
    return false;
  }
}



  static Future<bool> authenticateBiometric({required String reason}) async {
  try {
    final didAuthenticate = await _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: false, // On laisse Android décider (PIN/Pattern/Biométrie)
        stickyAuth: true,
      ),
    );
    return didAuthenticate;
  } catch (e) {
    debugPrint('Biometric Error: $e');
    return false;
  }
}

  // ============================================================
  // PIN
  // ============================================================
  static Future<void> savePin({required String bnoxId, required String pin}) async {
    await _storage.write(key: _keyPin(bnoxId), value: pin);
  }

  static Future<String?> loadPin(String bnoxId) async {
    return _storage.read(key: _keyPin(bnoxId));
  }

  static Future<bool> verifyPin({required String bnoxId, required String pin}) async {
    final stored = await loadPin(bnoxId);
    return stored != null && stored == pin;
  }

  // ============================================================
  // Méthodes actives (Biométrie + PIN)
  // ============================================================
  static Future<void> saveMethods({
    required String bnoxId,
    required bool biometric,
    required bool pin,
  }) async {
    await _storage.write(key: _keyMethods(bnoxId), value: '${biometric}_$pin');
  }

  static Future<Map<String, bool>> loadMethods(String bnoxId) async {
    final raw = await _storage.read(key: _keyMethods(bnoxId));
    if (raw == null) return {'biometric': false, 'pin': false};
    
    final parts = raw.split('_');
    if (parts.length != 2) return {'biometric': false, 'pin': false};

    return {
      'biometric': parts[0] == 'true',
      'pin': parts[1] == 'true',
    };
  }
}