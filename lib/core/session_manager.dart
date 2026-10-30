import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  SessionManager._();

  static const String _activeKey = 'bnox_active_account';

  /// Enregistre le compte actif
  static Future<void> setActiveAccount(String? bnoxId) async {
    final prefs = await SharedPreferences.getInstance();
    if (bnoxId == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, bnoxId);
    }
  }

  /// Récupère le compte actif (null si déconnecté)
  static Future<String?> getActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey);
  }

  /// Déconnexion
  static Future<void> logout() async {
    await setActiveAccount(null);
  }
}