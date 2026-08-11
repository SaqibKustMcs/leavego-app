import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';

/// Handles Firebase Cloud Messaging setup: permissions, token retrieval,
/// foreground display via local notifications, and tap routing callbacks.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important push notifications.',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Called when a message arrives while the app is in the foreground.
  void Function(RemoteMessage message)? onMessage;

  /// Called when the user taps a notification and the app opens/resumes.
  void Function(RemoteMessage message)? onMessageOpened;

  /// Called when FCM issues a new device token.
  void Function(String token)? onTokenRefresh;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      // iOS already presents the incoming alert itself in the foreground (see
      // setForegroundNotificationPresentationOptions above), so a local
      // notification would show the same message a second time. Android does
      // not auto-present, so it still needs one.
      if (!Platform.isIOS) {
        _showLocalNotification(message);
      }
      onMessage?.call(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onMessageOpened?.call(message);
    });
    _messaging.onTokenRefresh.listen((token) {
      onTokenRefresh?.call(token);
    });

    // Cold-start local notification tap (app launched from foreground local notif).
    final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse != null) {
      _onLocalNotificationTap(launchDetails!.notificationResponse!);
    }
  }

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission();
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('FCM TOKEN => $token');
      }
      return token;
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      return 'Android ${Platform.operatingSystemVersion}';
    }
    if (Platform.isIOS) {
      return 'iOS ${Platform.operatingSystemVersion}';
    }
    return 'Mobile Device';
  }

  /// The notification the app was launched from (when opened from terminated).
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final data = decoded.map((key, value) => MapEntry(key.toString(), value));
      NotificationNavigationService.openFromPayload(
        rawData: Map<String, dynamic>.from(data),
      );
    } catch (e) {
      debugPrint('Failed to handle local notification tap: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final payload = jsonEncode(
      NotificationNavigationService.payloadFromRemoteMessage(message),
    );

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
