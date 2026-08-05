import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/data/api_service.dart';
import 'package:leavego_app/data/data_service.dart';
import 'package:leavego_app/firebase_options.dart';
import 'package:leavego_app/services/app_http_overrides.dart';
import 'package:leavego_app/services/connectivity_service.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';
import 'package:leavego_app/services/push_notification_service.dart';
import 'package:leavego_app/ui/screens/splash_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/connectivity_banner.dart';

/// Handles FCM messages received while the app is in the background/terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Trust newer SSL intermediates on older Android trust stores.
  HttpOverrides.global = await AppHttpOverrides.create();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await PushNotificationService.instance.initialize();
  } catch (e, st) {
    // Older devices without Play Services should still be able to use the API.
    debugPrint('Firebase init skipped/failed: $e\n$st');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  Get.put(DataService(), permanent: true);
  Get.put(ApiService(Get.find<DataService>()), permanent: true);
  Get.put(AppController(Get.find<ApiService>()), permanent: true);
  await Get.putAsync(() => ConnectivityService().init(), permanent: true);
  runApp(const LeaveProApp());
}

class LeaveProApp extends StatelessWidget {
  const LeaveProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamFlow',
      theme: AppTheme.light(),
      navigatorKey: NotificationNavigationService.navigatorKey,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Dismiss keyboard on empty-area taps and button taps alike.
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: ConnectivityBanner(child: child),
        );
      },
    );
  }
}
