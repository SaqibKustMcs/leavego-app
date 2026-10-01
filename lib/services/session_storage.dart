import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the auth session in a way that survives process death, but not a
/// real reinstall.
///
/// iOS Keychain entries are kept after the app is deleted. SharedPreferences
/// (UserDefaults) are cleared. On a fresh install we therefore wipe any
/// leftover Keychain token when the UserDefaults "initialized" flag is missing.
class SessionStorage {
  SessionStorage._();

  static const _initializedKey = 'session_storage_initialized_v1';

  /// Must stay in sync with [AppController.tokenStorageKey] for legacy prefs.
  static const tokenKey = 'auth_token';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static bool _ready = false;

  /// Call once at app startup before any auth reads.
  static Future<void> init() async {
    if (_ready) return;

    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_initializedKey) ?? false;

    if (!initialized) {
      final legacyToken = prefs.getString(tokenKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        // Upgrade from older builds that stored the token in UserDefaults.
        await _storage.write(key: tokenKey, value: legacyToken);
      } else {
        // Fresh install after uninstall: clear Keychain leftovers.
        await _storage.delete(key: tokenKey);
      }
      await prefs.remove(tokenKey);
      await prefs.setBool(_initializedKey, true);
    } else {
      // Never keep a plaintext copy in UserDefaults after migration.
      await prefs.remove(tokenKey);
    }

    _ready = true;
  }

  static Future<String?> readToken() async {
    await init();
    return _storage.read(key: tokenKey);
  }

  static Future<void> writeToken(String token) async {
    await init();
    await _storage.write(key: tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<void> clearToken() async {
    await init();
    await _storage.delete(key: tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}
