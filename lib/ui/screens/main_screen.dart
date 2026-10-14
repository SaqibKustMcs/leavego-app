import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';
import 'package:leavego_app/services/push_notification_service.dart';
import 'package:leavego_app/ui/screens/home_screen.dart';
import 'package:leavego_app/ui/screens/my_leave_requests_screen.dart';
import 'package:leavego_app/ui/screens/projects_screen.dart';
import 'package:leavego_app/ui/screens/notification_screen.dart';
import 'package:leavego_app/ui/widgets/app_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final AppController _appController;
  bool _notificationPermissionRequested = false;

  static const int _projectsIndex = 1;
  static const int _leaveIndex = 2;
  static const int _notificationsIndex = 3;

  /// Kept alive across tab switches via [IndexedStack].
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    ProjectsScreen(),
    MyLeaveRequestsScreen(),
    NotificationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // _appController.ensureGoogleCalendarReady();
      NotificationNavigationService.flushPending();
      _requestNotificationPermissionAfterNavReady();
    });
  }

  /// Ask notification permission only after bottom navbar is on screen.
  Future<void> _requestNotificationPermissionAfterNavReady() async {
    if (_notificationPermissionRequested || !mounted) return;
    _notificationPermissionRequested = true;

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final push = PushNotificationService.instance;
    await push.initialize();
    await push.requestPermission();

    final token = await push.getToken();
    if (token != null && token.isNotEmpty) {
      final deviceName = await push.getDeviceName();
      await _appController.registerFcmToken(
        token,
        platform: Platform.isIOS ? 'ios' : 'android',
        deviceName: deviceName,
      );
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = _appController.pendingMainTabIndex;
      if (pending != null) {
        _appController.clearPendingMainTabIndex();
        setState(() {
          _currentIndex = pending.clamp(0, _screens.length - 1);
        });
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onTabSelected(int tappedIndex) async {
    setState(() => _currentIndex = tappedIndex);

    if (tappedIndex == 0) {
      await _appController.loadMe();
      return;
    }

    if (tappedIndex == _projectsIndex) {
      await _appController.loadProjects(refresh: true);
      return;
    }

    if (tappedIndex == _leaveIndex) {
      await Future.wait([
        _appController.loadDashboard(),
        _appController.loadLeaveTypes(),
        _appController.loadMyLeaves(),
        _appController.loadRequestsByRole(),
      ]);
      return;
    }

    if (tappedIndex == _notificationsIndex) {
      await Future.wait([
        _appController.loadUnreadCount(),
        _appController.loadNotifications(refresh: true),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex.clamp(0, _screens.length - 1);
    final unread = _appController.unreadCount;

    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: index,
        notificationBadgeCount: unread,
        onTap: (tappedIndex) => _onTabSelected(tappedIndex),
      ),
    );
  }
}
