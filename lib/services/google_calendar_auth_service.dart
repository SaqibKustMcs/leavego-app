import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leavego_app/config/google_calendar_config.dart';
import 'package:leavego_app/services/google_calendar_session_storage.dart';

class GoogleCalendarConnectResult {
  const GoogleCalendarConnectResult({required this.googleEmail});

  final String googleEmail;
}

/// Thrown when Calendar OAuth cannot produce a valid access token.
class GoogleCalendarAuthException implements Exception {
  const GoogleCalendarAuthException(this.code, [this.detail]);

  static const codeNotConnected = 'google_calendar_not_connected';
  static const codeSessionExpired = 'google_calendar_session_expired';
  static const codePermissionRevoked = 'google_calendar_permission_revoked';

  final String code;
  final String? detail;

  @override
  String toString() => detail ?? code;
}

/// Google OAuth on-device (read-only Calendar). No TaskBulls backend.
///
/// Access tokens are short-lived; the Google Sign-In SDK refreshes them via
/// [GoogleSignInAuthorizationClient.authorizationForScopes]. Stale cached tokens
/// must be cleared with [GoogleSignInAuthorizationClient.clearAuthorizationToken]
/// before re-requesting (see google_sign_in 7.x).
class GoogleCalendarAuthService {
  GoogleCalendarAuthService._();

  static final GoogleCalendarAuthService instance = GoogleCalendarAuthService._();

  bool _initialized = false;
  GoogleSignInAccount? _account;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSub;

  static const _scopes = [GoogleCalendarConfig.calendarReadonlyScope];

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final webId = GoogleCalendarConfig.webClientId;

    if (Platform.isIOS) {
      if (GoogleCalendarConfig.iosClientId == null) {
        throw Exception('iOS Google OAuth client ID is not configured.');
      }
      await GoogleSignIn.instance.initialize(
        clientId: GoogleCalendarConfig.iosClientId,
        serverClientId: webId,
      );
    } else if (Platform.isAndroid) {
      if (webId == null) {
        throw Exception(
          'Android requires a Web OAuth client ID (GOOGLE_OAUTH_WEB_CLIENT_ID). '
          'In Google Cloud Console → Credentials, create an OAuth client of type '
          '"Web application" in the same project as your Android client, then add '
          'that client ID to lib/config/google_calendar_config.dart or pass '
          '--dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=.... '
          'Also verify SHA-1/SHA-256 for com.devbay.taskbulls on the Android OAuth client.',
        );
      }
      await GoogleSignIn.instance.initialize(serverClientId: webId);
    } else {
      throw Exception('Google Calendar connect is only supported on iOS and Android.');
    }

    _authEventsSub ??= GoogleSignIn.instance.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn(:final user):
          _account = user;
        case GoogleSignInAuthenticationEventSignOut():
          _account = null;
      }
    });

    _initialized = true;
  }

  GoogleSignInAccount? get currentAccount => _account;

  /// Restores Google account + readonly Calendar scope without UI when possible.
  Future<bool> restoreSessionIfConnected() async {
    final cached = await GoogleCalendarSessionStorage.readConnected();
    if (cached != true) return false;

    await _ensureInitialized();
    final account = await _restoreAccount();
    if (account == null) return false;

    final token = await _silentAccessToken(account);
    return token != null;
  }

  Future<GoogleCalendarConnectResult> connect() async {
    await _ensureInitialized();

    GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    } on GoogleSignInException catch (e) {
      throw Exception(_messageForSignInException(e, phase: 'sign-in'));
    }

    try {
      await account.authorizationClient.authorizeScopes(_scopes);
    } on GoogleSignInException catch (e) {
      throw Exception(_messageForSignInException(e, phase: 'calendar access'));
    }

    _account = account;

    if (kDebugMode) {
      debugPrint('Google Calendar connected for ${account.email}');
    }

    await GoogleCalendarSessionStorage.writeConnected(
      connected: true,
      googleEmail: account.email,
    );

    return GoogleCalendarConnectResult(googleEmail: account.email);
  }

  Future<String> getCalendarAccessToken({bool interactiveIfNeeded = false}) async {
    await _ensureInitialized();

    var account = await _restoreAccount();
    if (account == null) {
      final linked = await GoogleCalendarSessionStorage.readConnected();
      if (linked == true) {
        throw const GoogleCalendarAuthException(
          GoogleCalendarAuthException.codeSessionExpired,
          'Google Calendar session expired. Connect again from Profile.',
        );
      }
      throw const GoogleCalendarAuthException(
        GoogleCalendarAuthException.codeNotConnected,
        'Google Calendar is not connected.',
      );
    }

    final silent = await _silentAccessToken(account);
    if (silent != null && silent.isNotEmpty) {
      return silent;
    }

    if (!interactiveIfNeeded) {
      throw const GoogleCalendarAuthException(
        GoogleCalendarAuthException.codeSessionExpired,
        'Google Calendar authorization expired. Open Profile to reconnect.',
      );
    }

    try {
      final authz = await account.authorizationClient.authorizeScopes(_scopes);
      final token = authz.accessToken.trim();
      if (token.isEmpty) {
        throw const GoogleCalendarAuthException(GoogleCalendarAuthException.codeSessionExpired);
      }
      return token;
    } on GoogleSignInException catch (e) {
      throw Exception(_messageForSignInException(e, phase: 'calendar access'));
    }
  }

  /// After Calendar API returns 401, drop the stale token and obtain a fresh one silently.
  Future<String> refreshAccessTokenAfterUnauthorized(String invalidAccessToken) async {
    await _ensureInitialized();

    final account = await _restoreAccount();
    if (account == null) {
      throw const GoogleCalendarAuthException(
        GoogleCalendarAuthException.codeSessionExpired,
        'Google Calendar session expired. Connect again from Profile.',
      );
    }

    final trimmed = invalidAccessToken.trim();
    if (trimmed.isNotEmpty) {
      try {
        await account.authorizationClient.clearAuthorizationToken(accessToken: trimmed);
      } catch (_) {}
    }

    final refreshed = await _silentAccessToken(account);
    if (refreshed != null && refreshed.isNotEmpty) {
      return refreshed;
    }

    _account = null;
    final retryAccount = await _restoreAccount();
    if (retryAccount != null) {
      final retryToken = await _silentAccessToken(retryAccount);
      if (retryToken != null && retryToken.isNotEmpty) {
        return retryToken;
      }
    }

    throw const GoogleCalendarAuthException(
      GoogleCalendarAuthException.codeSessionExpired,
      'Google Calendar authorization expired. Connect again from Profile.',
    );
  }

  Future<void> disconnect() async {
    _account = null;
    if (_initialized) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
    }
    await GoogleCalendarSessionStorage.clear();
  }

  Future<GoogleSignInAccount?> _restoreAccount() async {
    if (_account != null) return _account;

    final future = GoogleSignIn.instance.attemptLightweightAuthentication();
    if (future != null) {
      try {
        _account = await future;
      } on GoogleSignInException catch (e) {
        if (kDebugMode) {
          debugPrint('Google lightweight auth: $e');
        }
      }
    }

    if (_account != null) {
      await _verifyStoredEmail(_account!.email);
    }
    return _account;
  }

  Future<void> _verifyStoredEmail(String accountEmail) async {
    final stored = await GoogleCalendarSessionStorage.readGoogleEmail();
    if (stored == null || stored.trim().isEmpty) return;
    if (stored.trim().toLowerCase() != accountEmail.trim().toLowerCase()) {
      if (kDebugMode) {
        debugPrint('Google account email differs from last connected account.');
      }
    }
  }

  Future<String?> _silentAccessToken(GoogleSignInAccount account) async {
    try {
      final authz = await account.authorizationClient.authorizationForScopes(_scopes);
      final token = authz?.accessToken.trim() ?? '';
      return token.isEmpty ? null : token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google silent scope authorization failed: $e');
      }
      return null;
    }
  }

  String _messageForSignInException(
    GoogleSignInException e, {
    required String phase,
  }) {
    if (kDebugMode) {
      debugPrint('Google Sign-In ($phase): $e');
    }

    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return phase == 'calendar access'
            ? 'Calendar permission was denied.'
            : 'Google sign-in was cancelled.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google sign-in was interrupted. Please try again.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        final detail = e.description?.trim();
        if (detail != null && detail.isNotEmpty) {
          return detail;
        }
        if (Platform.isAndroid) {
          return 'Google Sign-In is misconfigured on Android. Add GOOGLE_OAUTH_WEB_CLIENT_ID '
              '(Web OAuth client), and check SHA-1/SHA-256 on your Android OAuth client for '
              'com.devbay.taskbulls.';
        }
        return 'Google Sign-In is misconfigured. Check GIDClientID and URL scheme in Info.plist.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return e.description?.trim().isNotEmpty == true
            ? e.description!.trim()
            : 'Google Play Services or Google Sign-In is unavailable on this device.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Could not show Google sign-in. Try again when the app is in the foreground.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Google account mismatch. Disconnect and connect again.';
      case GoogleSignInExceptionCode.unknownError:
        break;
    }

    final detail = e.description?.trim();
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }
    return 'Could not complete Google $phase. Please try again.';
  }
}
