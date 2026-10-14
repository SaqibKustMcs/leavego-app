import 'dart:io';

/// Public OAuth client IDs (not secrets). Override with dart-define if needed.
class GoogleCalendarConfig {
  GoogleCalendarConfig._();

  static const String calendarReadonlyScope =
      'https://www.googleapis.com/auth/calendar.readonly';

  static const String _iosClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_IOS_CLIENT_ID',
    defaultValue:
        '196388059648-lcfs56m0qqolai1kpso3rhloocdvqijb.apps.googleusercontent.com',
  );

  static const String _androidClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_ANDROID_CLIENT_ID',
    defaultValue:
        '196388059648-6c4710ed1bts4csttefdm39gepnasetj.apps.googleusercontent.com',
  );

  /// **Web application** OAuth client (same Google Cloud project). Required on Android
  /// for `google_sign_in` 7.x when `google-services.json` has no web OAuth entry.
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_WEB_CLIENT_ID',
    defaultValue:
        '196388059648-sfiqjohojdf82a0lqqbu5usk4g7rffhh.apps.googleusercontent.com',
  );

  /// Ready to connect (OAuth IDs present for this platform).
  static bool get isConfigured {
    if (Platform.isIOS) {
      return iosClientId != null;
    }
    return androidClientId != null && webClientId != null;
  }

  /// Connect button can be shown; Android may still need Web client ID at runtime.
  static bool get canAttemptConnect {
    if (Platform.isIOS) {
      return iosClientId != null;
    }
    return androidClientId != null;
  }

  static String? get iosClientId {
    final id = _iosClientId.trim();
    return id.isEmpty ? null : id;
  }

  static String? get androidClientId {
    final id = _androidClientId.trim();
    return id.isEmpty ? null : id;
  }

  static String? get webClientId {
    final id = _webClientId.trim();
    return id.isEmpty ? null : id;
  }

  static String? get iosUrlScheme {
    final clientId = iosClientId;
    if (clientId == null) return null;
    const suffix = '.apps.googleusercontent.com';
    if (!clientId.endsWith(suffix)) return null;
    final prefix = clientId.substring(0, clientId.length - suffix.length);
    return 'com.googleusercontent.apps.$prefix';
  }

  static const int defaultPastDays = 30;
  static const int defaultFutureDays = 90;
  static const int defaultEventsPerPage = 25;
}
