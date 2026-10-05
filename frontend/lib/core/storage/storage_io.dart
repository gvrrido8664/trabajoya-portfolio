// Native (mobile/desktop) storage using flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static final Map<String, String> _fallback = {};

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _fallback[key];
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _fallback[key] = value;
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _fallback.remove(key);
    }
  }
}
