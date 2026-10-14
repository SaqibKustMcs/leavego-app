import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Non-secret Google Calendar connection hints for faster UI (server is source of truth).
class GoogleCalendarSessionStorage {
  GoogleCalendarSessionStorage._();

  static const _connectedKey = 'google_calendar_connected_v1';
  static const _emailKey = 'google_calendar_google_email_v1';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static Future<void> writeConnected({required bool connected, String? googleEmail}) async {
    await _storage.write(key: _connectedKey, value: connected ? '1' : '0');
    if (googleEmail != null && googleEmail.trim().isNotEmpty) {
      await _storage.write(key: _emailKey, value: googleEmail.trim());
    } else if (!connected) {
      await _storage.delete(key: _emailKey);
    }
  }

  static Future<bool?> readConnected() async {
    final raw = await _storage.read(key: _connectedKey);
    if (raw == null) return null;
    return raw == '1';
  }

  static Future<String?> readGoogleEmail() => _storage.read(key: _emailKey);

  static Future<void> clear() async {
    await _storage.delete(key: _connectedKey);
    await _storage.delete(key: _emailKey);
  }
}
