// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:web/web.dart' as web;
import 'dart:math';

/// Almacenamiento por pestaña usando localStorage + sessionStorage.
///
/// El token real se guarda en localStorage con una clave única por pestaña
/// (auth_token_<tabId>). El tabId se guarda en sessionStorage (per-tab),
/// así cada pestaña tiene su propia sesión aunque comparta localStorage.
/// Al recargar la página, sessionStorage conserva el tabId y permite
/// leer el token correcto de localStorage.
class AppStorage {
  static String? _tabId;

  static String get _key {
    _tabId ??= web.window.sessionStorage.getItem('tab_id');
    if (_tabId == null) {
      _tabId = _generateId();
      web.window.sessionStorage.setItem('tab_id', _tabId!);
    }
    return 'auth_token_$_tabId';
  }

  static String _generateId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(999999)}';
  }

  static Future<String?> read(String key) async {
    if (key == 'auth_token') {
      final val = web.window.localStorage.getItem(_key);
      if (val != null) return val;
      // Migración desde formato antiguo (sin prefijo de pestaña)
      final old = web.window.localStorage.getItem('auth_token');
      if (old != null) {
        web.window.localStorage.setItem(_key, old);
        web.window.localStorage.removeItem('auth_token');
        return old;
      }
      return null;
    }
    return web.window.localStorage.getItem(key);
  }

  static Future<void> write(String key, String value) async {
    if (key == 'auth_token') {
      web.window.localStorage.setItem(_key, value);
    } else {
      web.window.localStorage.setItem(key, value);
    }
  }

  static Future<void> delete(String key) async {
    if (key == 'auth_token') {
      web.window.localStorage.removeItem(_key);
    } else {
      web.window.localStorage.removeItem(key);
    }
  }
}
