import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStorage {
  KeyStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _privEd(String id) => 'priv_ed_$id';
  static String _privX(String id) => 'priv_x_$id';
  static String _pubEd(String id) => 'pub_ed_$id';
  static String _pubX(String id) => 'pub_x_$id';
  static String _seed(String id) => 'seed_$id';

  static Future<void> savePrivateEd({required String bnoxId, required String value}) async =>
      _storage.write(key: _privEd(bnoxId), value: value);
  static Future<String?> loadPrivateEd(String id) => _storage.read(key: _privEd(id));

  static Future<void> savePrivateX({required String bnoxId, required String value}) async =>
      _storage.write(key: _privX(bnoxId), value: value);
  static Future<String?> loadPrivateX(String id) => _storage.read(key: _privX(id));

  static Future<void> savePublicEd({required String bnoxId, required String value}) async =>
      _storage.write(key: _pubEd(bnoxId), value: value);
  static Future<String?> loadPublicEd(String id) => _storage.read(key: _pubEd(id));

  static Future<void> savePublicX({required String bnoxId, required String value}) async =>
      _storage.write(key: _pubX(bnoxId), value: value);
  static Future<String?> loadPublicX(String id) => _storage.read(key: _pubX(id));

  static Future<void> saveSeed({required String bnoxId, required String seedBase64}) async =>
      _storage.write(key: _seed(bnoxId), value: seedBase64);
  static Future<String?> loadSeed(String id) => _storage.read(key: _seed(id));

  static Future<void> deleteAllKeys(String id) async {
    await _storage.delete(key: _privEd(id));
    await _storage.delete(key: _privX(id));
    await _storage.delete(key: _pubEd(id));
    await _storage.delete(key: _pubX(id));
    await _storage.delete(key: _seed(id));
  }
}